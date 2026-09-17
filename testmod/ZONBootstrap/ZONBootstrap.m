#import "ZONBootstrap.h"
#import "../ZONCore/ZONModuleLoader.h"
#import "../ZONServices/ZONLaunchTrace.h"

void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
                       ZONBootstrapReadyBlock _Nullable ready)
{
    ZONLaunchTraceRecord(ZONLaunchTraceBootstrapEnter);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZONCoreLog(ZONLogLevelInfo, "bootstrap", "start");

        if (preflight) {
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight begin");
            preflight();
            ZONLaunchTraceRecord(ZONLaunchTraceBootstrapPreflightEnd);
            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");
        }

        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapReadyScheduled);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (ready) {
                ZONCoreLog(ZONLogLevelDebug, "bootstrap", "variant entry begin");
                ready();
                ZONCoreLog(ZONLogLevelDebug, "bootstrap", "variant entry started");
            }

            ZONCoreLog(ZONLogLevelDebug, "bootstrap", "module load begin");
            ZONLaunchTraceRecord(ZONLaunchTraceModuleLoadBegin);
            ZONLoadBundledModules();
            ZONLaunchTraceRecord(ZONLaunchTraceModuleLoadEnd);
            ZONLaunchTraceRecord(ZONLaunchTraceBootstrapReady);
            ZONCoreLog(ZONLogLevelInfo, "bootstrap", "ready");
        });
    });
}
