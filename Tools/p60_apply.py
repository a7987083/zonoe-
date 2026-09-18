from pathlib import Path

p = Path('testmod/ZONServices/ZONUDIDBridge.m')
s = p.read_text()
assert 'ZONUDIDBridgeOpenRetryDelay' not in s, 'P59 auto-retry code must not be inherited'
assert '获取UDID中' not in s, 'P60 UI already present'

marker = '#pragma mark - Stored value\n'
assert marker in s
ui = r'''#pragma mark - UDID progress UI

static UIAlertController *gZONUDIDProgressAlert = nil;
static void ZONUDIDBridgeBeginAppRequest(dispatch_block_t _Nullable unavailableHandler);

static UIViewController * _Nullable ZONUDIDBridgeTopViewController(void)
{
    UIApplication *application = UIApplication.sharedApplication;
    UIWindow *window = nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive ||
                ![scene isKindOfClass:UIWindowScene.class]) continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *candidate in windowScene.windows) {
                if (candidate.isKeyWindow) {
                    window = candidate;
                    break;
                }
            }
            if (!window) {
                for (UIWindow *candidate in windowScene.windows) {
                    if (!candidate.hidden && candidate.alpha > 0.0 && candidate.rootViewController) {
                        window = candidate;
                        break;
                    }
                }
            }
            if (window) break;
        }
    }

    if (!window) window = application.keyWindow;
    if (!window) {
        for (UIWindow *candidate in application.windows) {
            if (!candidate.hidden && candidate.alpha > 0.0 && candidate.rootViewController) {
                window = candidate;
                break;
            }
        }
    }

    UIViewController *controller = window.rootViewController;
    while (controller) {
        UIViewController *next = nil;
        if (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
            next = controller.presentedViewController;
        } else if ([controller isKindOfClass:UINavigationController.class]) {
            next = ((UINavigationController *)controller).visibleViewController;
        } else if ([controller isKindOfClass:UITabBarController.class]) {
            next = ((UITabBarController *)controller).selectedViewController;
        }
        if (!next || next == controller) break;
        controller = next;
    }
    return controller;
}

static void ZONUDIDBridgeDismissProgressAlert(dispatch_block_t _Nullable completion)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = gZONUDIDProgressAlert;
        gZONUDIDProgressAlert = nil;
        if (!alert || !alert.presentingViewController) {
            if (completion) completion();
            return;
        }
        [alert dismissViewControllerAnimated:YES completion:completion];
    });
}

static void ZONUDIDBridgeShowProgressAlert(dispatch_block_t _Nullable unavailableHandler,
                                            dispatch_block_t launchHandler)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZONUDIDBridgeCurrentUDID().length > 0) return;

        UIAlertController *existing = gZONUDIDProgressAlert;
        if (existing && existing.presentingViewController) {
            if (launchHandler) launchHandler();
            return;
        }

        UIViewController *presenter = ZONUDIDBridgeTopViewController();
        if (!presenter) {
            NSLog(@"[zonoemenu][WARN][udid] no presenter for UDID progress alert");
            if (launchHandler) launchHandler();
            return;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"获取UDID中"
                                                                       message:@"正在通过 Zonoe 获取设备信息，请完成操作。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        __weak UIAlertController *weakAlert = alert;
        [alert addAction:[UIAlertAction actionWithTitle:@"重新获取"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction *action) {
            UIAlertController *strongAlert = weakAlert;
            if (gZONUDIDProgressAlert == strongAlert) gZONUDIDProgressAlert = nil;
            ZONUDIDBridgeClearPendingRequest();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                if (ZONUDIDBridgeCurrentUDID().length > 0) return;
                ZONUDIDBridgeBeginAppRequest(unavailableHandler);
            });
        }]];

        gZONUDIDProgressAlert = alert;
        [presenter presentViewController:alert animated:YES completion:launchHandler];
    });
}

'''
s = s.replace(marker, ui + marker, 1)

old = '''    [defaults setObject:scheme forKey:ZONUDIDBridgeSchemeKey];\n    ZONUDIDBridgeClearPendingRequest();\n\n    [[NSNotificationCenter defaultCenter] postNotificationName:ZONUDIDBridgeDidUpdateNotification'''
new = '''    [defaults setObject:scheme forKey:ZONUDIDBridgeSchemeKey];\n    ZONUDIDBridgeClearPendingRequest();\n    ZONUDIDBridgeDismissProgressAlert(nil);\n\n    [[NSNotificationCenter defaultCenter] postNotificationName:ZONUDIDBridgeDidUpdateNotification'''
assert old in s
s = s.replace(old, new, 1)

start = s.index('#pragma mark - Request\n')
end = s.index('void ZONUDIDBridgeRequestIfNeeded(void)', start)
request = r'''#pragma mark - Request

static void ZONUDIDBridgeBeginAppRequest(dispatch_block_t _Nullable unavailableHandler)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) {
        ZONUDIDBridgeDismissProgressAlert(nil);
        return;
    }

    if (ZONUDIDBridgeCallbackScheme().length == 0) {
        NSLog(@"[zonoemenu][WARN][udid] zonoe callback scheme unavailable; using fallback");
        ZONUDIDBridgeDismissProgressAlert(unavailableHandler);
        return;
    }

    NSString *nonce = ZONUDIDBridgeNewNonce();
    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);
    if (!requestURL) {
        NSLog(@"[zonoemenu][WARN][udid] unable to construct zonoe://udid request; using fallback");
        ZONUDIDBridgeDismissProgressAlert(unavailableHandler);
        return;
    }

    ZONUDIDBridgeShowProgressAlert(unavailableHandler, ^{
        if (ZONUDIDBridgeCurrentUDID().length > 0) return;

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];
        [defaults setDouble:NSDate.date.timeIntervalSince1970 forKey:ZONUDIDBridgeRequestTimestampKey];

        NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");
        [UIApplication.sharedApplication openURL:requestURL
                                         options:@{}
                               completionHandler:^(BOOL success) {
            if (success) return;

            NSString *currentNonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
            if (![currentNonce isEqualToString:nonce]) {
                NSLog(@"[zonoemenu][INFO][udid] ignoring stale zonoe open failure");
                return;
            }

            ZONUDIDBridgeClearPendingRequest();
            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid; using web fallback");
            ZONUDIDBridgeDismissProgressAlert(unavailableHandler);
        }];
    });
}

void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    ZONUDIDBridgeStart();
    ZONUDIDBridgeBeginAppRequest(unavailableHandler);
}

'''
s = s[:start] + request + s[end:]
p.write_text(s)
Path('VERSION').write_text('v1_p60\n')
