//static __attribute__((constructor)) void _logosLocalInit(void) {
//    NSLog(@"load1111111111");
//    [[WX_NongShiFu123 alloc] BSPHP];
//}
#import "WX_NongShiFu123.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "daochucd.h"
#import "getKeychain.h"

#import <UIKit/UIKit.h>
#import "JDStatusBarNotification.h"
#import "NSObject+UI.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "../ZONBootstrap/ZONBootstrap.h"
#import "../ZONServices/ZonoeUDIDAPI.h"

#ifndef ZON_BUILD_VARIANT_DEBUG
#define ZON_BUILD_VARIANT_DEBUG 0
#endif

#pragma mark - Authorization reset compatibility

static IMP gZONOriginalDeleteKM = NULL;

static void ZONClearStoredUDIDState(void)
{
    // loada / cloud-save legacy machine-code cache.
    [getKeychain removeKeychainDataForKey:@"DZUDID"];

    // C1/v1_p3+ zonoe bridge cache. If these are left behind, A_customer would
    // simply restore DZUDID from the bridge cache on the next launch and would
    // not exercise the first-activation UDID flow again.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:@"zonoe.udid.bridge.value"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.scheme"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.requestTimestamp"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.requestNonce"];
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

static void ZONInstallAuthorizationResetExtension(void)
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

    [auth loada];
}

static void ZONStartCustomerAuthorization(void)
{
    WX_NongShiFu123 *auth = [WX_NongShiFu123 new];

    // Existing valid customer keychain data wins. This avoids unnecessary zonoe jumps
    // for already activated customers.
    NSString *existing = [getKeychain getKeychainDataForKey:@"DZUDID"];
    if (existing.length >= 5) {
        [auth loada];
        return;
    }

    // Reuse the C1/v1_p3 bridge cache when available.
    NSString *cached = ZonoeCurrentUDID();
    if (cached.length >= 5) {
        ZONContinueCustomerAuthorization(auth, cached, NO);
        return;
    }

    ZONShowCustomerStatus(@"正在获取设备 UDID...",
                          JDStatusBarNotificationIncludedStyleLight,
                          5.0);

    // First customer activation: authorization is the only owner of UDID acquisition.
    // No menu/icon action requests UDID anymore.
    ZonoeSetUDIDCallback(^(NSString *udid) {
        ZONContinueCustomerAuthorization(auth, udid, YES);
    });
    ZonoeRequestUDIDIfNeeded();
}
 
@implementation NSObject (mian)

#pragma mark - 强制加载 AppLovin SDK（如果存在）

// 核心通用加载逻辑
+ (void)loadDynamicFrameworkNamed:(NSString *)frameworkName {
    NSString *frameworkPath = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 1. 优先尝试 PrivateFrameworks 路径
    NSString *privatePath = [[NSBundle mainBundle] privateFrameworksPath];
    if (privatePath) {
        frameworkPath = [privatePath stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@.framework/%@", frameworkName, frameworkName]];
    }

    // 2. 兜底尝试标准 Frameworks 路径
    if (!frameworkPath || ![fileManager fileExistsAtPath:frameworkPath]) {
        frameworkPath = [[[NSBundle mainBundle] bundlePath]
                         stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"Frameworks/%@.framework/%@", frameworkName, frameworkName]];
    }

    // 3. 最终检查文件是否存在
    if (![fileManager fileExistsAtPath:frameworkPath]) {
        NSLog(@"[%@] SDK not found at path: %@", frameworkName, frameworkPath);
        return;
    }

    // 4. 执行 dlopen
    void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"[%@] dlopen failed: %s", frameworkName, dlerror());
        return;
    }

    // 5. 执行后续初始化逻辑
    if ([NSObject respondsToSelector:@selector(sdkload)]) {
        [NSObject sdkload];
    }
    
    NSLog(@"[%@] SDK loaded successfully from: %@", frameworkName, frameworkPath);
}

+ (void)tryLoadAppLovinSDK {
    [self loadDynamicFrameworkNamed:@"AppLovinSDK"];
}

+ (void)UnityFramework {
    [self loadDynamicFrameworkNamed:@"UnityFramework"];
}

+(void)load
{
    ZONInstallAuthorizationResetExtension();

    ZONBootstrapStart(^{
        // Preserve the verified legacy framework preflight timing/order.
        [self tryLoadAppLovinSDK];
        [self UnityFramework];
    }, ^{
#if ZON_BUILD_VARIANT_DEBUG
        // B_debug: developer entry. No customer authorization and no UDID request.
        [NSObject 显示图标];
#else
        // A_customer: formal customer entry. UDID is acquired only when loada needs it.
        NSObject *statusHost = [NSObject new];
        [statusHost showProgressNotificationAndAnimate];
        ZONStartCustomerAuthorization();
#endif
    });
}

- (void)showProgressNotificationAndAnimate {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"🎉加载插件中...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];
    });
}

- (void)sdkload{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"🎉检测完成...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];
    });
}

@end
