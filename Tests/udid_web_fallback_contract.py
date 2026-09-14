#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
P35_RUNTIME = "def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9"


def fail(msg: str) -> None:
    print(f"udid-fallback-contract: FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")

bridge = (ROOT / "testmod/ZONServices/ZONUDIDBridge.h").read_text()
ui = (ROOT / "testmod/视图菜单/NSObject+UI.m").read_text()
auth_h = (ROOT / "testmod/Bsphp/WX_NongShiFu123.h").read_text()
auth_mm = (ROOT / "testmod/Bsphp/WX_NongShiFu123.mm").read_text()
main = (ROOT / "testmod/Bsphp/main.m").read_text()
registry = (ROOT / "testmod/ZONCore/ZONFeatureRegistry.m").read_text()

for needle in [
    "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
    "unable to open zonoe://udid; using web fallback",
    "if (unavailableHandler) unavailableHandler();",
    "ZONUDIDBridgeForceRefreshWithUnavailableHandler",
]:
    require(bridge, needle, "bridge unavailable-handler contract")

# Do not regress to canOpenURL preflight: injected hosts may not advertise
# LSApplicationQueriesSchemes even when Zonoe is installed. openURL completion is authoritative.
if "canOpenURL" in bridge or "canOpenURL" in ui:
    fail("fallback must be driven by openURL completion, not canOpenURL preflight")

for needle in [
    '#import "../Bsphp/WX_NongShiFu123.h"',
    '#import "../Bsphp/getKeychain.h"',
    "ZonoeStartLegacyWebUDIDFallback",
    "[legacyAuth getUDID:^{",
    'getKeychainDataForKey:@"DZUDID"',
    "ZONUDIDBridgeStoreUDID(udid);",
    "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(^{",
    "ZONUDIDBridgeForceRefreshWithUnavailableHandler(^{",
]:
    require(ui, needle, "stable API fallback wiring")

require(auth_h, "- (void)getUDID:(void (^)(void))completion;", "legacy web API declaration")
for needle in [
    'getKeychainDataForKey:@"SJUSERID"',
    'UDID_HOST,suijiid',
    'statusCode] == 404',
    'udid.php?id=%@&openurl=%@&daihao=%@',
    'getKeychain addKeychainData:设备特征码 forKey:@"DZUDID"',
]:
    require(auth_mm, needle, "legacy web flow marker")

# P36 must not alter the legacy web implementation body or customer startup owner.
def git_show(path: str) -> str:
    return subprocess.check_output(["git", "show", f"{P35_RUNTIME}:{path}"], text=True)

if git_show("testmod/Bsphp/WX_NongShiFu123.mm") != auth_mm:
    fail("legacy getUDID implementation changed; p36 should only wire fallback into it")
if git_show("testmod/Bsphp/main.m") != main:
    fail("customer startup/authorization owner changed unexpectedly")

for identifier in [
    "base.remote-download", "base.cloud-save", "base.local-files",
    "data.backup-save", "data.restore-save", "data.clear-game-data",
    "auth.clear-records", "runtime.iap-noads", "runtime.ad-speed",
]:
    require(registry, f'@"{identifier}"', "retained p35 feature")
if "runtime.placeholder-203" in registry:
    fail("retired placeholder 203 reappeared")

if (ROOT / "VERSION").read_text().strip() != "v1_p36":
    fail("VERSION must be v1_p36")

print("udid-fallback-contract: PASS")
