#import "ZONBootstrap.h"
#import "../ZONCore/ZONModuleLoader.h"

void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
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
