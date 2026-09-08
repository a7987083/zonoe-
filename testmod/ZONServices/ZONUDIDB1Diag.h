#ifndef ZONUDIDB1Diag_h
#define ZONUDIDB1Diag_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static inline UIViewController *ZONUDIDB1TopViewController(void)
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

static inline void ZONUDIDB1Show(NSString *title, NSString *message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = ZONUDIDB1TopViewController();
        if (!vc) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
    });
}

static inline void ZONUDIDB1Run(void)
{
    static id activeObserver = nil;
    static BOOL waitingForReturn = NO;

    NSBundle *bundle = NSBundle.mainBundle;
    NSString *scheme = [bundle objectForInfoDictionaryKey:@"ZonoeUDIDCallbackScheme"];
    NSString *host = [bundle objectForInfoDictionaryKey:@"ZonoeUDIDCallbackHost"];

    if (![scheme isKindOfClass:NSString.class] || scheme.length == 0) {
        ZONUDIDB1Show(@"B1 请求失败", @"缺少 ZonoeUDIDCallbackScheme。");
        return;
    }
    if (![host isKindOfClass:NSString.class] || host.length == 0) host = @"udid-callback";

    NSURLComponents *callback = [NSURLComponents new];
    callback.scheme = scheme;
    callback.host = host;
    if (!callback.URL) {
        ZONUDIDB1Show(@"B1 请求失败", @"callback URL 构造失败。");
        return;
    }

    NSURLComponents *request = [NSURLComponents componentsWithString:@"zonoe://udid"];
    request.queryItems = @[[NSURLQueryItem queryItemWithName:@"callback" value:callback.URL.absoluteString]];
    NSURL *requestURL = request.URL;
    if (!requestURL) {
        ZONUDIDB1Show(@"B1 请求失败", @"zonoe://udid 请求 URL 构造失败。");
        return;
    }

    if (activeObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:activeObserver];
        activeObserver = nil;
    }

    waitingForReturn = YES;
    activeObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(__unused NSNotification *note) {
        if (!waitingForReturn) return;
        waitingForReturn = NO;
        if (activeObserver) {
            [NSNotificationCenter.defaultCenter removeObserver:activeObserver];
            activeObserver = nil;
        }
        ZONUDIDB1Show(@"B1 已返回原 App",
                      @"纯 URL Scheme 基线成功。\n本版本不 Hook，也不读取 callback 中的 UDID。");
    }];

    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (success) return;
        waitingForReturn = NO;
        if (activeObserver) {
            [NSNotificationCenter.defaultCenter removeObserver:activeObserver];
            activeObserver = nil;
        }
        ZONUDIDB1Show(@"B1 请求失败", @"系统未能打开 zonoe://udid。");
    }];
}

#endif /* ZONUDIDB1Diag_h */
