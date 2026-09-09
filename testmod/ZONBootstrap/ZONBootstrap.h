#ifndef ZONBootstrap_h
#define ZONBootstrap_h

#import <Foundation/Foundation.h>
#import "../视图菜单/NSObject+UI.h"
#import "../ZONCore/ZONModuleLoader.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONBootstrapPreflightBlock)(void);
typedef void (^ZONBootstrapReadyBlock)(void);

/// Production bootstrap shared by customer/debug variants.
///
/// Order is deliberately stable:
/// 1. Run legacy framework preflight synchronously at +load timing.
/// 2. Hop to the main queue for the variant-specific entry path.
/// 3. Load explicitly bundled ZONModules after the entry path has been started.
static inline void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
                                     ZONBootstrapReadyBlock _Nullable ready)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZONCoreLog(ZONLogLevelInfo, "bootstrap", "start");

        if (preflight) {
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight begin");
            preflight();
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (ready) {
                ZONCoreLog(ZONLogLevelDebug, "bootstrap", "variant entry begin");
                ready();
                ZONCoreLog(ZONLogLevelDebug, "bootstrap", "variant entry started");
            }

            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "module load begin");
            ZONLoadBundledModules();
            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "ready");
        });
    });
}

NS_ASSUME_NONNULL_END

#endif /* ZONBootstrap_h */
