#import <Foundation/Foundation.h>
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
