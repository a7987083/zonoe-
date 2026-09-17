#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path, old, new):
    p = ROOT / path
    text = p.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise SystemExit(f"{path}: expected one marker, found {text.count(old)}")
    p.write_text(text.replace(old, new, 1), encoding="utf-8")


def ensure_absent(path):
    if (ROOT / path).exists():
        raise SystemExit(f"{path}: already exists")


HEADER = r'''#import <Foundation/Foundation.h>
#import <mach/mach_time.h>
#import <os/signpost.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZONLaunchTraceEvent) {
    ZONLaunchTraceMainLoadEnter = 1,
    ZONLaunchTraceAuthResetInstalled,
    ZONLaunchTraceBootstrapEnter,
    ZONLaunchTraceBootstrapPreflightBegin,
    ZONLaunchTraceAppLovinPreflightComplete,
    ZONLaunchTraceUnityPreflightComplete,
    ZONLaunchTraceBootstrapPreflightEnd,
    ZONLaunchTraceBootstrapReadyScheduled,
    ZONLaunchTraceVariantEntryBegin,
    ZONLaunchTraceVariantDebugFloatingRequest,
    ZONLaunchTraceVariantCustomerAuthRequest,
    ZONLaunchTraceAuthorizationEnter,
    ZONLaunchTraceAuthorizationExistingDZUDID,
    ZONLaunchTraceAuthorizationBridgeCache,
    ZONLaunchTraceAuthorizationAwaitUDID,
    ZONLaunchTraceAuthorizationUDIDCallback,
    ZONLaunchTraceAuthorizationContinue,
    ZONLaunchTraceLegacyFallbackBegin,
    ZONLaunchTraceLegacyFallbackInvalid,
    ZONLaunchTraceLegacyFallbackStore,
    ZONLaunchTraceModuleLoadBegin,
    ZONLaunchTraceModuleScanBegin,
    ZONLaunchTraceModuleScanEnd,
    ZONLaunchTraceModuleLoadEnd,
    ZONLaunchTraceBootstrapReady,
    ZONLaunchTraceFloatingEntryRequest,
    ZONLaunchTraceFloatingEntryAttached,
    ZONLaunchTraceMenuPresentationRequest,
    ZONLaunchTraceMenuPresentationDispatched,
};

static inline const char *ZONLaunchTraceEventName(ZONLaunchTraceEvent event)
{
    switch (event) {
        case ZONLaunchTraceMainLoadEnter: return "main.load.enter";
        case ZONLaunchTraceAuthResetInstalled: return "auth.reset.installed";
        case ZONLaunchTraceBootstrapEnter: return "bootstrap.enter";
        case ZONLaunchTraceBootstrapPreflightBegin: return "bootstrap.preflight.begin";
        case ZONLaunchTraceAppLovinPreflightComplete: return "preflight.applovin.complete";
        case ZONLaunchTraceUnityPreflightComplete: return "preflight.unity.complete";
        case ZONLaunchTraceBootstrapPreflightEnd: return "bootstrap.preflight.end";
        case ZONLaunchTraceBootstrapReadyScheduled: return "bootstrap.ready.scheduled";
        case ZONLaunchTraceVariantEntryBegin: return "variant.entry.begin";
        case ZONLaunchTraceVariantDebugFloatingRequest: return "variant.debug.floating.request";
        case ZONLaunchTraceVariantCustomerAuthRequest: return "variant.customer.auth.request";
        case ZONLaunchTraceAuthorizationEnter: return "authorization.enter";
        case ZONLaunchTraceAuthorizationExistingDZUDID: return "authorization.existing_dzudid";
        case ZONLaunchTraceAuthorizationBridgeCache: return "authorization.bridge_cache";
        case ZONLaunchTraceAuthorizationAwaitUDID: return "authorization.await_udid";
        case ZONLaunchTraceAuthorizationUDIDCallback: return "authorization.udid_callback";
        case ZONLaunchTraceAuthorizationContinue: return "authorization.continue";
        case ZONLaunchTraceLegacyFallbackBegin: return "legacy_fallback.begin";
        case ZONLaunchTraceLegacyFallbackInvalid: return "legacy_fallback.invalid";
        case ZONLaunchTraceLegacyFallbackStore: return "legacy_fallback.store";
        case ZONLaunchTraceModuleLoadBegin: return "module_load.begin";
        case ZONLaunchTraceModuleScanBegin: return "module_scan.begin";
        case ZONLaunchTraceModuleScanEnd: return "module_scan.end";
        case ZONLaunchTraceModuleLoadEnd: return "module_load.end";
        case ZONLaunchTraceBootstrapReady: return "bootstrap.ready";
        case ZONLaunchTraceFloatingEntryRequest: return "floating_entry.request";
        case ZONLaunchTraceFloatingEntryAttached: return "floating_entry.attached";
        case ZONLaunchTraceMenuPresentationRequest: return "menu.presentation.request";
        case ZONLaunchTraceMenuPresentationDispatched: return "menu.presentation.dispatched";
    }
    return "unknown";
}

static inline double ZONLaunchTraceUptimeMilliseconds(void)
{
    mach_timebase_info_data_t info = {0};
    mach_timebase_info(&info);
    uint64_t ticks = mach_absolute_time();
    return ((double)ticks * (double)info.numer / (double)info.denom) / 1000000.0;
}

static inline os_log_t ZONLaunchTraceLog(void)
{
    static os_log_t log;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        log = os_log_create("com.zonoemenu.launch", "startup");
    });
    return log;
}

static inline void ZONLaunchTraceRecord(ZONLaunchTraceEvent event)
{
    const char *name = ZONLaunchTraceEventName(event);
    double uptimeMS = ZONLaunchTraceUptimeMilliseconds();
    NSLog(@"[zonoemenu][TRACE][launch] event=%s uptime_ms=%.3f main=%d",
          name,
          uptimeMS,
          NSThread.isMainThread ? 1 : 0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    os_log_t log = ZONLaunchTraceLog();
    switch (event) {
        case ZONLaunchTraceMainLoadEnter: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "main.load.enter"); break;
        case ZONLaunchTraceAuthResetInstalled: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "auth.reset.installed"); break;
        case ZONLaunchTraceBootstrapEnter: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "bootstrap.enter"); break;
        case ZONLaunchTraceBootstrapPreflightBegin: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "bootstrap.preflight.begin"); break;
        case ZONLaunchTraceAppLovinPreflightComplete: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "preflight.applovin.complete"); break;
        case ZONLaunchTraceUnityPreflightComplete: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "preflight.unity.complete"); break;
        case ZONLaunchTraceBootstrapPreflightEnd: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "bootstrap.preflight.end"); break;
        case ZONLaunchTraceBootstrapReadyScheduled: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "bootstrap.ready.scheduled"); break;
        case ZONLaunchTraceVariantEntryBegin: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "variant.entry.begin"); break;
        case ZONLaunchTraceVariantDebugFloatingRequest: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "variant.debug.floating.request"); break;
        case ZONLaunchTraceVariantCustomerAuthRequest: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "variant.customer.auth.request"); break;
        case ZONLaunchTraceAuthorizationEnter: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.enter"); break;
        case ZONLaunchTraceAuthorizationExistingDZUDID: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.existing_dzudid"); break;
        case ZONLaunchTraceAuthorizationBridgeCache: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.bridge_cache"); break;
        case ZONLaunchTraceAuthorizationAwaitUDID: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.await_udid"); break;
        case ZONLaunchTraceAuthorizationUDIDCallback: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.udid_callback"); break;
        case ZONLaunchTraceAuthorizationContinue: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "authorization.continue"); break;
        case ZONLaunchTraceLegacyFallbackBegin: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "legacy_fallback.begin"); break;
        case ZONLaunchTraceLegacyFallbackInvalid: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "legacy_fallback.invalid"); break;
        case ZONLaunchTraceLegacyFallbackStore: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "legacy_fallback.store"); break;
        case ZONLaunchTraceModuleLoadBegin: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "module_load.begin"); break;
        case ZONLaunchTraceModuleScanBegin: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "module_scan.begin"); break;
        case ZONLaunchTraceModuleScanEnd: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "module_scan.end"); break;
        case ZONLaunchTraceModuleLoadEnd: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "module_load.end"); break;
        case ZONLaunchTraceBootstrapReady: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "bootstrap.ready"); break;
        case ZONLaunchTraceFloatingEntryRequest: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "floating_entry.request"); break;
        case ZONLaunchTraceFloatingEntryAttached: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "floating_entry.attached"); break;
        case ZONLaunchTraceMenuPresentationRequest: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "menu.presentation.request"); break;
        case ZONLaunchTraceMenuPresentationDispatched: os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "menu.presentation.dispatched"); break;
    }
#pragma clang diagnostic pop
}

NS_ASSUME_NONNULL_END
'''


