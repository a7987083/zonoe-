#import "ZONLocalFilesCoordinator.h"
#import "SandboxBrowserVC.h"

@implementation ZONLocalFilesCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONLocalFilesCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [[ZONLocalFilesCoordinator alloc] init]; });
    return coordinator;
}

- (BOOL)presentLocalFilesFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) return NO;

    SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (@available(iOS 13.0, *)) {
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
    } else {
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    [hostViewController presentViewController:nav animated:YES completion:nil];
    return YES;
}

@end
