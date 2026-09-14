#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

BASE_HEAD = "e7830036393fe2d4afa5b18ec370c0494fc0e32c"


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if text.count(old) != 1:
        raise SystemExit(f"{path}: expected exactly one match for {old[:100]!r}")
    p.write_text(text.replace(old, new, 1))


def regex_once(path: str, pattern: str, replacement: str) -> None:
    p = Path(path)
    text = p.read_text()
    text2, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"{path}: expected one regex match, found {count}")
    p.write_text(text2)


def main() -> None:
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    if head != BASE_HEAD:
        raise SystemExit(f"expected p35 documentation head {BASE_HEAD}, got {head}")

    bridge = "testmod/ZONServices/ZONUDIDBridge.h"
    regex_once(
        bridge,
        r"static inline void ZONUDIDBridgeRequestIfNeeded\(void\)\n\{.*?\n\}\n\nstatic inline void ZONUDIDBridgeForceRefresh\(void\)\n\{.*?\n\}\n",
        '''static inline void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)\n{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;
    if (ZONUDIDBridgeCallbackScheme().length == 0) {
        NSLog(@"[zonoemenu][WARN][udid] zonoe callback scheme unavailable; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    NSString *nonce = ZONUDIDBridgeNewNonce();
    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);
    if (!requestURL) {
        NSLog(@"[zonoemenu][WARN][udid] unable to construct zonoe://udid request; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    ZONUDIDBridgeStart();
    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];
    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];

    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");
    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (!success) {
            ZONUDIDBridgeClearPendingRequest();
            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid; using web fallback");
            if (unavailableHandler) unavailableHandler();
        }
    }];
}

static inline void ZONUDIDBridgeRequestIfNeeded(void)
{
    ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(nil);
}

static inline void ZONUDIDBridgeForceRefreshWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];
    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];
    ZONUDIDBridgeClearPendingRequest();

    dispatch_async(dispatch_get_main_queue(), ^{
        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(unavailableHandler);
    });
}

static inline void ZONUDIDBridgeForceRefresh(void)
{
    ZONUDIDBridgeForceRefreshWithUnavailableHandler(nil);
}
''',
    )

    replace_once(
        "testmod/Bsphp/WX_NongShiFu123.h",
        "- (void)loada;\n- (void)saveUDID;\n",
        "- (void)loada;\n- (void)getUDID:(void (^)(void))completion;\n- (void)saveUDID;\n",
    )

    ui = "testmod/视图菜单/NSObject+UI.m"
    replace_once(
        ui,
        '#import "../ZONServices/ZonoeUDIDAPI.h"\n',
        '#import "../ZONServices/ZonoeUDIDAPI.h"\n#import "../Bsphp/WX_NongShiFu123.h"\n#import "../category/getKeychain.h"\n',
    )
    replace_once(
        ui,
        "static ZonoeUDIDCallback gZonoeUDIDCallback = nil;\nstatic id gZonoeUDIDObserverToken = nil;\n",
        '''static ZonoeUDIDCallback gZonoeUDIDCallback = nil;
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
''',
    )
    replace_once(
        ui,
        "        ZONUDIDBridgeRequestIfNeeded();\n",
        "        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(^{\n            ZonoeStartLegacyWebUDIDFallback();\n        });\n",
    )
    replace_once(
        ui,
        "        ZONUDIDBridgeForceRefresh();\n",
        "        ZONUDIDBridgeForceRefreshWithUnavailableHandler(^{\n            ZonoeStartLegacyWebUDIDFallback();\n        });\n",
    )

    Path("VERSION").write_text("v1_p36\n")

    registry = Path("testmod/ZONCore/ZONFeatureRegistry.m").read_text()
    for identifier in [
        "base.remote-download", "base.cloud-save", "base.local-files",
        "data.backup-save", "data.restore-save", "data.clear-game-data",
        "auth.clear-records", "runtime.iap-noads", "runtime.ad-speed",
    ]:
        if f'@"{identifier}"' not in registry:
            raise SystemExit(f"active p35 feature missing: {identifier}")
    if "runtime.placeholder-203" in registry:
        raise SystemExit("retired placeholder unexpectedly reappeared")

    subprocess.check_call(["git", "diff", "--check"])
    print("p36 UDID web fallback patch: PASS")


if __name__ == "__main__":
    main()
