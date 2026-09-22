#import "ZONSixButtonActionService.h"
#import "ZONSaveTransferCoordinator.h"
#import "ZONBackupCoordinator.h"
#import "ZONLocalRestoreCoordinator.h"
#import "ZONResetCoordinator.h"


@implementation ZONSixButtonActionService

#pragma mark - Shared helpers

+ (NSString *)temporaryDirectoryPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}

+ (BOOL)ensureTemporaryDirectory
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *tmpPath = [self temporaryDirectoryPath];
    BOOL isDirectory = NO;

    if ([manager fileExistsAtPath:tmpPath isDirectory:&isDirectory]) {
        if (isDirectory) return YES;
        [manager removeItemAtPath:tmpPath error:nil];
    }

    NSError *error = nil;
    BOOL created = [manager createDirectoryAtPath:tmpPath
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:&error];
    if (!created) {
        NSLog(@"❌ 创建 tmp 目录失败 %@: %@", tmpPath, error.localizedDescription);
    }
    return created;
}


#pragma mark - Existing action adapters

+ (BOOL)performRemoteDownloadFromViewController:(UIViewController *)hostViewController
{
    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performCloudSaveFromViewController:(UIViewController *)hostViewController
{
    [self ensureTemporaryDirectory];
    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performBackupSaveFromViewController:(UIViewController *)hostViewController
{
    [[ZONBackupCoordinator sharedCoordinator] presentBackupFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performRestoreSaveFromViewController:(UIViewController *)hostViewController
{
    [[ZONLocalRestoreCoordinator sharedCoordinator] presentLocalRestoreFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performClearGameDataFromViewController:(UIViewController *)hostViewController
{
    [[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performClearAuthorizationFromViewController:(UIViewController *)hostViewController
{
    [[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];
    return YES;
}

#pragma mark - Compatibility surface

+ (void)clearGameDataPreservingTemporaryDirectory
{
    [[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];
}

@end
