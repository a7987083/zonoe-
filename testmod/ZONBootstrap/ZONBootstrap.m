#import "ZONBootstrap.h"
#import "../ZONCore/ZONModuleLoader.h"
#import "../ZONServices/ZONLaunchTrace.h"
#import <UIKit/UIKit.h>

static BOOL ZONBootstrapHostUIReady(void)
{
    UIApplication *application = UIApplication.sharedApplication;
    if (!application) {
        return NO;
    }

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }
            if (![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            UIWindow *visibleWindow = nil;
            for (UIWindow *window in windowScene.windows) {
                if (window.hidden || window.alpha <= 0.0 || !window.rootViewController) {
                    continue;
                }
                if (window.isKeyWindow) {
                    return YES;
                }
                if (!visibleWindow) {
                    visibleWindow = window;
                }
            }
            if (visibleWindow) {
                return YES;
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *keyWindow = application.keyWindow;
#pragma clang diagnostic pop
    if (keyWindow && !keyWindow.hidden && keyWindow.alpha > 0.0 && keyWindow.rootViewController) {
        return YES;
    }

    for (UIWindow *window in application.windows) {
        if (!window.hidden && window.alpha > 0.0 && window.rootViewController) {
            return YES;
        }
    }

    return NO;
}

static void ZONBootstrapAttemptStart(ZONBootstrapPreflightBlock _Nullable preflight,
                                     ZONBootstrapReadyBlock _Nullable ready)
{
    NSCAssert(NSThread.isMainThread, @"ZON bootstrap readiness gate must run on main thread");

    if (!ZONBootstrapHostUIReady()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)),
                       dispatch_get_main_queue(), ^{
            ZONBootstrapAttemptStart(preflight, ready);
        });
        return;
    }

    ZONCoreLog(ZONLogLevelInfo, "bootstrap", "host UI ready");

    if (preflight) {
        ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight begin");
        preflight();
        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapPreflightEnd);
        ZONCoreLog(ZONLogLevelDebug, "bootstrap", "legacy preflight complete");
    }

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
}

void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
                       ZONBootstrapReadyBlock _Nullable ready)
{
    ZONLaunchTraceRecord(ZONLaunchTraceBootstrapEnter);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZONCoreLog(ZONLogLevelInfo, "bootstrap", "startup deferred until host UI is ready");
        ZONLaunchTraceRecord(ZONLaunchTraceBootstrapReadyScheduled);

        // Keep dylib load/+load lightweight. Match the proven H5GG-style startup
        // shape: return immediately, let UIKit finish bootstrapping, then enter
        // the existing Zonoe preflight/auth/module path only after a host window exists.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            ZONBootstrapAttemptStart(preflight, ready);
        });
    });
}
