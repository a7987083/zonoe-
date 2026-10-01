#import "ZONAuthorizationCoordinator.h"
#import "../category/getKeychain.h"
#import "../ZONAuthV2/ZONAuthV2Flow.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "JDStatusBarNotification.h"
#import "ZonoeUDIDAPI.h"
#import "ZONLaunchTrace.h"
#import "JHPP.h"

#pragma mark - Authorization reset compatibility

void ZONInstallAuthorizationResetExtension(void)
{
    // Compatibility startup hook retained for the authorization reset service.
    // The primary P79 authorization engine is ZONAuthV2Flow.
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

static void ZONContinueCustomerAuthorization(NSString *udid, BOOL newlyFetched)
{
    if (udid.length < 5) return;

    // Preserve the P76 UDID acquisition/storage behavior because other stable features
    // (for example current cloud-save entitlement) still consume DZUDID in phase 1.
    [getKeychain addKeychainData:udid forKey:@"DZUDID"];
    NSString *verified = [getKeychain getKeychainDataForKey:@"DZUDID"];

    if (verified.length < 5 || ![verified isEqualToString:udid]) {
        ZONShowCustomerStatus(@"UDID 写入失败\n请重新启动后再试",
                              JDStatusBarNotificationIncludedStyleError,
                              5.0);
        return;
    }

    // P79.8b persistence cleanup starts only after DZUDID is durably confirmed.
    // This leaves menu/runtime preferences untouched while removing obsolete AuthV2,
    // legacy authorization, and completed UDID-bridge residue.
    [ZONAuthV2Storage purgeLegacyPersistentState];
    NSLog(@"[zonoemenu][auth-v2][P79.8B_PERSISTENCE] DZUDID confirmed; legacy auth/defaults residue purged");

    if (newlyFetched) {
        NSString *status = [NSString stringWithFormat:
                            @"UDID 获取成功\n%@\n已写入 DZUDID\n正在继续授权",
                            verified];
        ZONShowCustomerStatus(status,
                              JDStatusBarNotificationIncludedStyleSuccess,
                              5.0);
    }

    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationContinue);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *host = [JHPP currentViewController];
        [[ZONAuthV2Flow sharedFlow] startFromViewController:host udid:verified];
    });
}

void ZONStartCustomerAuthorization(void)
{
    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationEnter);

    // Existing valid P76 DZUDID still wins. Only the authorization engine changes.
    NSString *existing = [getKeychain getKeychainDataForKey:@"DZUDID"];
    if (existing.length >= 5) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationExistingDZUDID);
        ZONContinueCustomerAuthorization(existing, NO);
        return;
    }

    // Reuse the existing P76 UDID bridge cache when available.
    NSString *cached = ZonoeCurrentUDID();
    if (cached.length >= 5) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationBridgeCache);
        ZONContinueCustomerAuthorization(cached, NO);
        return;
    }

    ZONShowCustomerStatus(@"正在获取设备 UDID...",
                          JDStatusBarNotificationIncludedStyleLight,
                          5.0);

    // Keep the exact P76 ownership model: authorization is the sole UDID acquisition owner.
    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationAwaitUDID);
    ZonoeSetUDIDCallback(^(NSString *udid) {
        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationUDIDCallback);
        ZONContinueCustomerAuthorization(udid, YES);
    });
    ZonoeRequestUDIDIfNeeded();
}
