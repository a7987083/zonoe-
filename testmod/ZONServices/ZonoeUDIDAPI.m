#import "ZonoeUDIDAPI.h"
#import "ZONUDIDBridge.h"
#import "ZONLegacyUDIDFallbackAdapter.h"

#pragma mark - Stable public UDID API


static ZonoeUDIDCallback gZonoeUDIDCallback = nil;
static id gZonoeUDIDObserverToken = nil;
static void ZonoeDeliverUDIDIfNeeded(NSString *udid)
{
    if (!ZONUDIDBridgeIsPlausibleUDID(udid)) return;
    if (!gZonoeUDIDCallback) return;

    ZonoeUDIDCallback callback = [gZonoeUDIDCallback copy];
    gZonoeUDIDCallback = nil;
    callback(udid);
}

static void ZonoeEnsureUDIDObserver(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gZonoeUDIDObserverToken =
            [NSNotificationCenter.defaultCenter
                addObserverForName:ZONUDIDBridgeDidUpdateNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *note) {
            NSString *udid = [note.object isKindOfClass:NSString.class] ? note.object : nil;
            ZonoeDeliverUDIDIfNeeded(udid);
        }];
    });
}

NSString * _Nullable ZonoeCurrentUDID(void)
{
    return ZONUDIDBridgeCurrentUDID();
}

void ZonoeSetUDIDCallback(ZonoeUDIDCallback callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ZonoeEnsureUDIDObserver();
        gZonoeUDIDCallback = [callback copy];

        NSString *current = ZONUDIDBridgeCurrentUDID();
        if (current.length > 0) {
            ZonoeDeliverUDIDIfNeeded(current);
        }
    });
}

void ZonoeRequestUDIDIfNeeded(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ZonoeEnsureUDIDObserver();

        NSString *current = ZONUDIDBridgeCurrentUDID();
        if (current.length > 0) {
            ZonoeDeliverUDIDIfNeeded(current);
            return;
        }

        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(^{
            ZONStartLegacyWebUDIDFallback();
        });
    });
}

void ZonoeRequestUDID(void)
{
    ZonoeRequestUDIDIfNeeded();
}

void ZonoeForceRefreshUDID(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ZonoeEnsureUDIDObserver();
        ZONUDIDBridgeForceRefreshWithUnavailableHandler(^{
            ZONStartLegacyWebUDIDFallback();
        });
    });
}
