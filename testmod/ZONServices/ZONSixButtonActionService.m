#import "ZONSixButtonActionService.h"
#import "ZONSaveTransferCoordinator.h"
#import "ZONBackupCoordinator.h"
#import "ZONLocalRestoreCoordinator.h"
#import "ZONResetCoordinator.h"
#import "ZONRuntimeDirectoryService.h"


@implementation ZONSixButtonActionService

#pragma mark - Shared helpers

+ (NSString *)temporaryDirectoryPath
{
    return [ZONRuntimeDirectoryService temporaryDirectoryPath];
}

+ (BOOL)ensureTemporaryDirectory
{
    return [ZONRuntimeDirectoryService ensureTemporaryDirectory];
}


#pragma mark - Existing action adapters

+ (BOOL)performRemoteDownloadFromViewController:(UIViewController *)hostViewController
{
    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performCloudSaveFromViewController:(UIViewController *)hostViewController
{
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
