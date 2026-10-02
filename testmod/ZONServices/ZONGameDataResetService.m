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

+ (BOOL)isDirectoryEmptyAtPath:(NSString *)path
                         error:(NSError **)error
{
    NSArray<NSString *> *children = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:error];
    return children && children.count == 0;
}

+ (BOOL)clearDirectoryContentsAtPath:(NSString *)path
                allowRuntimeResidue:(BOOL)allowRuntimeResidue
                               error:(NSError **)error
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
        if (allowRuntimeResidue) {
            NSLog(@"⚠️ 运行期目录暂时无法读取，忽略：%@ (%@)", path, listError.localizedDescription);
            return YES;
        }
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
        if ([manager removeItemAtPath:childPath error:&removeError]) {
            continue;
        }
        if (removeError.code == NSFileNoSuchFileError) {
            continue;
        }

        BOOL isDirectory = NO;
        BOOL exists = [manager fileExistsAtPath:childPath isDirectory:&isDirectory];
        if (!exists) {
            continue;
        }

        if (isDirectory) {
            BOOL childAllowsRuntimeResidue = allowRuntimeResidue;
            if ([childPath.lastPathComponent isEqualToString:@"Caches"]) {
                childAllowsRuntimeResidue = YES;
            }

            NSError *recursiveError = nil;
            if (![self clearDirectoryContentsAtPath:childPath
                               allowRuntimeResidue:childAllowsRuntimeResidue
                                              error:&recursiveError]) {
                if (error) *error = recursiveError;
                return NO;
            }

            NSError *secondRemoveError = nil;
            if ([manager removeItemAtPath:childPath error:&secondRemoveError] ||
                secondRemoveError.code == NSFileNoSuchFileError) {
                continue;
            }

            NSError *emptyError = nil;
            BOOL empty = [self isDirectoryEmptyAtPath:childPath error:&emptyError];
            if (empty) {
                // The running process may keep standard container skeleton directories alive.
                // Empty directories are not user/game payload and are safe to preserve.
                NSLog(@"ℹ️ 保留运行期空目录：%@", childPath);
                continue;
            }

            if (childAllowsRuntimeResidue) {
                NSLog(@"⚠️ 运行期目录被系统/框架重新占用，按缓存残留处理：%@", childPath);
                continue;
            }

            if (error) {
                *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                             code:ZONGameDataResetErrorDirectoryCleanup
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法清空目录：%@", childPath],
                                             NSUnderlyingErrorKey: secondRemoveError ?: removeError
                                         }];
            }
            return NO;
        }

        if (allowRuntimeResidue) {
            NSLog(@"⚠️ 运行期缓存文件暂时无法删除，忽略：%@ (%@)", childPath, removeError.localizedDescription);
            continue;
        }

        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorDirectoryCleanup
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法删除文件：%@", childPath],
                                         NSUnderlyingErrorKey: removeError
                                     }];
        }
        return NO;
    }

    return YES;
}

+ (BOOL)directoryContainsPayloadAtPath:(NSString *)path
                   allowRuntimeResidue:(BOOL)allowRuntimeResidue
                                 error:(NSError **)error
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *listError = nil;
    NSArray<NSString *> *children = [manager contentsOfDirectoryAtPath:path error:&listError];
    if (!children) {
        if (allowRuntimeResidue) return NO;
        if (error) {
            *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                         code:ZONGameDataResetErrorVerification
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无法验证目录：%@", path],
                                         NSUnderlyingErrorKey: listError
                                     }];
        }
        return YES;
    }

    for (NSString *child in children) {
        NSString *childPath = [path stringByAppendingPathComponent:child];
        BOOL isDirectory = NO;
        BOOL exists = [manager fileExistsAtPath:childPath isDirectory:&isDirectory];
        if (!exists) continue;

        BOOL childAllowsRuntimeResidue = allowRuntimeResidue;
        if ([childPath.lastPathComponent isEqualToString:@"Caches"]) {
            childAllowsRuntimeResidue = YES;
        }

        if (isDirectory) {
            if ([self directoryContainsPayloadAtPath:childPath
                                allowRuntimeResidue:childAllowsRuntimeResidue
                                              error:error]) {
                return YES;
            }
            continue;
        }

        if (!childAllowsRuntimeResidue) {
            if (error) {
                *error = [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                             code:ZONGameDataResetErrorVerification
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: [NSString stringWithFormat:@"清理后仍存在数据文件：%@", childPath]
                                         }];
            }
            return YES;
        }
    }

    return NO;
}

