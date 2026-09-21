#import "ZONRestoreService.h"
#import "ZONRestorePolicy.h"
#import "SSZipArchive.h"

NSErrorDomain const ZONRestoreErrorDomain = @"ZONRestoreErrorDomain";

@interface ZONRestoreService ()
@property (nonatomic, strong) dispatch_queue_t restoreQueue;
@end

@implementation ZONRestoreService

+ (instancetype)sharedService
{
    static ZONRestoreService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[ZONRestoreService alloc] initPrivate];
    });
    return service;
}

- (instancetype)init
{
    return [ZONRestoreService sharedService];
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _restoreQueue = dispatch_queue_create("com.zonoe.restore.serial", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)restoreStagingRootPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];
}

- (NSString *)restoreInboxPathForBundleIdentifier:(NSString *)bundleIdentifier
{
    NSString *tmpRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
    return [tmpRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-Inbox", bundleIdentifier ?: @""]];
}

- (NSError *)errorWithCode:(ZONRestoreErrorCode)code description:(NSString *)description underlying:(NSError *)underlying
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (description.length) userInfo[NSLocalizedDescriptionKey] = description;
    if (underlying) userInfo[NSUnderlyingErrorKey] = underlying;
    return [NSError errorWithDomain:ZONRestoreErrorDomain code:code userInfo:userInfo];
}

- (void)finish:(ZONRestoreCompletion)completion success:(BOOL)success error:(NSError *)error
{
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(success, error);
    });
}

- (BOOL)cleanupPath:(NSString *)path error:(NSError **)error
{
    if (path.length == 0) return YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) return YES;
    return [fm removeItemAtPath:path error:error];
}

- (BOOL)prepareStagingRoot:(NSString *)stagingRoot error:(NSError **)error
{
    NSError *cleanupError = nil;
    if (![self cleanupPath:stagingRoot error:&cleanupError]) {
        if (error) *error = [self errorWithCode:ZONRestoreErrorStagingPrepareFailed
                                    description:@"无法清理恢复临时目录"
                                     underlying:cleanupError];
        return NO;
    }

    NSError *createError = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:stagingRoot
                                              withIntermediateDirectories:YES
                                                               attributes:nil
                                                                    error:&createError];
    if (!created && error) {
        *error = [self errorWithCode:ZONRestoreErrorStagingPrepareFailed
                         description:@"无法创建恢复临时目录"
                          underlying:createError];
    }
    return created;
}

- (BOOL)directoryExistsAtPath:(NSString *)path fileManager:(NSFileManager *)fm
{
    BOOL isDirectory = NO;
    return path.length > 0 && [fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory;
}

- (NSDictionary<NSString *, NSString *> *)commonBackupRootAtPath:(NSString *)root
                                                      fileManager:(NSFileManager *)fm
{
    if (![self directoryExistsAtPath:root fileManager:fm]) return nil;

    NSString *documents = [root stringByAppendingPathComponent:@"Documents"];
    NSString *library = [root stringByAppendingPathComponent:@"Library"];
    BOOL hasDocuments = [self directoryExistsAtPath:documents fileManager:fm];
    BOOL hasLibrary = [self directoryExistsAtPath:library fileManager:fm];
    if (hasDocuments || hasLibrary) {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObject:root forKey:@"root"];
        if (hasDocuments) result[@"Documents"] = documents;
        if (hasLibrary) result[@"Library"] = library;
        if (hasDocuments && hasLibrary) result[@"complete"] = @"1";
        return result;
    }

    NSError *listError = nil;
    NSArray<NSString *> *items = [fm contentsOfDirectoryAtPath:root error:&listError];
    if (!items) return nil;

    NSDictionary *fallback = nil;
    for (NSString *item in [items sortedArrayUsingSelector:@selector(compare:)]) {
        if ([item hasPrefix:@"."] || [item isEqualToString:@"__MACOSX"]) continue;
        NSString *child = [root stringByAppendingPathComponent:item];
        if (![self directoryExistsAtPath:child fileManager:fm]) continue;
        NSDictionary *candidate = [self commonBackupRootAtPath:child fileManager:fm];
        if ([candidate[@"complete"] boolValue]) return candidate;
        if (!fallback && candidate) fallback = candidate;
    }
    return fallback;
}