def main():
    ensure_absent("testmod/ZONServices/ZONLaunchTrace.h")
    (ROOT / "testmod/ZONServices/ZONLaunchTrace.h").write_text(HEADER, encoding="utf-8")

    (ROOT / "VERSION").write_text("v1_p46\n", encoding="utf-8")

    replace_once("testmod/Bsphp/main.m",
                 '#import "../ZONServices/ZONAuthorizationCoordinator.h"\n',
                 '#import "../ZONServices/ZONAuthorizationCoordinator.h"\n#import "../ZONServices/ZONLaunchTrace.h"\n')
    replace_once("testmod/Bsphp/main.m",
                 '+(void)load\n{\n    ZONInstallAuthorizationResetExtension();\n\n    ZONBootstrapStart(^{\n',
                 '+(void)load\n{\n    ZONLaunchTraceRecord(ZONLaunchTraceMainLoadEnter);\n    ZONInstallAuthorizationResetExtension();\n    ZONLaunchTraceRecord(ZONLaunchTraceAuthResetInstalled);\n\n    ZONBootstrapStart(^{\n        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapPreflightBegin);\n')
    replace_once("testmod/Bsphp/main.m",
                 '        [self tryLoadAppLovinSDK];\n        [self UnityFramework];\n    }, ^{\n#if ZON_BUILD_VARIANT_DEBUG\n',
                 '        [self tryLoadAppLovinSDK];\n        ZONLaunchTraceRecord(ZONLaunchTraceAppLovinPreflightComplete);\n        [self UnityFramework];\n        ZONLaunchTraceRecord(ZONLaunchTraceUnityPreflightComplete);\n    }, ^{\n        ZONLaunchTraceRecord(ZONLaunchTraceVariantEntryBegin);\n#if ZON_BUILD_VARIANT_DEBUG\n')
    replace_once("testmod/Bsphp/main.m",
                 '        [NSObject 显示图标];\n#else\n',
                 '        ZONLaunchTraceRecord(ZONLaunchTraceVariantDebugFloatingRequest);\n        [NSObject 显示图标];\n#else\n')
    replace_once("testmod/Bsphp/main.m",
                 '        [statusHost showProgressNotificationAndAnimate];\n        ZONStartCustomerAuthorization();\n',
                 '        [statusHost showProgressNotificationAndAnimate];\n        ZONLaunchTraceRecord(ZONLaunchTraceVariantCustomerAuthRequest);\n        ZONStartCustomerAuthorization();\n')

    replace_once("testmod/ZONBootstrap/ZONBootstrap.m",
                 '#import "../ZONCore/ZONModuleLoader.h"\n',
                 '#import "../ZONCore/ZONModuleLoader.h"\n#import "../ZONServices/ZONLaunchTrace.h"\n')
    replace_once("testmod/ZONBootstrap/ZONBootstrap.m",
                 '{\n    static dispatch_once_t onceToken;\n',
                 '{\n    ZONLaunchTraceRecord(ZONLaunchTraceBootstrapEnter);\n    static dispatch_once_t onceToken;\n')
    replace_once("testmod/ZONBootstrap/ZONBootstrap.m",
                 '            preflight();\n            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");\n',
                 '            preflight();\n            ZONLaunchTraceRecord(ZONLaunchTraceBootstrapPreflightEnd);\n            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");\n')
    replace_once("testmod/ZONBootstrap/ZONBootstrap.m",
                 '        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),\n',
                 '        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapReadyScheduled);\n        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),\n')
    replace_once("testmod/ZONBootstrap/ZONBootstrap.m",
                 '            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "module load begin");\n            ZONLoadBundledModules();\n            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "ready");\n',
                 '            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "module load begin");\n            ZONLaunchTraceRecord(ZONLaunchTraceModuleLoadBegin);\n            ZONLoadBundledModules();\n            ZONLaunchTraceRecord(ZONLaunchTraceModuleLoadEnd);\n            ZONLaunchTraceRecord(ZONLaunchTraceBootstrapReady);\n            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "ready");\n')

    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 '#import "ZonoeUDIDAPI.h"\n',
                 '#import "ZonoeUDIDAPI.h"\n#import "ZONLaunchTrace.h"\n')
    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 'void ZONStartCustomerAuthorization(void)\n{\n    WX_NongShiFu123 *auth = [WX_NongShiFu123 new];\n',
                 'void ZONStartCustomerAuthorization(void)\n{\n    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationEnter);\n    WX_NongShiFu123 *auth = [WX_NongShiFu123 new];\n')
    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 '    if (existing.length >= 5) {\n        [auth loada];\n',
                 '    if (existing.length >= 5) {\n        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationExistingDZUDID);\n        [auth loada];\n')
    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 '    if (cached.length >= 5) {\n        ZONContinueCustomerAuthorization(auth, cached, NO);\n',
                 '    if (cached.length >= 5) {\n        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationBridgeCache);\n        ZONContinueCustomerAuthorization(auth, cached, NO);\n')
    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 '    ZonoeSetUDIDCallback(^(NSString *udid) {\n        ZONContinueCustomerAuthorization(auth, udid, YES);\n',
                 '    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationAwaitUDID);\n    ZonoeSetUDIDCallback(^(NSString *udid) {\n        ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationUDIDCallback);\n        ZONContinueCustomerAuthorization(auth, udid, YES);\n')
    replace_once("testmod/ZONServices/ZONAuthorizationCoordinator.m",
                 '    [auth loada];\n}\n\nvoid ZONStartCustomerAuthorization',
                 '    ZONLaunchTraceRecord(ZONLaunchTraceAuthorizationContinue);\n    [auth loada];\n}\n\nvoid ZONStartCustomerAuthorization')

    replace_once("testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m",
                 '#import "../category/getKeychain.h"\n',
                 '#import "../category/getKeychain.h"\n#import "ZONLaunchTrace.h"\n')
    replace_once("testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m",
                 '        gZonoeLegacyWebFallbackInFlight = YES;\n',
                 '        gZonoeLegacyWebFallbackInFlight = YES;\n        ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackBegin);\n')
    replace_once("testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m",
                 '                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {\n',
                 '                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {\n                    ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);\n')
    replace_once("testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m",
                 '                ZONUDIDBridgeStoreUDID(udid);\n',
                 '                ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackStore);\n                ZONUDIDBridgeStoreUDID(udid);\n')

    replace_once("testmod/ZONCore/ZONModuleLoader.m",
                 '#import <dlfcn.h>\n',
                 '#import <dlfcn.h>\n#import "../ZONServices/ZONLaunchTrace.h"\n')
    replace_once("testmod/ZONCore/ZONModuleLoader.m",
                 '    dispatch_once(&onceToken, ^{\n        NSFileManager *fm = [NSFileManager defaultManager];\n',
                 '    dispatch_once(&onceToken, ^{\n        ZONLaunchTraceRecord(ZONLaunchTraceModuleScanBegin);\n        NSFileManager *fm = [NSFileManager defaultManager];\n')
    replace_once("testmod/ZONCore/ZONModuleLoader.m",
                 '        }\n    });\n}\n',
                 '        }\n        ZONLaunchTraceRecord(ZONLaunchTraceModuleScanEnd);\n    });\n}\n')

    replace_once("testmod/视图菜单/NSObject+UI.m",
                 '#import "NSObject+UI.h"\n',
                 '#import "NSObject+UI.h"\n#import "../ZONServices/ZONLaunchTrace.h"\n')
    replace_once("testmod/视图菜单/NSObject+UI.m",
                 '- (void)显示图标\n{\n    dispatch_async(dispatch_get_main_queue(), ^{\n',
                 '- (void)显示图标\n{\n    ZONLaunchTraceRecord(ZONLaunchTraceFloatingEntryRequest);\n    dispatch_async(dispatch_get_main_queue(), ^{\n')
    replace_once("testmod/视图菜单/NSObject+UI.m",
                 '            [parentView addSubview:view];\n',
                 '            [parentView addSubview:view];\n            ZONLaunchTraceRecord(ZONLaunchTraceFloatingEntryAttached);\n')
    replace_once("testmod/视图菜单/NSObject+UI.m",
                 '        [topVC presentViewController:menu animated:NO completion:nil];\n',
                 '        ZONLaunchTraceRecord(ZONLaunchTraceMenuPresentationRequest);\n        [topVC presentViewController:menu animated:NO completion:nil];\n        ZONLaunchTraceRecord(ZONLaunchTraceMenuPresentationDispatched);\n')

    print("p46 launch instrumentation applied")


if __name__ == "__main__":
    main()
