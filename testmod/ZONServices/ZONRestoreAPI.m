#import "ZONRestoreAPI.h"
#import "PreferenceManager.h"

@implementation ZONRestoreAPI

+ (instancetype)sharedAPI
{
    static ZONRestoreAPI *api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api = [[ZONRestoreAPI alloc] init];
    });
    return api;
}

- (NSString *)restoreStagingRootPath
{
    return [[ZONRestoreService sharedService] restoreStagingRootPath];
}

- (NSString *)restoreInboxPathForBundleIdentifier:(NSString *)bundleIdentifier
{
    return [[ZONRestoreService sharedService] restoreInboxPathForBundleIdentifier:bundleIdentifier];
}

- (void)finishRestoreSuccess:(BOOL)success
                       error:(NSError *)error
                  completion:(ZONRestoreCompletion)completion
{
    if (!success) {
        if (completion) completion(NO, error);
        return;
    }

    // Preserve the P66/yidongwenjian post-success contract exactly.
    // PreferenceManager reloads restored preferences, synchronizes them,
    // cleans legacy staging state and exits the game after successful sync.
    [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];

    // Normally PreferenceManager terminates the process. If it returns (for
    // example because synchronize failed), propagate the restore result so the
    // caller can still present an accurate fallback state.
    if (completion) completion(YES, error);
}

- (void)restoreArchiveAtPath:(NSString *)archivePath
                   inboxPath:(NSString *)inboxPath
                  completion:(ZONRestoreCompletion)completion
{
    [[ZONRestoreService sharedService]
     restoreArchiveAtPath:archivePath
     inboxPath:inboxPath
     completion:^(BOOL success, NSError *error) {
        [self finishRestoreSuccess:success error:error completion:completion];
     }];
}

- (void)restorePreparedStagingAtPath:(NSString *)stagingRoot
                          completion:(ZONRestoreCompletion)completion
{
    [[ZONRestoreService sharedService]
     restorePreparedStagingAtPath:stagingRoot
     completion:^(BOOL success, NSError *error) {
        [self finishRestoreSuccess:success error:error completion:completion];
     }];
}

@end