- (NSString *)legacyFindTargetDirectory:(NSString *)target root:(NSString *)root fileManager:(NSFileManager *)fm
{
    if (![self directoryExistsAtPath:root fileManager:fm]) return nil;
    NSArray<NSString *> *items = [fm contentsOfDirectoryAtPath:root error:nil];
    for (NSString *item in items) {
        if ([item hasPrefix:@"."] || [item isEqualToString:@"__MACOSX"]) continue;
        NSString *path = [root stringByAppendingPathComponent:item];
        if (![self directoryExistsAtPath:path fileManager:fm]) continue;
        if ([item isEqualToString:target]) return path;
        NSString *nested = [self legacyFindTargetDirectory:target root:path fileManager:fm];
        if (nested) return nested;
    }
    return nil;
}

- (BOOL)preflightRestoreRoot:(NSString *)root
                   documents:(NSString **)documentsOut
                     library:(NSString **)libraryOut
                       error:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *candidate = [self commonBackupRootAtPath:root fileManager:fm];
    NSString *documents = candidate[@"Documents"];
    NSString *library = candidate[@"Library"];

    // Compatibility fallback for historical archives whose Documents/Library were found independently.
    if (!documents) documents = [self legacyFindTargetDirectory:@"Documents" root:root fileManager:fm];
    if (!library) library = [self legacyFindTargetDirectory:@"Library" root:root fileManager:fm];

    if (!documents && !library) {
        if (error) *error = [self errorWithCode:ZONRestoreErrorBackupRootNotFound
                                    description:@"恢复包中未找到 Documents 或 Library"
                                     underlying:nil];
        return NO;
    }

    NSString *dstDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dstLibrary = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    if (dstDocuments.length == 0 || dstLibrary.length == 0) {
        if (error) *error = [self errorWithCode:ZONRestoreErrorPreflightFailed
                                    description:@"无法解析当前应用数据目录"
                                     underlying:nil];
        return NO;
    }

    if (documentsOut) *documentsOut = documents;
    if (libraryOut) *libraryOut = library;
    return YES;
}

+ (BOOL)copyContentsFrom:(NSString *)sourcePath
                      to:(NSString *)destinationPath
             fileManager:(NSFileManager *)fm
               skipItems:(NSSet<NSString *> *)skipItems
                   error:(NSError **)error
{
    BOOL sourceIsDirectory = NO;
    if (![fm fileExistsAtPath:sourcePath isDirectory:&sourceIsDirectory]) {
        if (error) *error = [NSError errorWithDomain:ZONRestoreErrorDomain
                                                code:ZONRestoreErrorPreflightFailed
                                            userInfo:@{NSLocalizedDescriptionKey: @"恢复源文件不存在"}];
        return NO;
    }

    BOOL destinationIsDirectory = NO;
    BOOL destinationExists = [fm fileExistsAtPath:destinationPath isDirectory:&destinationIsDirectory];
    if (destinationExists && sourceIsDirectory != destinationIsDirectory) {
        if (![fm removeItemAtPath:destinationPath error:error]) return NO;
        destinationExists = NO;
    }

    if (sourceIsDirectory) {
        if (!destinationExists && ![fm createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:error]) {
            return NO;
        }
        NSArray<NSString *> *items = [fm contentsOfDirectoryAtPath:sourcePath error:error];
        if (!items) return NO;
        for (NSString *item in items) {
            if ([skipItems containsObject:item]) continue;
            if (![self copyContentsFrom:[sourcePath stringByAppendingPathComponent:item]
                                     to:[destinationPath stringByAppendingPathComponent:item]
                            fileManager:fm
                              skipItems:skipItems
                                  error:error]) {
                return NO;
            }
        }
        return YES;
    }

    if (destinationExists && ![fm removeItemAtPath:destinationPath error:error]) return NO;
    return [fm copyItemAtPath:sourcePath toPath:destinationPath error:error];
}

