#import "ZONAuthorizationCoordinator.h"
#import "../Bsphp/WX_NongShiFu123.h"
#import "../category/getKeychain.h"
#import "JDStatusBarNotification.h"
#import "ZonoeUDIDAPI.h"
#import "ZONLaunchTrace.h"

#pragma mark - Authorization reset compatibility

void ZONInstallAuthorizationResetExtension(void)
{
    // Kept as a compatibility startup hook. Reset ownership now lives in
    // ZONAuthorizationResetService and WX_NongShiFu123::deletekm forwards to it.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[zonoemenu][INFO][auth] authorization reset service installed");
    });
}

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
    if (udid.length < 5) return;

    [getKeychain addKeychainData:udid forKey:@"DZUDID"];
    NSString *verified = [getKeychain getKeychainDataForKey:@"DZUDID"];

    if (verified.length < 5 || ![verified isEqualToString:udid]) {
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
    NSString *existing = [getKeychain getKeychainDataForKey:@"DZUDID"];
    if (existing.length >= 5) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationExistingDZUDID);
        [auth loada];
        return;
    }

    // Reuse the C1/v1_p3 bridge cache when available.
    NSString *cached = ZonoeCurrentUDID();
    if (cached.length >= 5) {
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
 
