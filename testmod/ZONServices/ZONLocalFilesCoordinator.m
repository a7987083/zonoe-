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
    nav.modalPresentationStyle = UIModalPresentationPageSheet;

    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        sheet.detents = @[
            UISheetPresentationControllerDetent.mediumDetent,
            UISheetPresentationControllerDetent.largeDetent
        ];
        sheet.prefersGrabberVisible = YES;
        sheet.prefersScrollingExpandsWhenScrolledToEdge = YES;
    }

    [hostViewController presentViewController:nav animated:YES completion:nil];
    return YES;
}

@end
