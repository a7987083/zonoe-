//
//  NSObject+UI.m
//  iOsGods.Cn
//

#import "JHPP.h"
#import "JHDragView.h"
#import "PopupMenuVC.h"
#import "NSObject+UI.h"

@implementation NSObject (UI)

#pragma mark - 显示悬浮按钮

- (void)显示图标
{
    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *vc = [self topViewController];
        UIView *parentView = vc.view;

        JHDragView *view = [parentView viewWithTag:100];

        if (!view)
        {
            view = [[JHDragView alloc] initWithFrame:CGRectMake(
                [UIScreen mainScreen].bounds.size.width - 70,
                130,
                50,
                50
            )];

            view.tag = 100;

            [parentView addSubview:view];
        }
    });
}

#pragma mark - 打开菜单

- (void)vip菜单显示
{
    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *topVC = [self topViewController];
        if (!topVC || [topVC isKindOfClass:[PopupMenuVC class]]) {
            return;
        }

        PopupMenuVC *menu = [PopupMenuVC new];
        menu.modalPresentationStyle = UIModalPresentationOverFullScreen;

        [topVC presentViewController:menu
                            animated:NO
                          completion:nil];
    });
}

// 兼容旧调用名，统一走 vip菜单显示。
- (void)vipaa
{
    [self vip菜单显示];
}

#pragma mark - 获取顶部控制器

- (UIViewController *)topViewController
{
    UIViewController *rootVC = nil;

    if (@available(iOS 13.0, *))
    {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        {
            if ([scene isKindOfClass:UIWindowScene.class] &&
                scene.activationState == UISceneActivationStateForegroundActive)
            {
                UIWindowScene *windowScene = (UIWindowScene *)scene;

                for (UIWindow *window in windowScene.windows)
                {
                    if (window.isKeyWindow)
                    {
                        rootVC = window.rootViewController;
                        break;
                    }
                }
            }
        }
    }

    if (!rootVC)
    {
        rootVC = UIApplication.sharedApplication.keyWindow.rootViewController;
    }

    while (rootVC.presentedViewController)
    {
        rootVC = rootVC.presentedViewController;
    }

    return rootVC;
}

@end
