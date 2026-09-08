#ifndef ZONBootstrap_h
#define ZONBootstrap_h

#import <Foundation/Foundation.h>
#import "../视图菜单/NSObject+UI.h"
#import "../ZONCore/ZONModuleLoader.h"
#import "../ZONServices/ZONUDIDBridge.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONBootstrapPreflightBlock)(void);

/// Phase-one production bootstrap.
///
/// The first migration stage intentionally preserves the verified runtime order:
/// 1. Install passive host callback capture for the zonoe UDID bridge.
/// 2. Run legacy framework preflight synchronously at the original +load timing.
/// 3. Hop to the main queue exactly as the legacy bootstrap did.
/// 4. Install the existing floating entry without changing its implementation.
/// 5. Load explicitly bundled ZONModules after the floating entry is installed.
///
/// Feature routing, authorization behavior and module ABI semantics are not changed here.
static inline void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZONCoreLog(ZONLogLevelInfo, "bootstrap", "start");

        // Passive until the host becomes active. Apps not signed with the dedicated
        // zonoe callback metadata are a no-op and never leave the host application.
        ZONUDIDBridgeStart();

        // Preserve the legacy early-load timing for AppLovin/Unity framework probing.
        if (preflight) {
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight begin");
            preflight();
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");
        }

        // Preserve the verified legacy behavior: UI work is deferred to the main queue.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "floating entry begin");
            [NSObject 显示图标];
            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "floating entry ready");

            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "module load begin");
            ZONLoadBundledModules();
            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "ready");
        });
    });
}

NS_ASSUME_NONNULL_END

#endif /* ZONBootstrap_h */
