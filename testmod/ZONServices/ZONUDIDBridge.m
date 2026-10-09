#import "ZONUDIDBridge.h"
#import "ZONLegacyUDIDFallbackAdapter.h"


NSString * const ZONUDIDBridgeValueKey = @"zonoe.udid.bridge.value";
NSString * const ZONUDIDBridgeSchemeKey = @"zonoe.udid.bridge.scheme";
NSString * const ZONUDIDBridgeRequestTimestampKey = @"zonoe.udid.bridge.requestTimestamp";
NSString * const ZONUDIDBridgeRequestNonceKey = @"zonoe.udid.bridge.requestNonce";
NSString * const ZONUDIDBridgeDidUpdateNotification = @"zonoe.udid.bridge.didUpdate";
const uint16_t ZONUDIDBridgePort = 14302;

#pragma mark - Callback metadata

NSString * _Nullable ZONUDIDBridgeCallbackScheme(void)
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *scheme = [info[@"ZonoeUDIDCallbackScheme"] isKindOfClass:NSString.class]
        ? info[@"ZonoeUDIDCallbackScheme"] : nil;

    if (scheme.length > 0) return scheme;

    NSArray *urlTypes = [info[@"CFBundleURLTypes"] isKindOfClass:NSArray.class]
        ? info[@"CFBundleURLTypes"] : nil;
    for (id object in urlTypes) {
        if (![object isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *type = object;
        if (![[type[@"CFBundleURLName"] description] isEqualToString:@"zonoe.udid.callback"]) continue;
        NSArray *schemes = [type[@"CFBundleURLSchemes"] isKindOfClass:NSArray.class]
            ? type[@"CFBundleURLSchemes"] : nil;
        for (id value in schemes) {
            if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
        }
    }
    return nil;
}

NSString *ZONUDIDBridgeCallbackHost(void)
{
    id value = NSBundle.mainBundle.infoDictionary[@"ZonoeUDIDCallbackHost"];
    if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    return @"udid-callback";
}

NSURL * _Nullable ZONUDIDBridgeCallbackURL(void)
{
    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0) return nil;

    NSURLComponents *components = [NSURLComponents new];
    components.scheme = scheme;
    components.host = ZONUDIDBridgeCallbackHost();
    return components.URL;
}

#pragma mark - Nonce

BOOL ZONUDIDBridgeIsPlausibleNonce(NSString *value)
{
    if (![value isKindOfClass:NSString.class]) return NO;
    if (value.length < 16 || value.length > 128) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"];
    return [value rangeOfCharacterFromSet:allowed.invertedSet].location == NSNotFound;
}

NSString *ZONUDIDBridgeNewNonce(void)
{
    return [[[NSUUID UUID].UUIDString lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

NSURL * _Nullable ZONUDIDBridgeRequestURLForNonce(NSString *nonce)
{
    NSURL *callbackURL = ZONUDIDBridgeCallbackURL();
    if (!callbackURL || !ZONUDIDBridgeIsPlausibleNonce(nonce)) return nil;

    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"zonoe";
    components.host = @"udid";
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"callback" value:callbackURL.absoluteString],
        [NSURLQueryItem queryItemWithName:@"nonce" value:nonce]
    ];
    return components.URL;
}

NSURL * _Nullable ZONUDIDBridgeRequestURL(void)
{
    NSString *nonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
    if (!ZONUDIDBridgeIsPlausibleNonce(nonce)) nonce = ZONUDIDBridgeNewNonce();
    return ZONUDIDBridgeRequestURLForNonce(nonce);
}

#pragma mark - UDID progress UI

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

#pragma mark - Stored value

BOOL ZONUDIDBridgeIsPlausibleUDID(NSString *value)
{
    if (![value isKindOfClass:NSString.class]) return NO;
    NSString *trimmed = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length < 8 || trimmed.length > 128) return NO;

    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"];
    return [trimmed rangeOfCharacterFromSet:allowed.invertedSet].location == NSNotFound;
}

NSString * _Nullable ZONUDIDBridgeCurrentUDID(void)
{
    NSString *currentScheme = ZONUDIDBridgeCallbackScheme();
    if (currentScheme.length == 0) return nil;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *storedScheme = [defaults stringForKey:ZONUDIDBridgeSchemeKey];
    NSString *storedUDID = [defaults stringForKey:ZONUDIDBridgeValueKey];

    if (storedScheme.length == 0 ||
        [storedScheme caseInsensitiveCompare:currentScheme] != NSOrderedSame ||
        !ZONUDIDBridgeIsPlausibleUDID(storedUDID)) {
        return nil;
    }
    return storedUDID;
}

