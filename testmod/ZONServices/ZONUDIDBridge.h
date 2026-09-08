#ifndef ZONUDIDBridge_h
#define ZONUDIDBridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const ZONUDIDBridgeValueKey = @"zonoe.udid.bridge.value";
static NSString * const ZONUDIDBridgeSchemeKey = @"zonoe.udid.bridge.scheme";
static NSString * const ZONUDIDBridgeRequestTimestampKey = @"zonoe.udid.bridge.requestTimestamp";
static NSString * const ZONUDIDBridgeDidUpdateNotification = @"zonoe.udid.bridge.didUpdate";

static const void *ZONUDIDBridgeModernOpenURLOriginalKey = &ZONUDIDBridgeModernOpenURLOriginalKey;
static const void *ZONUDIDBridgeLegacyOpenURLOriginalKey = &ZONUDIDBridgeLegacyOpenURLOriginalKey;
static const void *ZONUDIDBridgeSceneOpenURLOriginalKey = &ZONUDIDBridgeSceneOpenURLOriginalKey;

#pragma mark - Callback metadata

static inline NSString * _Nullable ZONUDIDBridgeCallbackScheme(void)
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *scheme = [info[@"ZonoeUDIDCallbackScheme"] isKindOfClass:NSString.class]
        ? info[@"ZonoeUDIDCallbackScheme"] : nil;

    if (scheme.length > 0) {
        return scheme;
    }

    // Compatibility fallback: locate the URL type written by zonoe signing.
    NSArray *urlTypes = [info[@"CFBundleURLTypes"] isKindOfClass:NSArray.class]
        ? info[@"CFBundleURLTypes"] : nil;
    for (id object in urlTypes) {
        if (![object isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *type = object;
        if (![[type[@"CFBundleURLName"] description] isEqualToString:@"zonoe.udid.callback"]) continue;
        NSArray *schemes = [type[@"CFBundleURLSchemes"] isKindOfClass:NSArray.class]
            ? type[@"CFBundleURLSchemes"] : nil;
        for (id value in schemes) {
            if ([value isKindOfClass:NSString.class] && [value length] > 0) {
                return value;
            }
        }
    }
    return nil;
}

static inline NSString *ZONUDIDBridgeCallbackHost(void)
{
    id value = NSBundle.mainBundle.infoDictionary[@"ZonoeUDIDCallbackHost"];
    if ([value isKindOfClass:NSString.class] && [value length] > 0) {
        return value;
    }
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

static inline NSURL * _Nullable ZONUDIDBridgeRequestURL(void)
{
    NSURL *callbackURL = ZONUDIDBridgeCallbackURL();
    if (!callbackURL) return nil;

    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"zonoe";
    components.host = @"udid";
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"callback" value:callbackURL.absoluteString]
    ];
    return components.URL;
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

/// Returns the UDID captured for this signed build's unique callback scheme.
/// Example: NSString *udid = ZONUDIDBridgeCurrentUDID();
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

static inline void ZONUDIDBridgeStoreUDID(NSString *udid)
{
    NSString *scheme = ZONUDIDBridgeCallbackScheme();
    if (scheme.length == 0 || !ZONUDIDBridgeIsPlausibleUDID(udid)) return;

    NSString *trimmed = [udid stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:trimmed forKey:ZONUDIDBridgeValueKey];
    [defaults setObject:scheme forKey:ZONUDIDBridgeSchemeKey];
    [defaults removeObjectForKey:ZONUDIDBridgeRequestTimestampKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:ZONUDIDBridgeDidUpdateNotification
                                                        object:trimmed];
    NSLog(@"[zonoemenu][INFO][udid] callback received (%lu chars)", (unsigned long)trimmed.length);
}

#pragma mark - URL parsing

static inline BOOL ZONUDIDBridgeHandleURL(NSURL *url)
{
    if (![url isKindOfClass:NSURL.class]) return NO;

    NSString *expectedScheme = ZONUDIDBridgeCallbackScheme();
    NSString *expectedHost = ZONUDIDBridgeCallbackHost();
    if (expectedScheme.length == 0) return NO;

    if ([url.scheme caseInsensitiveCompare:expectedScheme] != NSOrderedSame) return NO;
    if (expectedHost.length > 0 && [url.host caseInsensitiveCompare:expectedHost] != NSOrderedSame) return NO;

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *udid = nil;
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        if ([item.name isEqualToString:@"udid"] && item.value.length > 0) {
            udid = item.value;
            break;
        }
    }

    if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
        NSLog(@"[zonoemenu][WARN][udid] callback matched but UDID was missing or invalid");
        return YES;
    }

    ZONUDIDBridgeStoreUDID(udid);
    return YES;
}

