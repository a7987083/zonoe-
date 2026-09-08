#ifndef ZONUDIDCDiag_h
#define ZONUDIDCDiag_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZONUDIDBridge.h"

static inline UIViewController *ZONUDIDCTopViewController(void)
{
    UIViewController *root = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class] ||
                scene.activationState != UISceneActivationStateForegroundActive) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *window in ws.windows) {
                if (window.isKeyWindow) { root = window.rootViewController; break; }
            }
            if (root) break;
        }
    }
    if (!root) root = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    return root;
}

static inline void ZONUDIDCShow(NSString *title, NSString *message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = ZONUDIDCTopViewController();
        if (!vc) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
    });
}

static inline void ZONUDIDCRun(void)
{
    static id observer = nil;
    static NSUInteger generation = 0;
    generation += 1;
    NSUInteger currentGeneration = generation;

    if (observer) {
        [NSNotificationCenter.defaultCenter removeObserver:observer];
        observer = nil;
    }

    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0) {
        ZONUDIDCShow(@"C 获取失败", @"缺少 ZonoeUDIDCallbackScheme。");
        return;
    }

    observer = [NSNotificationCenter.defaultCenter
        addObserverForName:ZONUDIDBridgeDidUpdateNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
        if (currentGeneration != generation) return;
        NSString *udid = [note.object isKindOfClass:NSString.class] ? note.object : ZONUDIDBridgeCurrentUDID();
        if (observer) {
            [NSNotificationCenter.defaultCenter removeObserver:observer];
            observer = nil;
        }
        if (udid.length > 0) {
            ZONUDIDCShow(@"C 获取成功", [NSString stringWithFormat:@"UDID：\n%@", udid]);
        } else {
            ZONUDIDCShow(@"C 获取失败", @"收到更新事件，但 UDID 为空或格式无效。");
        }
    }];

    ZONUDIDBridgeForceRefresh();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (currentGeneration != generation) return;
        NSString *udid = ZONUDIDBridgeCurrentUDID();
        if (observer) {
            [NSNotificationCenter.defaultCenter removeObserver:observer];
            observer = nil;
        }
        if (udid.length > 0) {
            ZONUDIDCShow(@"C 获取成功", [NSString stringWithFormat:@"UDID：\n%@", udid]);
        } else {
            ZONUDIDCShow(@"C 获取失败",
                         @"8 秒内没有取得有效 UDID。\n已使用 callback + nonce + localhost bridge，未安装 AppDelegate/SceneDelegate Hook。");
        }
    });
}

#endif /* ZONUDIDCDiag_h */