+ (BOOL)verifyPayloadClearedAtPath:(NSString *)path
              allowRuntimeResidue:(BOOL)allowRuntimeResidue
                            error:(NSError **)error
{
    NSError *payloadError = nil;
    if (![self directoryContainsPayloadAtPath:path
                          allowRuntimeResidue:allowRuntimeResidue
                                        error:&payloadError]) {
        return YES;
    }

    // One final sweep handles data recreated while the app is still alive.
    NSError *cleanupError = nil;
    if (![self clearDirectoryContentsAtPath:path
                       allowRuntimeResidue:allowRuntimeResidue
                                      error:&cleanupError]) {
        if (error) *error = cleanupError;
        return NO;
    }

    payloadError = nil;
    BOOL stillContainsPayload = [self directoryContainsPayloadAtPath:path
                                                  allowRuntimeResidue:allowRuntimeResidue
                                                                error:&payloadError];
    if (stillContainsPayload) {
        if (error) {
            *error = payloadError ?: [NSError errorWithDomain:ZONGameDataResetErrorDomain
                                                         code:ZONGameDataResetErrorVerification
                                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"清理后仍存在业务数据：%@", path]}];
        }
        return NO;
    }

    return YES;
}

+ (BOOL)resetGameDataWithProgress:(ZONGameDataResetProgressHandler)progress
                            error:(NSError **)error
{
    [self reportStage:ZONGameDataResetStagePreparing progress:progress];

    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *home = NSHomeDirectory();
    NSString *documentsPath = [home stringByAppendingPathComponent:@"Documents"];
    NSString *libraryPath = [home stringByAppendingPathComponent:@"Library"];
    NSString *temporaryPath = [home stringByAppendingPathComponent:@"tmp"];

    void (^bestEffortClear)(NSString *, ZONGameDataResetStage) =
    ^(NSString *path, ZONGameDataResetStage stage) {
        [self reportStage:stage progress:progress];

        NSError *rootError = nil;
        if (![manager removeItemAtPath:path error:&rootError] &&
            rootError.code != NSFileNoSuchFileError) {
            NSLog(@"[zonoemenu][WARN][reset] root remove failed, continuing recursively %@: %@",
                  path, rootError.localizedDescription);
        }

        // Preserve the original qcshuju behavior: if the running process/system
        // recreates or protects entries, continue deleting what is removable and
        // never fail the whole reset because of one runtime-owned path.
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:path];
        for (NSString *relativePath in enumerator) {
            NSString *itemPath = [path stringByAppendingPathComponent:relativePath];
            NSError *itemError = nil;
            if (![manager removeItemAtPath:itemPath error:&itemError] &&
                itemError.code != NSFileNoSuchFileError) {
                NSLog(@"[zonoemenu][WARN][reset] ignored runtime/system residue %@: %@",
                      itemPath, itemError.localizedDescription);
            }
        }
    };

    bestEffortClear(documentsPath, ZONGameDataResetStageDocuments);
    bestEffortClear(temporaryPath, ZONGameDataResetStageTemporary);

    [self reportStage:ZONGameDataResetStagePreferences progress:progress];
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    if (bundleIdentifier.length) {
        [NSUserDefaults.standardUserDefaults removePersistentDomainForName:bundleIdentifier];
        [NSUserDefaults.standardUserDefaults synchronize];
    } else {
        NSLog(@"[zonoemenu][WARN][reset] bundle identifier unavailable; skipping defaults domain reset");
    }

    bestEffortClear(libraryPath, ZONGameDataResetStageLibrary);

    // The legacy implementation did not require every system-owned runtime file
    // to disappear before considering the operation complete.
    [self reportStage:ZONGameDataResetStageVerification progress:progress];
    [self reportStage:ZONGameDataResetStageCompleted progress:progress];
    return YES;
}

@end
