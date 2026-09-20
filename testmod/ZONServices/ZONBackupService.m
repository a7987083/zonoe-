#import "ZONBackupService.h"
#import "ZONBackupPolicy.h"
#import "SSZipArchive.h"

static NSString * const ZONBackupErrorDomain = @"com.zonoe.backup";

typedef NS_ENUM(NSInteger, ZONBackupErrorCode) {
    ZONBackupErrorInvalidName = 1,
    ZONBackupErrorWorkspace,
    ZONBackupErrorScan,
    ZONBackupErrorCopy,
    ZONBackupErrorArchive,
};

@interface ZONBackupManifestItem : NSObject
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, strong) NSURL *destinationURL;
@property (nonatomic, copy) NSString *relativePath;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, assign) BOOL excludedContents;
@property (nonatomic, assign) BOOL sourceIsDirectory;
@end

@implementation ZONBackupManifestItem
@end

@implementation ZONBackupService

+ (void)reportProgress:(ZONBackupProgressHandler)progress
                 stage:(ZONBackupStage)stage
                detail:(NSString *)detail
              fraction:(double)fraction
{
    if (!progress) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        progress(stage, detail, MAX(0.0, MIN(1.0, fraction)));
    });
}

+ (NSError *)errorWithCode:(ZONBackupErrorCode)code
               description:(NSString *)description
                underlying:(NSError *)underlying
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (description.length > 0) [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    if (underlying) [userInfo setObject:underlying forKey:NSUnderlyingErrorKey];
    return [NSError errorWithDomain:ZONBackupErrorDomain code:code userInfo:userInfo];
}

+ (BOOL)removePathIfPresent:(NSURL *)url
                fileManager:(NSFileManager *)fm
                      error:(NSError **)error
{
    if (![fm fileExistsAtPath:url.path]) return YES;
    return [fm removeItemAtURL:url error:error];
}

+ (BOOL)ensureDirectoryURL:(NSURL *)url
               fileManager:(NSFileManager *)fm
                     error:(NSError **)error
{
    BOOL isDirectory = NO;
    if ([fm fileExistsAtPath:url.path isDirectory:&isDirectory]) {
        if (isDirectory) return YES;
        if (![fm removeItemAtURL:url error:error]) return NO;
    }
    return [fm createDirectoryAtURL:url
        withIntermediateDirectories:YES
                         attributes:nil
                              error:error];
}

+ (unsigned long long)sizeOfURL:(NSURL *)url error:(NSError **)error
{
    NSNumber *isDirectory = nil;
    NSError *resourceError = nil;
    if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&resourceError]) {
        if (error) *error = resourceError;
        return 0;
    }

    if (!isDirectory.boolValue) {
        NSNumber *size = nil;
        if (![url getResourceValue:&size forKey:NSURLFileSizeKey error:&resourceError]) {
            if (error) *error = resourceError;
            return 0;
        }
        return size.unsignedLongLongValue;
    }

    __block NSError *enumerationError = nil;
    unsigned long long total = 0;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSDirectoryEnumerator<NSURL *> *enumerator =
        [fm enumeratorAtURL:url
 includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLFileSizeKey]
                    options:0
               errorHandler:^BOOL(__unused NSURL *failedURL, NSError *scanError) {
        enumerationError = scanError;
        return NO;
    }];

    for (NSURL *childURL in enumerator) {
        NSNumber *regular = nil;
        NSNumber *size = nil;
        NSError *childError = nil;
        if (![childURL getResourceValue:&regular forKey:NSURLIsRegularFileKey error:&childError]) {
            enumerationError = childError;
            break;
        }
        if (!regular.boolValue) continue;
        if (![childURL getResourceValue:&size forKey:NSURLFileSizeKey error:&childError]) {
            enumerationError = childError;
            break;
        }
        total += size.unsignedLongLongValue;
    }

    if (enumerationError) {
        if (error) *error = enumerationError;
        return 0;
    }
    return total;
}

+ (NSArray<ZONBackupManifestItem *> *)manifestForRootName:(NSString *)rootName
                                                sourceURL:(NSURL *)sourceURL
                                           destinationURL:(NSURL *)destinationURL
                                             fileManager:(NSFileManager *)fm
                                                   error:(NSError **)error
{
    NSArray<NSURL *> *children = [fm contentsOfDirectoryAtURL:sourceURL
                                  includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                     options:0
                                                       error:error];
    if (!children) return nil;

    NSMutableArray<ZONBackupManifestItem *> *manifest = [NSMutableArray arrayWithCapacity:children.count];
    for (NSURL *sourceItemURL in children) {
        NSString *itemName = sourceItemURL.lastPathComponent ?: @"";
        if (itemName.length == 0) continue;

        NSString *relativePath = [rootName stringByAppendingPathComponent:itemName];
        NSNumber *isDirectory = nil;
        NSError *metadataError = nil;
        if (![sourceItemURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&metadataError]) {
            if (error) *error = metadataError;
            return nil;
        }

        ZONBackupManifestItem *item = [ZONBackupManifestItem new];
        item.sourceURL = sourceItemURL;
        item.destinationURL = [destinationURL URLByAppendingPathComponent:itemName];
        item.relativePath = relativePath;
        item.sourceIsDirectory = isDirectory.boolValue;
        item.excludedContents = [ZONBackupPolicy shouldExcludeContentsAtRelativePath:relativePath];

        if (!item.excludedContents) {
            NSError *sizeError = nil;
            item.size = [self sizeOfURL:sourceItemURL error:&sizeError];
            if (sizeError) {
                if (error) *error = sizeError;
                return nil;
            }
        }
        [manifest addObject:item];
    }
    return manifest;
}

