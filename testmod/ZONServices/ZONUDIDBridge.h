#ifndef ZONUDIDBridge_h
#define ZONUDIDBridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const ZONUDIDBridgeValueKey = @"zonoe.udid.bridge.value";
static NSString * const ZONUDIDBridgeSchemeKey = @"zonoe.udid.bridge.scheme";
static NSString * const ZONUDIDBridgeRequestTimestampKey = @"zonoe.udid.bridge.requestTimestamp";
static NSString * const ZONUDIDBridgeRequestNonceKey = @"zonoe.udid.bridge.requestNonce";
static NSString * const ZONUDIDBridgeDidUpdateNotification = @"zonoe.udid.bridge.didUpdate";
static const uint16_t ZONUDIDBridgePort = 14302;

#pragma mark - Callback metadata

static inline NSString * _Nullable ZONUDIDBridgeCallbackScheme(void)
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

static inline NSString *ZONUDIDBridgeCallbackHost(void)
{
    id value = NSBundle.mainBundle.infoDictionary[@"ZonoeUDIDCallbackHost"];
    if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    return @"udid-callback";
}

static inline NSURL * _Nullable ZONUDIDBridgeCallbackURL(void)
{
    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0) return nil;

    NSURLComponents *components = [NSURLComponents new];
    components.scheme = scheme;
    components.host = ZONUDIDBridgeCallbackHost();
    return components.URL;
}

#pragma mark - Nonce

static inline BOOL ZONUDIDBridgeIsPlausibleNonce(NSString *value)
{
    if (![value isKindOfClass:NSString.class]) return NO;
    if (value.length < 16 || value.length > 128) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"];
    return [value rangeOfCharacterFromSet:allowed.invertedSet].location == NSNotFound;
}

static inline NSString *ZONUDIDBridgeNewNonce(void)
{
    return [[[NSUUID UUID].UUIDString lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

static inline NSURL * _Nullable ZONUDIDBridgeRequestURLForNonce(NSString *nonce)
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

static inline NSURL * _Nullable ZONUDIDBridgeRequestURL(void)
{
    NSString *nonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
    if (!ZONUDIDBridgeIsPlausibleNonce(nonce)) nonce = ZONUDIDBridgeNewNonce();
    return ZONUDIDBridgeRequestURLForNonce(nonce);
}

#pragma mark - Stored value

static inline BOOL ZONUDIDBridgeIsPlausibleUDID(NSString *value)
{
    if (![value isKindOfClass:NSString.class]) return NO;
    NSString *trimmed = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length < 8 || trimmed.length > 128) return NO;

    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"];
    return [trimmed rangeOfCharacterFromSet:allowed.invertedSet].location == NSNotFound;
}

static inline NSString * _Nullable ZONUDIDBridgeCurrentUDID(void)
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

static inline void ZONUDIDBridgeClearPendingRequest(void)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeRequestTimestampKey];
    [defaults removeObjectForKey:ZONUDIDBridgeRequestNonceKey];
}

static inline void ZONUDIDBridgeStoreUDID(NSString *udid)
{
    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0 || !ZONUDIDBridgeIsPlausibleUDID(udid)) return;

    NSString *trimmed = [udid stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:trimmed forKey:ZONUDIDBridgeValueKey];
    [defaults setObject:scheme forKey:ZONUDIDBridgeSchemeKey];
    ZONUDIDBridgeClearPendingRequest();

    [[NSNotificationCenter defaultCenter] postNotificationName:ZONUDIDBridgeDidUpdateNotification
                                                        object:trimmed];
    NSLog(@"[zonoemenu][INFO][udid] bridge result received (%lu chars)", (unsigned long)trimmed.length);
}

#pragma mark - Callback URL compatibility parser

static inline BOOL ZONUDIDBridgeHandleURL(NSURL *url)
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

static inline NSDictionary * _Nullable ZONUDIDBridgeFetchLocalResultOnce(NSString *nonce)
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

static inline void ZONUDIDBridgeFetchPendingResult(void)
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

static inline void ZONUDIDBridgeStart(void)
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

static inline void ZONUDIDBridgeRequestIfNeeded(void)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;
    if (ZONUDIDBridgeCallbackScheme().length == 0) return;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    NSString *nonce = ZONUDIDBridgeNewNonce();
    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);
    if (!requestURL) return;

    ZONUDIDBridgeStart();
    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];
    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];

    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");
    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (!success) {
            ZONUDIDBridgeClearPendingRequest();
            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid");
        }
    }];
}

static inline void ZONUDIDBridgeForceRefresh(void)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];
    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];
    ZONUDIDBridgeClearPendingRequest();

    dispatch_async(dispatch_get_main_queue(), ^{
        ZONUDIDBridgeRequestIfNeeded();
    });
}

NS_ASSUME_NONNULL_END

#endif /* ZONUDIDBridge_h */
