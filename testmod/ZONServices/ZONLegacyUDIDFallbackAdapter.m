#import "ZONLegacyUDIDFallbackAdapter.h"
#import "ZONUDIDBridge.h"
#import "../Bsphp/WX_NongShiFu123.h"
#import "../category/getKeychain.h"
#import "ZONLaunchTrace.h"

static BOOL gZonoeLegacyWebFallbackInFlight = NO;

void ZONStartLegacyWebUDIDFallback(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gZonoeLegacyWebFallbackInFlight || ZONUDIDBridgeCurrentUDID().length > 0) return;

        gZonoeLegacyWebFallbackInFlight = YES;
        ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackBegin);
        NSLog(@"[zonoemenu][INFO][udid] Zonoe unavailable; starting legacy web UDID flow");

        WX_NongShiFu123 *legacyAuth = [WX_NongShiFu123 new];
        [legacyAuth getUDID:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                gZonoeLegacyWebFallbackInFlight = NO;
                NSString *udid = [getKeychain getKeychainDataForKey:@"DZUDID"];
                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {
                    ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackInvalid);
                    NSLog(@"[zonoemenu][WARN][udid] legacy web flow completed without a valid DZUDID");
                    return;
                }

                NSLog(@"[zonoemenu][INFO][udid] legacy web flow produced DZUDID; resuming authorization");
                ZONLaunchTraceRecord(ZONLaunchTraceLegacyFallbackStore);
                ZONUDIDBridgeStoreUDID(udid);
            });
        }];
    });
}