#pragma mark - Delegate hook helpers

static inline Method _Nullable ZONUDIDBridgeDirectMethod(Class cls, SEL selector)
{
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    Method found = NULL;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == selector) {
            found = methods[i];
            break;
        }
    }
    free(methods);
    return found;
}

static inline NSValue *ZONUDIDBridgeIMPValue(IMP imp)
{
    return [NSValue value:&imp withObjCType:@encode(IMP)];
}

static inline IMP _Nullable ZONUDIDBridgeIMPFromValue(NSValue *value)
{
    if (!value) return NULL;
    IMP imp = NULL;
    [value getValue:&imp];
    return imp;
}

static inline IMP _Nullable ZONUDIDBridgeOriginalIMP(id object, const void *key)
{
    for (Class cls = object_getClass(object); cls != Nil; cls = class_getSuperclass(cls)) {
        NSValue *value = objc_getAssociatedObject((id)cls, key);
        IMP imp = ZONUDIDBridgeIMPFromValue(value);
        if (imp) return imp;
    }
    return NULL;
}

static inline void ZONUDIDBridgeHookMethod(Class cls,
                                           SEL selector,
                                           IMP replacement,
                                           const char *fallbackTypes,
                                           const void *originalKey)
{
    if (!cls) return;

    Method direct = ZONUDIDBridgeDirectMethod(cls, selector);
    if (direct && method_getImplementation(direct) == replacement) return;

    Method resolved = class_getInstanceMethod(cls, selector);
    IMP original = resolved ? method_getImplementation(resolved) : NULL;
    const char *types = resolved ? method_getTypeEncoding(resolved) : fallbackTypes;

    if (direct) {
        method_setImplementation(direct, replacement);
    } else {
        class_addMethod(cls, selector, replacement, types);
    }

    if (original && original != replacement) {
        objc_setAssociatedObject((id)cls,
                                 originalKey,
                                 ZONUDIDBridgeIMPValue(original),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static BOOL ZONUDIDBridgeModernOpenURL(id self,
                                       SEL _cmd,
                                       UIApplication *application,
                                       NSURL *url,
                                       NSDictionary *options)
{
    if (ZONUDIDBridgeHandleURL(url)) return YES;

    IMP original = ZONUDIDBridgeOriginalIMP(self, ZONUDIDBridgeModernOpenURLOriginalKey);
    if (!original) return NO;
    return ((BOOL (*)(id, SEL, UIApplication *, NSURL *, NSDictionary *))original)
        (self, _cmd, application, url, options);
}

static BOOL ZONUDIDBridgeLegacyOpenURL(id self,
                                       SEL _cmd,
                                       UIApplication *application,
                                       NSURL *url,
                                       NSString *sourceApplication,
                                       id annotation)
{
    if (ZONUDIDBridgeHandleURL(url)) return YES;

    IMP original = ZONUDIDBridgeOriginalIMP(self, ZONUDIDBridgeLegacyOpenURLOriginalKey);
    if (!original) return NO;
    return ((BOOL (*)(id, SEL, UIApplication *, NSURL *, NSString *, id))original)
        (self, _cmd, application, url, sourceApplication, annotation);
}

static void ZONUDIDBridgeSceneOpenURLContexts(id self,
                                              SEL _cmd,
                                              id scene,
                                              NSSet *contexts)
{
    NSMutableSet *remaining = [NSMutableSet setWithCapacity:contexts.count];
    for (id context in contexts) {
        NSURL *url = nil;
        @try {
            id value = [context valueForKey:@"URL"];
            if ([value isKindOfClass:NSURL.class]) url = value;
        } @catch (__unused NSException *exception) {}

        if (!url || !ZONUDIDBridgeHandleURL(url)) {
            [remaining addObject:context];
        }
    }

    if (remaining.count == 0) return;

    IMP original = ZONUDIDBridgeOriginalIMP(self, ZONUDIDBridgeSceneOpenURLOriginalKey);
    if (original) {
        ((void (*)(id, SEL, id, NSSet *))original)(self, _cmd, scene, remaining.copy);
    }
}

static inline void ZONUDIDBridgeInstallDelegateHooks(void)
{
    UIApplication *application = UIApplication.sharedApplication;
    id appDelegate = application.delegate;
    if (appDelegate) {
        Class cls = object_getClass(appDelegate);
        ZONUDIDBridgeHookMethod(cls,
                                @selector(application:openURL:options:),
                                (IMP)ZONUDIDBridgeModernOpenURL,
                                "B@:@@@",
                                ZONUDIDBridgeModernOpenURLOriginalKey);
        ZONUDIDBridgeHookMethod(cls,
                                @selector(application:openURL:sourceApplication:annotation:),
                                (IMP)ZONUDIDBridgeLegacyOpenURL,
                                "B@:@@@@",
                                ZONUDIDBridgeLegacyOpenURLOriginalKey);
    }

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            id sceneDelegate = scene.delegate;
            if (!sceneDelegate) continue;
            ZONUDIDBridgeHookMethod(object_getClass(sceneDelegate),
                                    NSSelectorFromString(@"scene:openURLContexts:"),
                                    (IMP)ZONUDIDBridgeSceneOpenURLContexts,
                                    "v@:@@",
                                    ZONUDIDBridgeSceneOpenURLOriginalKey);
        }
    }
}

#pragma mark - Request

static inline void ZONUDIDBridgeRequestIfNeeded(void)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;

    NSURL *requestURL = ZONUDIDBridgeRequestURL();
    if (!requestURL) return; // App was not signed with the zonoe callback option.

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];
    ZONUDIDBridgeInstallDelegateHooks();

    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback");
    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (!success) {
            [NSUserDefaults.standardUserDefaults removeObjectForKey:ZONUDIDBridgeRequestTimestampKey];
            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid");
        }
    }];
}

