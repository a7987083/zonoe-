#import "PubgLoad.h"
#import "JHPP.h"
#import "ZONSaveTransferCoordinator.h"

@implementation PubgLoad

- (void)loadddd
{
    [self checkCloudSaveStatus];
}

- (void)yuanchengdwon
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:host];
}

- (void)checkCloudSaveStatus
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:host];
}

@end
