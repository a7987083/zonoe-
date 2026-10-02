#import "ZONLegacyUDIDFallbackAdapter.h"
#import "ZONUDIDBridge.h"
#import "../category/getKeychain.h"
#import "ZONLaunchTrace.h"
#import <UIKit/UIKit.h>

static BOOL gZonoeLegacyWebFallbackInFlight = NO;
static NSString * const ZONLegacyUDIDBaseURLString = @"https://yz.zonoeios.xyz/udid/";
static NSString * const ZONLegacyUDIDAppCode = @"79870831";
static NSString * const ZONLegacyUDIDPendingTimestampKey = @"zonoe.legacy.udid.pendingAt";
static const NSTimeInterval ZONLegacyUDIDPendingMaxAge = 600.0;

static NSString *ZONLegacyRandomUserID(void)
{
    static NSString * const alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *value = [NSMutableString stringWithCapacity:15];
    for (NSUInteger index = 0; index < 15; index++) {
        uint32_t position = arc4random_uniform((uint32_t)alphabet.length);
        [value appendFormat:@"%C", [alphabet characterAtIndex:position]];
    }
    return value;
}

static NSString *ZONLegacyURLScheme(void)
{
    NSArray *urlTypes = [NSBundle mainBundle].infoDictionary[@"CFBundleURLTypes"];
    if (![urlTypes isKindOfClass:NSArray.class]) return @"";
    for (NSDictionary *entry in urlTypes) {
        NSArray *schemes = [entry[@"CFBundleURLSchemes"] isKindOfClass:NSArray.class] ? entry[@"CFBundleURLSchemes"] : nil;
        NSString *scheme = [schemes.firstObject isKindOfClass:NSString.class] ? schemes.firstObject : @"";
        if (scheme.length) return scheme;
    }
    return @"";
}

static UIViewController *ZONLegacyTopViewController(void)
{
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if (!window) {
        for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
            if (candidate.isKeyWindow) { window = candidate; break; }
        }
    }
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) controller = controller.presentedViewController;
    return controller;
}

static void ZONLegacyFinishFallback(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        gZonoeLegacyWebFallbackInFlight = NO;
    });
}

static void ZONLegacyClearPendingMarker(void)
{
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ZONLegacyUDIDPendingTimestampKey];
}

static void ZONLegacyMarkPending(void)
{
    [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970
                                             forKey:ZONLegacyUDIDPendingTimestampKey];
}

static BOOL ZONLegacyHasFreshPendingMarker(void)
{
    NSTimeInterval pendingAt = [NSUserDefaults.standardUserDefaults doubleForKey:ZONLegacyUDIDPendingTimestampKey];
    if (pendingAt <= 0) return NO;

    NSTimeInterval age = NSDate.date.timeIntervalSince1970 - pendingAt;
    if (age < 0 || age > ZONLegacyUDIDPendingMaxAge) {
        ZONLegacyClearPendingMarker();
        return NO;
    }
    return YES;
}

static void ZONLegacyRemoveServerCache(NSString *userID)
{
    if (!userID.length) return;
    NSString *urlString = [NSString stringWithFormat:@"%@udid.php?rm=%@", ZONLegacyUDIDBaseURLString, userID];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(__unused NSData *data,
                                                                          __unused NSURLResponse *response,
                                                                          __unused NSError *error) {}] resume];
}

static void ZONLegacyPresentBlockedMessage(NSString *message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *host = ZONLegacyTopViewController();
        if (!host) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设备拉黑"
                                                                       message:(message.length ? message : @"当前设备不可用")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            exit(0);
        }]];
        [host presentViewController:alert animated:YES completion:nil];
    });
}

static void ZONLegacyOpenProfileInstaller(NSString *userID)
{
    NSString *scheme = ZONLegacyURLScheme();
    NSString *encodedScheme = [scheme stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: @"";
    NSString *urlString = [NSString stringWithFormat:@"%@udid.php?id=%@&openurl=%@&daihao=%@",
                           ZONLegacyUDIDBaseURLString,
                           userID ?: @"",
                           encodedScheme,
                           ZONLegacyUDIDAppCode];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        ZONLegacyFinishFallback();
        return;
    }
    ZONLegacyMarkPending();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            gZonoeLegacyWebFallbackInFlight = NO;
            if (!success) {
                ZONLegacyClearPendingMarker();
                NSLog(@"[zonoemenu][WARN][udid] unable to open legacy profile installer");
                return;
            }

            // Preserve the proven legacy lifecycle: once the profile installer/web
            // flow has been opened successfully, terminate the injected host process.
            // The next App launch reuses the persistent SJUSERID, fetches the server
            // generated udid<SJUSERID>.txt, stores DZUDID, and resumes authorization.
            NSLog(@"[zonoemenu][INFO][udid] legacy profile installer opened; terminating host for clean relaunch");
            exit(0);
        }];
    });
}

