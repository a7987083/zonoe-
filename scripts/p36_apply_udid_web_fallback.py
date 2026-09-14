#!/usr/bin/env python3
from pathlib import Path
import subprocess

BASE_HEAD = "e7830036393fe2d4afa5b18ec370c0494fc0e32c"


def replace_exact(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}: {old[:120]!r}")
    p.write_text(text.replace(old, new, 1))


def main() -> None:
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    if head != BASE_HEAD:
        raise SystemExit(f"expected p35 documentation head {BASE_HEAD}, got {head}")

    bridge = "testmod/ZONServices/ZONUDIDBridge.h"
    old_request_block = '''static inline void ZONUDIDBridgeRequestIfNeeded(void)\n{\n    if (ZONUDIDBridgeCurrentUDID().length > 0) return;\n    if (ZONUDIDBridgeCallbackScheme().length == 0) return;\n\n    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;\n    NSTimeInterval now = NSDate.date.timeIntervalSince1970;\n    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];\n    if (previous > 0 && now - previous < 10.0) return;\n\n    NSString *nonce = ZONUDIDBridgeNewNonce();\n    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);\n    if (!requestURL) return;\n\n    ZONUDIDBridgeStart();\n    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];\n    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];\n\n    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");\n    [UIApplication.sharedApplication openURL:requestURL\n                                     options:@{}\n                           completionHandler:^(BOOL success) {\n        if (!success) {\n            ZONUDIDBridgeClearPendingRequest();\n            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid");\n        }\n    }];\n}\n\nstatic inline void ZONUDIDBridgeForceRefresh(void)\n{\n    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;\n    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];\n    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];\n    ZONUDIDBridgeClearPendingRequest();\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        ZONUDIDBridgeRequestIfNeeded();\n    });\n}\n'''
    new_request_block = '''static inline void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)\n{\n    if (ZONUDIDBridgeCurrentUDID().length > 0) return;\n    if (ZONUDIDBridgeCallbackScheme().length == 0) {\n        NSLog(@"[zonoemenu][WARN][udid] zonoe callback scheme unavailable; using fallback");\n        if (unavailableHandler) unavailableHandler();\n        return;\n    }\n\n    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;\n    NSTimeInterval now = NSDate.date.timeIntervalSince1970;\n    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];\n    if (previous > 0 && now - previous < 10.0) return;\n\n    NSString *nonce = ZONUDIDBridgeNewNonce();\n    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);\n    if (!requestURL) {\n        NSLog(@"[zonoemenu][WARN][udid] unable to construct zonoe://udid request; using fallback");\n        if (unavailableHandler) unavailableHandler();\n        return;\n    }\n\n    ZONUDIDBridgeStart();\n    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];\n    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];\n\n    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");\n    [UIApplication.sharedApplication openURL:requestURL\n                                     options:@{}\n                           completionHandler:^(BOOL success) {\n        if (!success) {\n            ZONUDIDBridgeClearPendingRequest();\n            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid; using web fallback");\n            if (unavailableHandler) unavailableHandler();\n        }\n    }];\n}\n\nstatic inline void ZONUDIDBridgeRequestIfNeeded(void)\n{\n    ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(nil);\n}\n\nstatic inline void ZONUDIDBridgeForceRefreshWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)\n{\n    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;\n    [defaults removeObjectForKey:ZONUDIDBridgeValueKey];\n    [defaults removeObjectForKey:ZONUDIDBridgeSchemeKey];\n    ZONUDIDBridgeClearPendingRequest();\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(unavailableHandler);\n    });\n}\n\nstatic inline void ZONUDIDBridgeForceRefresh(void)\n{\n    ZONUDIDBridgeForceRefreshWithUnavailableHandler(nil);\n}\n'''
    replace_exact(bridge, old_request_block, new_request_block)

    auth_header = "testmod/Bsphp/WX_NongShiFu123.h"
    replace_exact(
        auth_header,
        "- (void)loada;\n- (void)saveUDID;\n",
        "- (void)loada;\n- (void)getUDID:(void (^)(void))completion;\n- (void)saveUDID;\n",
    )

    ui = "testmod/视图菜单/NSObject+UI.m"
    replace_exact(
        ui,
        '#import "../ZONServices/ZonoeUDIDAPI.h"\n',
        '#import "../ZONServices/ZonoeUDIDAPI.h"\n#import "../Bsphp/WX_NongShiFu123.h"\n#import "../Bsphp/getKeychain.h"\n',
    )
    replace_exact(
        ui,
        "static ZonoeUDIDCallback gZonoeUDIDCallback = nil;\nstatic id gZonoeUDIDObserverToken = nil;\n",
        '''static ZonoeUDIDCallback gZonoeUDIDCallback = nil;\nstatic id gZonoeUDIDObserverToken = nil;\nstatic BOOL gZonoeLegacyWebFallbackInFlight = NO;\n\nstatic void ZonoeStartLegacyWebUDIDFallback(void)\n{\n    dispatch_async(dispatch_get_main_queue(), ^{\n        if (gZonoeLegacyWebFallbackInFlight || ZONUDIDBridgeCurrentUDID().length > 0) return;\n\n        gZonoeLegacyWebFallbackInFlight = YES;\n        NSLog(@"[zonoemenu][INFO][udid] Zonoe unavailable; starting legacy web UDID flow");\n\n        WX_NongShiFu123 *legacyAuth = [WX_NongShiFu123 new];\n        [legacyAuth getUDID:^{\n            dispatch_async(dispatch_get_main_queue(), ^{\n                gZonoeLegacyWebFallbackInFlight = NO;\n                NSString *udid = [getKeychain getKeychainDataForKey:@"DZUDID"];\n                if (!ZONUDIDBridgeIsPlausibleUDID(udid)) {\n                    NSLog(@"[zonoemenu][WARN][udid] legacy web flow completed without a valid DZUDID");\n                    return;\n                }\n\n                NSLog(@"[zonoemenu][INFO][udid] legacy web flow produced DZUDID; resuming authorization");\n                ZONUDIDBridgeStoreUDID(udid);\n            });\n        }];\n    });\n}\n''',
    )
    replace_exact(
        ui,
        "        ZONUDIDBridgeRequestIfNeeded();\n",
        "        ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(^{\n            ZonoeStartLegacyWebUDIDFallback();\n        });\n",
    )
    replace_exact(
        ui,
        "        ZONUDIDBridgeForceRefresh();\n",
        "        ZONUDIDBridgeForceRefreshWithUnavailableHandler(^{\n            ZonoeStartLegacyWebUDIDFallback();\n        });\n",
    )

    Path("VERSION").write_text("v1_p36\n")

    # Safety locks: P35 product feature set stays untouched.
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
