//
//  NSObject+UI.m
//  iOsGods.Cn
//

#import "JHPP.h"
#import "JHDragView.h"
#import "PopupMenuVC.h"
#import "NSObject+UI.h"
#import "../ZONServices/ZONUDIDBridge.h"

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

        // zonoemenu 本身是固定浅色设计。部分宿主游戏会强制 Dark Style，
        // 未显式设置 textColor 的 UILabel 会继承白色动态 labelColor，
        // 落在菜单的白色卡片上后看起来像“文字消失”。
        // 只隔离本菜单的界面风格，不修改宿主 App 的全局 appearance。
        if (@available(iOS 13.0, *)) {
            menu.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }

        [topVC presentViewController:menu
                            animated:NO
                          completion:^{
            // Do not touch host URL delegates during +load / launch. Some Unity/Scene
            // hosts are still building their lifecycle graph there. The user tapping
            // the zonoemenu entry is the first safe, explicit point to request UDID.
            if (ZONUDIDBridgeCurrentUDID().length == 0 &&
                ZONUDIDBridgeCallbackScheme().length > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(350 * NSEC_PER_MSEC)),
                               dispatch_get_main_queue(), ^{
                    ZONUDIDBridgeRequestIfNeeded();
                });
            }
        }];
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