/// Clears only the bridge cache and requests a fresh value for the current signed callback scheme.
static inline void ZONUDIDBridgeForceRefresh(void)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];
    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];
    [defaults removeObjectForKey:ZONUDIDBridgeRequestTimestampKey];

    dispatch_async(dispatch_get_main_queue(), ^{
        ZONUDIDBridgeRequestIfNeeded();
    });
}

/// Installs URL capture hooks early, then auto-requests once when the host app becomes active.
/// Apps without ZonoeUDIDCallbackScheme are a no-op.
static inline void ZONUDIDBridgeStart(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;

        void (^installAndSchedule)(void) = ^{
            ZONUDIDBridgeInstallDelegateHooks();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(700 * NSEC_PER_MSEC)),
                           dispatch_get_main_queue(), ^{
                if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
                    ZONUDIDBridgeRequestIfNeeded();
                }
            });
        };

        [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                           object:nil
                            queue:NSOperationQueue.mainQueue
                       usingBlock:^(__unused NSNotification *note) {
            installAndSchedule();
        }];

        [center addObserverForName:UIApplicationDidBecomeActiveNotification
                           object:nil
                            queue:NSOperationQueue.mainQueue
                       usingBlock:^(__unused NSNotification *note) {
            installAndSchedule();
        }];

        if (@available(iOS 13.0, *)) {
            [center addObserverForName:UISceneDidActivateNotification
                               object:nil
                                queue:NSOperationQueue.mainQueue
                           usingBlock:^(__unused NSNotification *note) {
                ZONUDIDBridgeInstallDelegateHooks();
            }];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            ZONUDIDBridgeInstallDelegateHooks();
        });
    });
}

NS_ASSUME_NONNULL_END

#endif /* ZONUDIDBridge_h */