+ (BOOL)shouldSkipLargeItem:(ZONBackupManifestItem *)item
            decisionHandler:(ZONBackupLargeItemDecisionHandler)decisionHandler
{
    if (item.excludedContents || item.size <= [ZONBackupPolicy largeItemThresholdBytes]) return NO;
    if (!decisionHandler) return YES;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL skip = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        decisionHandler(item.relativePath, item.size, ^(BOOL replySkip) {
            skip = replySkip;
            dispatch_semaphore_signal(semaphore);
        });
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return skip;
}

+ (BOOL)copyManifest:(NSArray<ZONBackupManifestItem *> *)manifest
                stage:(ZONBackupStage)stage
          fileManager:(NSFileManager *)fm
      decisionHandler:(ZONBackupLargeItemDecisionHandler)decisionHandler
             progress:(ZONBackupProgressHandler)progress
                error:(NSError **)error
{
    if (manifest.count == 0) {
        [self reportProgress:progress stage:stage detail:nil fraction:1.0];
        return YES;
    }

    for (NSUInteger index = 0; index < manifest.count; index++) {
        ZONBackupManifestItem *item = [manifest objectAtIndex:index];

        if (item.excludedContents) {
            if (item.sourceIsDirectory) {
                NSError *directoryError = nil;
                if (![self ensureDirectoryURL:item.destinationURL fileManager:fm error:&directoryError]) {
                    if (error) {
                        *error = [self errorWithCode:ZONBackupErrorCopy
                                        description:[NSString stringWithFormat:@"无法创建备份目录骨架：%@", item.relativePath]
                                         underlying:directoryError];
                    }
                    return NO;
                }
            }
        } else if (![self shouldSkipLargeItem:item decisionHandler:decisionHandler]) {
            NSError *removeError = nil;
            if (![self removePathIfPresent:item.destinationURL fileManager:fm error:&removeError]) {
                if (error) {
                    *error = [self errorWithCode:ZONBackupErrorCopy
                                    description:[NSString stringWithFormat:@"无法替换备份目标：%@", item.relativePath]
                                     underlying:removeError];
                }
                return NO;
            }

            NSError *copyError = nil;
            if (![fm copyItemAtURL:item.sourceURL toURL:item.destinationURL error:&copyError]) {
                if (error) {
                    *error = [self errorWithCode:ZONBackupErrorCopy
                                    description:[NSString stringWithFormat:@"备份复制失败：%@", item.relativePath]
                                     underlying:copyError];
                }
                return NO;
            }
        }

        double fraction = (double)(index + 1) / (double)manifest.count;
        [self reportProgress:progress stage:stage detail:item.relativePath fraction:fraction];
    }
    return YES;
}

+ (void)finishOnMainQueueWithURL:(NSURL *)archiveURL
                           error:(NSError *)error
                      completion:(ZONBackupCompletionHandler)completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(archiveURL, error);
    });
}

