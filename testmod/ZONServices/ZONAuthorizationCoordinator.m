#import "ZONAuthorizationCoordinator.h"
#import "../Bsphp/WX_NongShiFu123.h"
#import "../category/getKeychain.h"
#import "JDStatusBarNotification.h"
#import "ZonoeUDIDAPI.h"
#import "ZONLaunchTrace.h"
#import <objc/runtime.h>

#pragma mark - Authorization state constants

static NSString * const kZONAuthorizationUDIDKey = @"DZUDID";
static NSString * const kZONBridgeUDIDValueKey = @"zonoe.udid.bridge.value";
static NSString * const kZONBridgeUDIDSchemeKey = @"zonoe.udid.bridge.scheme";
static NSString * const kZONBridgeRequestTimestampKey = @"zonoe.udid.bridge.requestTimestamp";
static NSString * const kZONBridgeRequestNonceKey = @"zonoe.udid.bridge.requestNonce";

static BOOL ZONAuthorizationUDIDIsValid(NSString * _Nullable udid)
{
    return udid.length >= 5;
}

static NSString * _Nullable ZONReadStoredAuthorizationUDID(void)
{
    return [getKeychain getKeychainDataForKey:kZONAuthorizationUDIDKey];
}

static NSString * _Nullable ZONPersistAndVerifyAuthorizationUDID(NSString *udid)
{
    [getKeychain addKeychainData:udid forKey:kZONAuthorizationUDIDKey];
    NSString *verified = ZONReadStoredAuthorizationUDID();
    return (ZONAuthorizationUDIDIsValid(verified) && [verified isEqualToString:udid]) ? verified : nil;
}

#pragma mark - Authorization reset compatibility

static IMP gZONOriginalDeleteKM = NULL;

static void ZONClearStoredUDIDState(void)
{
    // loada / cloud-save legacy machine-code cache.
    [getKeychain removeKeychainDataForKey:kZONAuthorizationUDIDKey];

    // C1/v1_p3+ zonoe bridge cache. If these are left behind, A_customer would
    // simply restore DZUDID from the bridge cache on the next launch and would
    // not exercise the first-activation UDID flow again.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *bridgeKeys = @[
        kZONBridgeUDIDValueKey,
        kZONBridgeUDIDSchemeKey,
        kZONBridgeRequestTimestampKey,
        kZONBridgeRequestNonceKey,
    ];
    for (NSString *key in bridgeKeys) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];

    NSLog(@"[zonoemenu][INFO][auth] authorization reset also cleared UDID state");
}

static void ZONDeleteKMAndUDID(id self, SEL _cmd)
{
    if (gZONOriginalDeleteKM) {
        ((void (*)(id, SEL))gZONOriginalDeleteKM)(self, _cmd);
    }
    ZONClearStoredUDIDState();
}

void ZONInstallAuthorizationResetExtension(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class authClass = NSClassFromString(@"WX_NongShiFu123");
        Method method = class_getInstanceMethod(authClass, @selector(deletekm));
        if (!method) {
            NSLog(@"[zonoemenu][WARN][auth] deletekm not found; UDID reset extension unavailable");
            return;
        }

        gZONOriginalDeleteKM = method_setImplementation(method, (IMP)ZONDeleteKMAndUDID);
        NSLog(@"[zonoemenu][INFO][auth] authorization reset now includes UDID state");
    });
}

#pragma mark - Customer authorization flow

static void ZONShowCustomerStatus(NSString *text,
                                  JDStatusBarNotificationIncludedStyle style,
                                  NSTimeInterval delay)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];
        [presenter presentWithText:text dismissAfterDelay:delay includedStyle:style];
    });
}

static void ZONContinueCustomerAuthorization(WX_NongShiFu123 *auth, NSString *udid, BOOL newlyFetched)
{
    if (!ZONAuthorizationUDIDIsValid(udid)) return;

    NSString *verified = ZONPersistAndVerifyAuthorizationUDID(udid);
    if (!verified) {
        ZONShowCustomerStatus(@"UDID 写入失败\n请重新启动后再试",
                              JDStatusBarNotificationIncludedStyleError,
                              5.0);
        return;
    }

    if (newlyFetched) {
        NSString *status = [NSString stringWithFormat:
                            @"UDID 获取成功\n%@\n已写入 DZUDID\n正在继续授权",
                            verified];
        ZONShowCustomerStatus(status,
                              JDStatusBarNotificationIncludedStyleSuccess,
                              5.0);
    }

    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationContinue);
    [auth loada];
}

void ZONStartCustomerAuthorization(void)
{
    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationEnter);
    WX_NongShiFu123 *auth = [WX_NongShiFu123 new];

    // Existing valid customer keychain data wins. This avoids unnecessary zonoe jumps
    // for already activated customers.
    NSString *existing = ZONReadStoredAuthorizationUDID();
    if (ZONAuthorizationUDIDIsValid(existing)) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationExistingDZUDID);
        [auth loada];
        return;
    }

    // Reuse the C1/v1_p3 bridge cache when available.
    NSString *cached = ZonoeCurrentUDID();
    if (ZONAuthorizationUDIDIsValid(cached)) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationBridgeCache);
        ZONContinueCustomerAuthorization(auth, cached, NO);
        return;
    }

    ZONShowCustomerStatus(@"正在获取设备 UDID...",
                          JDStatusBarNotificationIncludedStyleLight,
                          5.0);

    // First customer activation: authorization is the only owner of UDID acquisition.
    // No menu/icon action requests UDID anymore.
    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationAwaitUDID);
    ZonoeSetUDIDCallback(^(NSString *udid) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationUDIDCallback);
        ZONContinueCustomerAuthorization(auth, udid, YES);
    });
    ZonoeRequestUDIDIfNeeded();
}