void ZONUDIDBridgeClearPendingRequest(void)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeRequestTimestampKey];
    [defaults removeObjectForKey:ZONUDIDBridgeRequestNonceKey];
}

void ZONUDIDBridgeStoreUDID(NSString *udid)
{
    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0 || !ZONUDIDBridgeIsPlausibleUDID(udid)) return;

    NSString *trimmed = [udid stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:trimmed forKey:ZONUDIDBridgeValueKey];
    [defaults setObject:scheme forKey:ZONUDIDBridgeSchemeKey];
    ZONUDIDBridgeClearPendingRequest();
    ZONUDIDBridgeDismissProgressAlert(nil);

    [[NSNotificationCenter defaultCenter] postNotificationName:ZONUDIDBridgeDidUpdateNotification
                                                        object:trimmed];
    NSLog(@"[zonoemenu][INFO][udid] bridge result received (%lu chars)", (unsigned long)trimmed.length);
}

#pragma mark - Callback URL compatibility parser

BOOL ZONUDIDBridgeHandleURL(NSURL *url)
{
    if (![url isKindOfClass:NSURL.class]) return NO;

    NSString *expectedScheme = ZONUDIDBridgeCallbackScheme();
    NSString *expectedHost = ZONUDIDBridgeCallbackHost();
    if (expectedScheme.length == 0) return NO;
    if ([url.scheme caseInsensitiveCompare:expectedScheme] != NSOrderedSame) return NO;
    if (expectedHost.length > 0 && [url.host caseInsensitiveCompare:expectedHost] != NSOrderedSame) return NO;

    NSString *expectedNonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
    if (!ZONUDIDBridgeIsPlausibleNonce(expectedNonce)) {
        NSLog(@"[zonoemenu][WARN][udid] callback arrived without an active nonce");
        return YES;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *udid = nil;
    NSString *nonce = nil;
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        if ([item.name isEqualToString:@"udid"] && item.value.length > 0) udid = item.value;
        if ([item.name isEqualToString:@"nonce"] && item.value.length > 0) nonce = item.value;
    }

    if (!ZONUDIDBridgeIsPlausibleNonce(nonce) || ![nonce isEqualToString:expectedNonce]) {
        NSLog(@"[zonoemenu][WARN][udid] callback nonce mismatch");
        return YES;
    }
    if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
        NSLog(@"[zonoemenu][WARN][udid] callback UDID missing or invalid");
        return YES;
    }

    ZONUDIDBridgeStoreUDID(udid);
    return YES;
}

void ZONUDIDBridgeStart(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserverForName:UIApplicationDidBecomeActiveNotification
                           object:nil
                            queue:NSOperationQueue.mainQueue
                       usingBlock:^(__unused NSNotification *note) {
            ZONResumeLegacyWebUDIDFallbackIfNeeded();
        }];

        if (@available(iOS 13.0, *)) {
            [center addObserverForName:UISceneDidActivateNotification
                               object:nil
                                queue:NSOperationQueue.mainQueue
                           usingBlock:^(__unused NSNotification *note) {
                    ZONResumeLegacyWebUDIDFallbackIfNeeded();
            }];
        }
    });
}


#pragma mark - Request

static void ZONUDIDBridgeBeginAppRequest(dispatch_block_t _Nullable unavailableHandler)
{
    // Compatibility entry point: the production UDID acquisition path is website-based.
    // Keep this API callable without recreating the retired localhost listener.
    (void)unavailableHandler;
    ZONStartLegacyWebUDIDFallback();
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

void ZONUDIDBridgeRequestIfNeeded(void)
{
    ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(nil);
}

void ZONUDIDBridgeForceRefreshWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];
    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];
    ZONUDIDBridgeClearPendingRequest();

    dispatch_async(dispatch_get_main_queue(), ^{
        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(unavailableHandler);
    });
}

void ZONUDIDBridgeForceRefresh(void)
{
    ZONUDIDBridgeForceRefreshWithUnavailableHandler(nil);
}
