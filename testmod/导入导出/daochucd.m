#import "daochucd.h"
#import "JHPP.h"
#import "ZONBackupCoordinator.h"

@implementation daochucd

- (void)backupasd
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONBackupCoordinator sharedCoordinator] presentBackupFromViewController:host];
}

@end
