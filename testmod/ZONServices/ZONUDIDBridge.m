#import "ZONUDIDBridge.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

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

#pragma mark - Localhost bridge fetch (no AppDelegate/SceneDelegate hooks)

NSDictionary * _Nullable ZONUDIDBridgeFetchLocalResultOnce(NSString *nonce)
{
    if (!ZONUDIDBridgeIsPlausibleNonce(nonce)) return nil;

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return nil;

    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 700000;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));

    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons(ZONUDIDBridgePort);
    inet_pton(AF_INET, "127.0.0.1", &address.sin_addr);

    if (connect(fd, (struct sockaddr *)&address, sizeof(address)) != 0) {
        close(fd);
        return nil;
    }

    NSString *request = [NSString stringWithFormat:
                         @"GET /bridge/result/%@ HTTP/1.1\r\nHost: 127.0.0.1:%u\r\nConnection: close\r\n\r\n",
                         nonce, ZONUDIDBridgePort];
    NSData *requestData = [request dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *bytes = requestData.bytes;
    NSUInteger remaining = requestData.length;
    while (remaining > 0) {
        ssize_t written = send(fd, bytes, remaining, 0);
        if (written <= 0) {
            close(fd);
            return nil;
        }
        bytes += written;
        remaining -= (NSUInteger)written;
    }

    NSMutableData *responseData = [NSMutableData data];
    uint8_t buffer[2048];
    while (responseData.length < 65536) {
        ssize_t count = recv(fd, buffer, sizeof(buffer), 0);
        if (count <= 0) break;
        [responseData appendBytes:buffer length:(NSUInteger)count];
    }
    close(fd);

    NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    if (response.length == 0 ||
        (![response hasPrefix:@"HTTP/1.1 200"] && ![response hasPrefix:@"HTTP/1.0 200"])) {
        return nil;
    }

    NSRange separator = [response rangeOfString:@"\r\n\r\n"];
    if (separator.location == NSNotFound) return nil;
    NSString *body = [response substringFromIndex:NSMaxRange(separator)];
    NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : nil;
}

void ZONUDIDBridgeFetchPendingResult(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        static BOOL inFlight = NO;
        if (inFlight || ZONUDIDBridgeCurrentUDID().length > 0) return;

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        NSString *nonce = [defaults stringForKey:ZONUDIDBridgeRequestNonceKey];
        NSTimeInterval requestedAt = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
        if (!ZONUDIDBridgeIsPlausibleNonce(nonce)) return;

        NSTimeInterval age = NSDate.date.timeIntervalSince1970 - requestedAt;
        if (requestedAt <= 0 || age > 90.0) {
            ZONUDIDBridgeClearPendingRequest();
            return;
        }

        inFlight = YES;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSDictionary *result = nil;
            for (NSInteger attempt = 0; attempt < 6 && !result; attempt++) {
                result = ZONUDIDBridgeFetchLocalResultOnce(nonce);
                if (!result) usleep(250000);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                inFlight = NO;
                if (!result) {
                    NSLog(@"[zonoemenu][WARN][udid] localhost bridge result unavailable");
                    return;
                }

                NSString *returnedNonce = [result[@"nonce"] isKindOfClass:NSString.class] ? result[@"nonce"] : nil;
                NSString *udid = [result[@"udid"] isKindOfClass:NSString.class] ? result[@"udid"] : nil;
                NSString *currentNonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];

                if (!ZONUDIDBridgeIsPlausibleNonce(returnedNonce) ||
                    ![returnedNonce isEqualToString:nonce] ||
                    ![returnedNonce isEqualToString:currentNonce]) {
                    NSLog(@"[zonoemenu][WARN][udid] localhost bridge nonce mismatch");
                    return;
                }
                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
                    NSLog(@"[zonoemenu][WARN][udid] localhost bridge returned invalid UDID");
                    return;
                }

                ZONUDIDBridgeStoreUDID(udid);
            });
        });
    });
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
            ZONUDIDBridgeFetchPendingResult();
        }];

        if (@available(iOS 13.0, *)) {
            [center addObserverForName:UISceneDidActivateNotification
                               object:nil
                                queue:NSOperationQueue.mainQueue
                           usingBlock:^(__unused NSNotification *note) {
                ZONUDIDBridgeFetchPendingResult();
            }];
        }
    });
}

#pragma mark - Request

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
