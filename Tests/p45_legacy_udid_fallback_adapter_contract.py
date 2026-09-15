#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = "aee574d180da7cc82db54be7ab5aeaa9d072c561"
API = ROOT / "testmod/ZONServices/ZonoeUDIDAPI.m"
ADAPTER_H = ROOT / "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.h"
ADAPTER_M = ROOT / "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"


def fail(msg):
    raise SystemExit(f"p45-contract: {msg}")


def git_show(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], text=True)


def main():
    if (ROOT / "VERSION").read_text().strip() != "v1_p45":
        fail("VERSION != v1_p45")

    api = API.read_text(encoding="utf-8")
    h = ADAPTER_H.read_text(encoding="utf-8")
    m = ADAPTER_M.read_text(encoding="utf-8")
    pbx = PBX.read_text(encoding="utf-8")

    if '#import "ZONLegacyUDIDFallbackAdapter.h"' not in api:
        fail("API does not import adapter")
    for forbidden in ["WX_NongShiFu123", "getKeychain", "gZonoeLegacyWebFallbackInFlight", "ZonoeStartLegacyWebUDIDFallback"]:
        if forbidden in api:
            fail(f"legacy fallback detail remains in API: {forbidden}")
    if api.count("ZONStartLegacyWebUDIDFallback();") != 2:
        fail("expected exactly two fallback call sites")

    if 'void ZONStartLegacyWebUDIDFallback(void)' not in h:
        fail("adapter declaration missing")
    required = [
        "static BOOL gZonoeLegacyWebFallbackInFlight = NO;",
        "dispatch_async(dispatch_get_main_queue(), ^{",
        "gZonoeLegacyWebFallbackInFlight || ZONUDIDBridgeCurrentUDID().length > 0",
        "WX_NongShiFu123 *legacyAuth = [WX_NongShiFu123 new];",
        "[legacyAuth getUDID:^{",
        "[getKeychain getKeychainDataForKey:@\"DZUDID\"]",
        "ZONUDIDBridgeIsPlausibleUDID(udid)",
        "ZONUDIDBridgeStoreUDID(udid);",
    ]
    for marker in required:
        if marker not in m:
            fail(f"adapter marker missing: {marker}")

    base_api = git_show("testmod/ZONServices/ZonoeUDIDAPI.m")
    start = base_api.index("static BOOL gZonoeLegacyWebFallbackInFlight = NO;")
    end = base_api.index("static void ZonoeDeliverUDIDIfNeeded(NSString *udid)")
    old_block = base_api[start:end].replace(
        "static void ZonoeStartLegacyWebUDIDFallback(void)",
        "void ZONStartLegacyWebUDIDFallback(void)", 1,
    ).strip()
    new_block = m[m.index("static BOOL gZonoeLegacyWebFallbackInFlight = NO;"):].strip()
    if old_block != new_block:
        fail("adapter body is not a mechanical copy of P44 fallback block")

    if pbx.count("ZONLegacyUDIDFallbackAdapter.m in Sources") != 2:
        fail("adapter PBX build/source registration mismatch")
    source_section = pbx.split("/* Begin PBXSourcesBuildPhase section */",1)[1].split("/* End PBXSourcesBuildPhase section */",1)[0]
    active = source_section.count(" in Sources */,")
    if active != 79:
        fail(f"expected 79 active source entries, got {active}")

    protected = [
        "testmod/Bsphp/main.m",
        "testmod/Bsphp/WX_NongShiFu123.mm",
        "testmod/ZONServices/ZONUDIDBridge.h",
        "testmod/ZONServices/ZONUDIDBridge.m",
        "testmod/ZONServices/ZONAuthorizationCoordinator.h",
        "testmod/ZONServices/ZONAuthorizationCoordinator.m",
        "testmod/ZONCore/ZONBootstrap.m",
        "testmod/ZONCore/ZONModuleLoader.m",
        "testmod/ZONCore/ZONFeatureDispatcher.m",
        "testmod/菜单/PubgLoad.mm",
    ]
    for path in protected:
        current = (ROOT / path).read_bytes()
        base = subprocess.check_output(["git", "show", f"{BASE}:{path}"])
        if current != base:
            fail(f"protected runtime changed: {path}")

    print("p45-contract: OK")


if __name__ == "__main__":
    main()