static void ZONLegacyFetchUDIDForUserID(NSString *userID)
{
    NSString *requestString = [NSString stringWithFormat:@"%@udid%@.txt", ZONLegacyUDIDBaseURLString, userID];
    NSURL *url = [NSURL URLWithString:requestString];
    if (!url) {
        ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
        ZONLegacyFinishFallback();
        return;
    }

    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[zonoemenu][WARN][udid] standalone web fallback request failed: %@", error.localizedDescription);
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
            ZONLegacyFinishFallback();
            return;
        }

        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        if (http.statusCode == 404) {
            NSLog(@"[zonoemenu][INFO][udid] no server UDID yet; opening profile installer");
            ZONLegacyOpenProfileInstaller(userID);
            return;
        }
        if (http.statusCode != 200 || !data.length) {
            NSLog(@"[zonoemenu][WARN][udid] standalone web fallback returned HTTP %ld", (long)http.statusCode);
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
            ZONLegacyFinishFallback();
            return;
        }

        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
        NSString *trimmed = [body stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSArray<NSString *> *parts = [trimmed componentsSeparatedByString:@"|"];
        if (parts.count < 1) {
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
            ZONLegacyFinishFallback();
            return;
        }

        NSString *udid = parts[0] ?: @"";
        NSString *blacklistState = parts.count > 2 ? (parts[2] ?: @"") : @"";
        NSString *note = parts.count > 3 ? (parts[3] ?: @"") : @"";
        if ([blacklistState containsString:@"黑名单用户"]) {
            [getKeychain removeKeychainDataForKey:@"DZUDID"];
            ZONLegacyRemoveServerCache(userID);
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
            ZONLegacyFinishFallback();
            ZONLegacyPresentBlockedMessage(note.length ? note : blacklistState);
            return;
        }

        if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
            NSLog(@"[zonoemenu][WARN][udid] standalone web fallback returned invalid UDID");
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
            ZONLegacyFinishFallback();
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:udid forKey:@"zonoeudid"];
        [getKeychain addKeychainData:udid forKey:@"DZUDID"];
        ZONLegacyClearPendingMarker();
        ZONLegacyRemoveServerCache(userID);

        dispatch_async(dispatch_get_main_queue(), ^{
            gZonoeLegacyWebFallbackInFlight = NO;
            NSLog(@"[zonoemenu][INFO][udid] standalone web fallback produced DZUDID; resuming authorization");
            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackStore);
            ZONUDIDBridgeStoreUDID(udid);
        });
    }] resume];
}

void ZONStartLegacyWebUDIDFallback(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gZonoeLegacyWebFallbackInFlight || ZONUDIDBridgeCurrentUDID().length > 0) return;

        NSString *existing = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
        if (ZONUDIDBridgeIsPlausibleUDID(existing)) {
            ZONUDIDBridgeStoreUDID(existing);
            return;
        }

        gZonoeLegacyWebFallbackInFlight = YES;
        ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackBegin);
        NSLog(@"[zonoemenu][INFO][udid] Zonoe unavailable; starting standalone web UDID fallback");

        NSString *userID = [getKeychain getKeychainDataForKey:@"SJUSERID"] ?: @"";
        if (userID.length <= 5) {
            userID = ZONLegacyRandomUserID();
            [getKeychain addKeychainData:userID forKey:@"SJUSERID"];
        }
        ZONLegacyFetchUDIDForUserID(userID);
    });
}

void ZONResumeLegacyWebUDIDFallbackIfNeeded(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZONUDIDBridgeCurrentUDID().length > 0) {
            ZONLegacyClearPendingMarker();
            return;
        }
        if (!ZONLegacyHasFreshPendingMarker()) return;
        if (gZonoeLegacyWebFallbackInFlight) return;

        NSString *userID = [getKeychain getKeychainDataForKey:@"SJUSERID"] ?: @"";
        if (userID.length <= 5) {
            ZONLegacyClearPendingMarker();
            return;
        }

        gZonoeLegacyWebFallbackInFlight = YES;
        NSLog(@"[zonoemenu][INFO][udid] foreground resume: polling legacy web UDID result");

        __block NSInteger attemptsRemaining = 12;
        __block void (^poll)(void) = nil;
        poll = ^{
            if (ZONUDIDBridgeCurrentUDID().length > 0) {
                gZonoeLegacyWebFallbackInFlight = NO;
                poll = nil;
                return;
            }
            if (!ZONLegacyHasFreshPendingMarker() || attemptsRemaining-- <= 0) {
                gZonoeLegacyWebFallbackInFlight = NO;
                NSLog(@"[zonoemenu][WARN][udid] foreground resume: legacy web result still unavailable");
                poll = nil;
                return;
            }

            NSString *requestString = [NSString stringWithFormat:@"%@udid%@.txt", ZONLegacyUDIDBaseURLString, userID];
            NSURL *url = [NSURL URLWithString:requestString];
            if (!url) {
                gZonoeLegacyWebFallbackInFlight = NO;
                poll = nil;
                return;
            }

            [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
                if (!error && http.statusCode == 200 && data.length > 0) {
                    NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
                    NSString *trimmed = [body stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                    NSArray<NSString *> *parts = [trimmed componentsSeparatedByString:@"|"];
                    NSString *udid = parts.count > 0 ? (parts[0] ?: @"") : @"";
                    if (ZONUDIDBridgeIsPlausibleUDID(udid)) {
                        [[NSUserDefaults standardUserDefaults] setObject:udid forKey:@"zonoeudid"];
                        [getKeychain addKeychainData:udid forKey:@"DZUDID"];
                        ZONLegacyClearPendingMarker();
                        ZONLegacyRemoveServerCache(userID);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            gZonoeLegacyWebFallbackInFlight = NO;
                            NSLog(@"[zonoemenu][INFO][udid] foreground resume recovered legacy web UDID");
                            ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackStore);
                            ZONUDIDBridgeStoreUDID(udid);
                            poll = nil;
                        });
                        return;
                    }
                }

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    if (poll) poll();
                });
            }] resume];
        };

        poll();
    });
}
