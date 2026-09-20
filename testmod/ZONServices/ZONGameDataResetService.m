#import "ZONGameDataResetService.h"

static NSString * const ZONGameDataResetErrorDomain = @"com.zonoe.game-data-reset";

typedef NS_ENUM(NSInteger, ZONGameDataResetErrorCode) {
    ZONGameDataResetErrorDirectoryPreparation = 1,
    ZONGameDataResetErrorDirectoryCleanup,
    ZONGameDataResetErrorDefaultsReset,
    ZONGameDataResetErrorVerification,
};

@implementation ZONGameDataResetService

+ (void)reportStage:(ZONGameDataResetStage)stage
           progress:(ZONGameDataResetProgressHandler)progress
{
    if (progress) progress(stage);
}

+ (BOOL)ensureDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL isDirectory = NO;
    if ([manager fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) return YES;

        NSError *removeError = nil;
        if (![manager removeItemAtPath:path error:&removeError]) {
            if (error) *error = removeError;
            return NO;
        }
    }

    return [manager createDirectoryAtPath:path
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:error];
}

+ (BOOL)clearContentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    NSError *prepareError = nil;
    if (![self ensureDirectoryAtPath:path error:&prepareError]) {
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorDirectoryPreparation
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法准备目录：%@", path],
                                         NSUnderlyingErrorKey: prepareError
                                     }];
        }
        return NO;
    }

    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *listError = nil;
    NSArray<NSString *> *children = [manager contentsOfDirectoryAtPath:path error:&listError];
    if (!children) {
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorDirectoryCleanup
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法读取目录：%@", path],
                                         NSUnderlyingErrorKey: listError
                                     }];
        }
        return NO;
    }

    for (NSString *child in children) {
        NSString *childPath = [path stringByAppendingPathComponent:child];
        NSError *removeError = nil;
        if (![manager removeItemAtPath:childPath error:&removeError]) {
            if (removeError.code == NSFileNoSuchFileError) continue;
            if (error) {
                *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                             code:ZONGameDataResetErrorDirectoryCleanup
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法删除：%@", childPath],
                                             NSUnderlyingErrorKey: removeError
                                         }];
            }
            return NO;
        }
    }

    return YES;
}

+ (BOOL)verifyDirectoryIsEmptyAtPath:(NSString *)path error:(NSError **)error
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *listError = nil;
    NSArray<NSString *> *children = [manager contentsOfDirectoryAtPath:path error:&listError];
    if (!children) {
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorVerification
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法验证目录：%@", path],
                                         NSUnderlyingErrorKey: listError
                                     }];
        }
        return NO;
    }

    if (children.count != 0) {
        // One final sweep handles files recreated while the app is still alive.
        NSError *cleanupError = nil;
        if (![self clearContentsOfDirectoryAtPath:path error:&cleanupError]) {
            if (error) *error = cleanupError;
            return NO;
        }

        children = [manager contentsOfDirectoryAtPath:path error:&listError];
        if (!children || children.count != 0) {
            if (error) {
                *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                             code:ZONGameDataResetErrorVerification
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: [NSString stringWithFormat:@"目录清理后仍存在数据：%@", path]
                                         }];
            }
            return NO;
        }
    }

    return YES;
}

+ (BOOL)resetGameDataWithProgress:(ZONGameDataResetProgressHandler)progress
                            error:(NSError **)error
{
    [self reportStage:ZONGameDataResetStagePreparing progress:progress];

    NSString *home = NSHomeDirectory();
    NSString *documentsPath = [home stringByAppendingPathComponent:@"Documents"];
    NSString *libraryPath = [home stringByAppendingPathComponent:@"Library"];
    NSString *temporaryPath = [home stringByAppendingPathComponent:@"tmp"];

    [self reportStage:ZONGameDataResetStageDocuments progress:progress];
    if (![self clearContentsOfDirectoryAtPath:documentsPath error:error]) return NO;

    [self reportStage:ZONGameDataResetStageTemporary progress:progress];
    if (![self clearContentsOfDirectoryAtPath:temporaryPath error:error]) return NO;

    [self reportStage:ZONGameDataResetStagePreferences progress:progress];
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    if (bundleIdentifier.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorDefaultsReset
                                     userInfo:@{NSLocalizedDescriptionKey: @"无法取得 Bundle Identifier，不能安全重置本地设置"}];
        }
        return NO;
    }
    [NSUserDefaults.standardUserDefaults removePersistentDomainForName:bundleIdentifier];
    [NSUserDefaults.standardUserDefaults synchronize];

    [self reportStage:ZONGameDataResetStageLibrary progress:progress];
    if (![self clearContentsOfDirectoryAtPath:libraryPath error:error]) return NO;

    [self reportStage:ZONGameDataResetStageVerification progress:progress];
    if (![self verifyDirectoryIsEmptyAtPath:documentsPath error:error]) return NO;
    if (![self verifyDirectoryIsEmptyAtPath:libraryPath error:error]) return NO;
    if (![self verifyDirectoryIsEmptyAtPath:temporaryPath error:error]) return NO;

    NSDictionary *remainingDefaults = [NSUserDefaults.standardUserDefaults persistentDomainForName:bundleIdentifier];
    if (remainingDefaults.count != 0) {
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorVerification
                                     userInfo:@{NSLocalizedDescriptionKey: @"本地设置清理后仍存在持久化数据"}];
        }
        return NO;
    }

    [self reportStage:ZONGameDataResetStageCompleted progress:progress];
    return YES;
}

@end
