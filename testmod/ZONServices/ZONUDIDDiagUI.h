#ifndef ZONUDIDDiagUI_h
#define ZONUDIDDiagUI_h

// v1_p2 B diagnostic: nonce + localhost bridge with explicit success/failure popup.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZONUDIDBridge.h"

static inline UIViewController *ZONUDIDDiagTopViewController(void)
{
    UIViewController *root = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.activationState != UISceneActivationStateForegroundActive) continue;
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

static inline void ZONUDIDDiagShow(NSString *title, NSString *message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = ZONUDIDDiagTopViewController();
        if (!vc) return;
        if ([vc isKindOfClass:UIAlertController.class]) {
            [vc dismissViewControllerAnimated:NO completion:nil];
            vc = ZONUDIDDiagTopViewController();
            if (!vc) return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
    });
}

static inline void ZONUDIDDiagRun(NSString *variant)
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
        ZONUDIDDiagShow([NSString stringWithFormat:@"%@ 获取失败", variant],
                        @"当前 App 没有 ZonoeUDIDCallbackScheme。请先使用 zonoe 注册 UDID 回调后重新签名。");
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
            ZONUDIDDiagShow([NSString stringWithFormat:@"%@ 获取成功", variant],
                            [NSString stringWithFormat:@"UDID：\n%@", udid]);
        } else {
            ZONUDIDDiagShow([NSString stringWithFormat:@"%@ 获取失败", variant], @"收到更新事件，但 UDID 为空或格式无效。");
        }
    }];

    ZONUDIDBridgeForceRefresh();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (currentGeneration != generation) return;
        NSString *udid = ZONUDIDBridgeCurrentUDID();
        if (observer) {
            [NSNotificationCenter.defaultCenter removeObserver:observer];
            observer = nil;
        }
        if (udid.length > 0) {
            ZONUDIDDiagShow([NSString stringWithFormat:@"%@ 获取成功", variant],
                            [NSString stringWithFormat:@"UDID：\n%@", udid]);
        } else {
            ZONUDIDDiagShow([NSString stringWithFormat:@"%@ 获取失败", variant],
                            @"8 秒内没有取得有效 UDID。请记录是否成功跳转 zonoe、是否成功返回原 App，以及是否发生闪退。");
        }
    });
}

#endif /* ZONUDIDDiagUI_h */
