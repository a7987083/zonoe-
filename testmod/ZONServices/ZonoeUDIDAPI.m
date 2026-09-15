#import "ZonoeUDIDAPI.h"
#import "ZONUDIDBridge.h"
#import "../Bsphp/WX_NongShiFu123.h"
#import "../category/getKeychain.h"

#pragma mark - Stable public UDID API


static ZonoeUDIDCallback gZonoeUDIDCallback = nil;
static id gZonoeUDIDObserverToken = nil;
static BOOL gZonoeLegacyWebFallbackInFlight = NO;

static void ZonoeStartLegacyWebUDIDFallback(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gZonoeLegacyWebFallbackInFlight || ZONUDIDBridgeCurrentUDID().length > 0) return;

        gZonoeLegacyWebFallbackInFlight = YES;
        NSLog(@"[zonoemenu][INFO][udid] Zonoe unavailable; starting legacy web UDID flow");

        WX_NongShiFu123 *legacyAuth = [WX_NongShiFu123 new];
        [legacyAuth getUDID:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                gZonoeLegacyWebFallbackInFlight = NO;
                NSString *udid = [getKeychain getKeychainDataForKey:@"DZUDID"];
                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
                    NSLog(@"[zonoemenu][WARN][udid] legacy web flow completed without a valid DZUDID");
                    return;
                }

                NSLog(@"[zonoemenu][INFO][udid] legacy web flow produced DZUDID; resuming authorization");
                ZONUDIDBridgeStoreUDID(udid);
            });
        }];
    });
}

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
            ZonoeStartLegacyWebUDIDFallback();
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
            ZonoeStartLegacyWebUDIDFallback();
        });
    });
}