- (BOOL)applyPreparedRestoreAtRoot:(NSString *)root error:(NSError **)error
{
    NSString *sourceDocuments = nil;
    NSString *sourceLibrary = nil;
    if (![self preflightRestoreRoot:root documents:&sourceDocuments library:&sourceLibrary error:error]) return NO;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSSet<NSString *> *skipItems = [ZONRestorePolicy legacySkipItems];

    if (sourceDocuments) {
        NSError *copyError = nil;
        NSString *destination = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        if (![ZONRestoreService copyContentsFrom:sourceDocuments to:destination fileManager:fm skipItems:skipItems error:&copyError]) {
            if (error) *error = [self errorWithCode:ZONRestoreErrorDocumentsApplyFailed
                                        description:@"Documents 恢复失败"
                                         underlying:copyError];
            return NO;
        }
    }

    if (sourceLibrary) {
        NSError *copyError = nil;
        NSString *destination = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        if (![ZONRestoreService copyContentsFrom:sourceLibrary to:destination fileManager:fm skipItems:skipItems error:&copyError]) {
            if (error) *error = [self errorWithCode:ZONRestoreErrorLibraryApplyFailed
                                        description:@"Library 恢复失败"
                                         underlying:copyError];
            return NO;
        }
    }

    return YES;
}

- (void)restoreArchiveAtPath:(NSString *)archivePath
                   inboxPath:(NSString *)inboxPath
                  completion:(ZONRestoreCompletion)completion
{
    dispatch_async(self.restoreQueue, ^{
        if (archivePath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:archivePath]) {
            [self finish:completion success:NO error:[self errorWithCode:ZONRestoreErrorInvalidInput description:@"恢复文件不存在" underlying:nil]];
            return;
        }
        if (![[[archivePath pathExtension] lowercaseString] isEqualToString:@"zip"]) {
            [self finish:completion success:NO error:[self errorWithCode:ZONRestoreErrorInvalidInput description:@"恢复文件不是 ZIP" underlying:nil]];
            return;
        }

        NSString *stagingRoot = [self restoreStagingRootPath];
        NSError *prepareError = nil;
        if (![self prepareStagingRoot:stagingRoot error:&prepareError]) {
            [self finish:completion success:NO error:prepareError];
            return;
        }

        NSError *unzipError = nil;
        BOOL extracted = [SSZipArchive unzipFileAtPath:archivePath
                                         toDestination:stagingRoot
                                             overwrite:YES
                                              password:nil
                                                 error:&unzipError];

        // Own only the selected archive. Remove Inbox only when it becomes empty.
        [[NSFileManager defaultManager] removeItemAtPath:archivePath error:nil];
        if (inboxPath.length) {
            NSArray *remaining = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxPath error:nil];
            if (remaining.count == 0) [[NSFileManager defaultManager] removeItemAtPath:inboxPath error:nil];
        }

        if (!extracted) {
            [self cleanupPath:stagingRoot error:nil];
            NSError *wrapped = [self errorWithCode:ZONRestoreErrorArchiveExtractFailed description:@"解压恢复包失败" underlying:unzipError];
            [self finish:completion success:NO error:wrapped];
            return;
        }

        NSError *restoreError = nil;
        BOOL restored = [self applyPreparedRestoreAtRoot:stagingRoot error:&restoreError];
        NSError *cleanupError = nil;
        BOOL cleaned = [self cleanupPath:stagingRoot error:&cleanupError];
        if (!restored) {
            [self finish:completion success:NO error:restoreError];
            return;
        }
        if (!cleaned) {
            [self finish:completion success:YES error:[self errorWithCode:ZONRestoreErrorCleanupFailed description:@"恢复完成，但临时文件清理失败" underlying:cleanupError]];
            return;
        }
        [self finish:completion success:YES error:nil];
    });
}

- (void)restorePreparedStagingAtPath:(NSString *)stagingRoot completion:(ZONRestoreCompletion)completion
{
    dispatch_async(self.restoreQueue, ^{
        if (![self directoryExistsAtPath:stagingRoot fileManager:[NSFileManager defaultManager]]) {
            [self finish:completion success:NO error:[self errorWithCode:ZONRestoreErrorInvalidInput description:@"恢复临时目录不存在" underlying:nil]];
            return;
        }

        NSError *restoreError = nil;
        BOOL restored = [self applyPreparedRestoreAtRoot:stagingRoot error:&restoreError];
        NSError *cleanupError = nil;
        BOOL cleaned = [self cleanupPath:stagingRoot error:&cleanupError];
        if (!restored) {
            [self finish:completion success:NO error:restoreError];
            return;
        }
        if (!cleaned) {
            [self finish:completion success:YES error:[self errorWithCode:ZONRestoreErrorCleanupFailed description:@"恢复完成，但临时文件清理失败" underlying:cleanupError]];
            return;
        }
        [self finish:completion success:YES error:nil];
    });
}

@end