+ (void)createBackupNamed:(NSString *)name
        largeItemDecision:(ZONBackupLargeItemDecisionHandler)largeItemDecision
                 progress:(ZONBackupProgressHandler)progress
               completion:(ZONBackupCompletionHandler)completion
{
    NSParameterAssert(completion != nil);

    NSString *resolvedName = name.length > 0 ? name : NSBundle.mainBundle.bundleIdentifier;
    if (resolvedName.length == 0) {
        [self finishOnMainQueueWithURL:nil
                                 error:[self errorWithCode:ZONBackupErrorInvalidName
                                               description:@"无法生成备份名称"
                                                underlying:nil]
                            completion:completion];
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSFileManager *fm = NSFileManager.defaultManager;
            [self reportProgress:progress stage:ZONBackupStagePreparing detail:nil fraction:0.0];

            NSURL *homeURL = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
            NSURL *documentsSourceURL = [homeURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
            NSURL *librarySourceURL = [homeURL URLByAppendingPathComponent:@"Library" isDirectory:YES];
            NSURL *stagingRootURL = [homeURL URLByAppendingPathComponent:@"tmp/zonoe" isDirectory:YES];
            NSURL *documentsStageURL = [stagingRootURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
            NSURL *libraryStageURL = [stagingRootURL URLByAppendingPathComponent:@"Library" isDirectory:YES];
            NSURL *outputDirectoryURL = [documentsSourceURL URLByAppendingPathComponent:@"zonoe" isDirectory:YES];

            NSError *workspaceError = nil;
            if (![self removePathIfPresent:stagingRootURL fileManager:fm error:&workspaceError] ||
                ![self removePathIfPresent:outputDirectoryURL fileManager:fm error:&workspaceError] ||
                ![self ensureDirectoryURL:documentsStageURL fileManager:fm error:&workspaceError] ||
                ![self ensureDirectoryURL:libraryStageURL fileManager:fm error:&workspaceError]) {
                NSError *wrapped = [self errorWithCode:ZONBackupErrorWorkspace
                                           description:@"无法准备备份工作目录"
                                            underlying:workspaceError];
                [self finishOnMainQueueWithURL:nil error:wrapped completion:completion];
                return;
            }

            [self reportProgress:progress stage:ZONBackupStageScanning detail:@"Documents" fraction:0.0];
            NSError *scanError = nil;
            NSArray<ZONBackupManifestItem *> *documentsManifest =
                [self manifestForRootName:@"Documents"
                                sourceURL:documentsSourceURL
                           destinationURL:documentsStageURL
                             fileManager:fm
                                   error:&scanError];
            if (!documentsManifest) {
                NSError *wrapped = [self errorWithCode:ZONBackupErrorScan
                                           description:@"扫描 Documents 失败"
                                            underlying:scanError];
                [self removePathIfPresent:stagingRootURL fileManager:fm error:nil];
                [self finishOnMainQueueWithURL:nil error:wrapped completion:completion];
                return;
            }

            [self reportProgress:progress stage:ZONBackupStageScanning detail:@"Library" fraction:0.5];
            NSArray<ZONBackupManifestItem *> *libraryManifest =
                [self manifestForRootName:@"Library"
                                sourceURL:librarySourceURL
                           destinationURL:libraryStageURL
                             fileManager:fm
                                   error:&scanError];
            if (!libraryManifest) {
                NSError *wrapped = [self errorWithCode:ZONBackupErrorScan
                                           description:@"扫描 Library 失败"
                                            underlying:scanError];
                [self removePathIfPresent:stagingRootURL fileManager:fm error:nil];
                [self finishOnMainQueueWithURL:nil error:wrapped completion:completion];
                return;
            }
            [self reportProgress:progress stage:ZONBackupStageScanning detail:nil fraction:1.0];

            NSError *copyError = nil;
            if (![self copyManifest:documentsManifest
                               stage:ZONBackupStageCopyingDocuments
                         fileManager:fm
                     decisionHandler:largeItemDecision
                            progress:progress
                               error:&copyError] ||
                ![self copyManifest:libraryManifest
                               stage:ZONBackupStageCopyingLibrary
                         fileManager:fm
                     decisionHandler:largeItemDecision
                            progress:progress
                               error:&copyError]) {
                [self removePathIfPresent:stagingRootURL fileManager:fm error:nil];
                [self finishOnMainQueueWithURL:nil error:copyError completion:completion];
                return;
            }

            NSError *outputError = nil;
            if (![self ensureDirectoryURL:outputDirectoryURL fileManager:fm error:&outputError]) {
                NSError *wrapped = [self errorWithCode:ZONBackupErrorWorkspace
                                           description:@"无法创建备份输出目录"
                                            underlying:outputError];
                [self removePathIfPresent:stagingRootURL fileManager:fm error:nil];
                [self finishOnMainQueueWithURL:nil error:wrapped completion:completion];
                return;
            }

            NSString *archiveName = [resolvedName stringByAppendingPathExtension:@"zip"];
            NSURL *archiveURL = [outputDirectoryURL URLByAppendingPathComponent:archiveName];
            [self reportProgress:progress stage:ZONBackupStageArchiving detail:archiveName fraction:0.0];

            BOOL archiveSuccess = [SSZipArchive createZipFileAtPath:archiveURL.path
                                         withContentsOfDirectory:stagingRootURL.path];
            [self removePathIfPresent:stagingRootURL fileManager:fm error:nil];
            if (!archiveSuccess) {
                NSError *archiveError = [self errorWithCode:ZONBackupErrorArchive
                                                description:@"压缩备份失败"
                                                 underlying:nil];
                [self finishOnMainQueueWithURL:nil error:archiveError completion:completion];
                return;
            }

            [self reportProgress:progress stage:ZONBackupStageArchiving detail:archiveName fraction:1.0];
            [self reportProgress:progress stage:ZONBackupStageCompleted detail:archiveName fraction:1.0];
            [self finishOnMainQueueWithURL:archiveURL error:nil completion:completion];
        }
    });
}

@end
