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
#import "../ZONServices/ZONAuthorizationCoordinator.h"
#import "../ZONServices/ZONLaunchTrace.h"

#ifndef ZON_BUILD_VARIANT_DEBUG
#define ZON_BUILD_VARIANT_DEBUG 0
#endif

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
    ZONLaunchTraceRecord(ZONLaunchTraceMainLoadEnter);
    ZONInstallAuthorizationResetExtension();
    ZONLaunchTraceRecord(ZONLaunchTraceAuthResetInstalled);

    ZONBootstrapStart(^{
        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapPreflightBegin);
        // Preserve the verified legacy framework preflight timing/order.
        [self tryLoadAppLovinSDK];
        ZONLaunchTraceRecord(ZONLaunchTraceAppLovinPreflightComplete);
        [self UnityFramework];
        ZONLaunchTraceRecord(ZONLaunchTraceUnityPreflightComplete);
    }, ^{
        ZONLaunchTraceRecord(ZONLaunchTraceVariantEntryBegin);
#if ZON_BUILD_VARIANT_DEBUG
        // B_debug: developer entry. No customer authorization and no UDID request.
        ZONLaunchTraceRecord(ZONLaunchTraceVariantDebugFloatingRequest);
        [NSObject 显示图标];
#else
        // A_customer: formal customer entry. UDID is acquired only when loada needs it.
        NSObject *statusHost = [NSObject new];
        [statusHost showProgressNotificationAndAnimate];
        ZONLaunchTraceRecord(ZONLaunchTraceVariantCustomerAuthRequest);
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
