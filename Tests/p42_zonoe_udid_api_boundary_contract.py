#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

P41 = "ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe"
UI = Path("testmod/视图菜单/NSObject+UI.m")
API = Path("testmod/ZONServices/ZonoeUDIDAPI.m")
PBX = Path("testmod.xcodeproj/project.pbxproj")
VERSION = Path("VERSION")
START = "#pragma mark - Stable public UDID API\n"
END = "\n@implementation NSObject (UI)"
REMOVED_IMPORTS = [
    '#import "../ZONServices/ZONUDIDBridge.h"\n',
    '#import "../ZONServices/ZonoeUDIDAPI.h"\n',
    '#import "../Bsphp/WX_NongShiFu123.h"\n',
    '#import "../category/getKeychain.h"\n',
]
API_IMPORTS = '''#import "ZonoeUDIDAPI.h"\n#import "ZONUDIDBridge.h"\n#import "../Bsphp/WX_NongShiFu123.h"\n#import "../category/getKeychain.h"\n\n'''


def fail(msg):
    raise SystemExit("p42-contract: FAIL: " + msg)


def git_show(path):
    return subprocess.check_output(["git", "show", f"{P41}:{path}"], text=True)


def source_names(text):
    out=[]
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', text):
        if name not in out: out.append(name)
    return out


def main():
    if VERSION.read_text().strip() != "v1_p42": fail("VERSION")

    changed = subprocess.check_output([
        "git","diff","--name-only",P41,"HEAD","--","VERSION","testmod","testmod.xcodeproj"
    ], text=True).splitlines()
    expected = {
        "VERSION",
        "testmod/视图菜单/NSObject+UI.m",
        "testmod/ZONServices/ZonoeUDIDAPI.m",
        "testmod.xcodeproj/project.pbxproj",
    }
    if set(changed) != expected: fail("product diff scope: " + repr(changed))

    old_ui = git_show("testmod/视图菜单/NSObject+UI.m")
    if old_ui.count(START) != 1 or old_ui.count(END) != 1: fail("P41 API block anchors")
    block = old_ui.split(START,1)[1].split(END,1)[0].rstrip() + "\n"
    expected_api = API_IMPORTS + START + "\n" + block
    if API.read_text() != expected_api: fail("ZonoeUDIDAPI.m is not an exact mechanical migration")

    old_without = old_ui.replace(START + old_ui.split(START,1)[1].split(END,1)[0], "", 1)
    for imp in REMOVED_IMPORTS:
        if old_without.count(imp) != 1: fail("P41 import anchor: " + imp.strip())
        old_without = old_without.replace(imp, "", 1)
    while "\n\n\n" in old_without[:500]: old_without = old_without.replace("\n\n\n","\n\n",1)
    if UI.read_text() != old_without: fail("NSObject+UI.m changed beyond exact API extraction")

    current_ui = UI.read_text()
    for marker in ["gZonoeUDIDCallback","ZonoeStartLegacyWebUDIDFallback","ZonoeCurrentUDID(","WX_NongShiFu123"]:
        if marker in current_ui: fail("UDID residue in UI: " + marker)
    for marker in ["@implementation NSObject (UI)","- (void)显示图标","- (void)vip菜单显示","- (UIViewController *)topViewController"]:
        if marker not in current_ui: fail("UI marker missing: " + marker)

    api = API.read_text()
    for marker in [
        "gZonoeUDIDCallback","gZonoeUDIDObserverToken","gZonoeLegacyWebFallbackInFlight",
        "ZonoeStartLegacyWebUDIDFallback","ZonoeDeliverUDIDIfNeeded","ZonoeEnsureUDIDObserver",
        "ZonoeCurrentUDID","ZonoeSetUDIDCallback","ZonoeRequestUDIDIfNeeded","ZonoeRequestUDID","ZonoeForceRefreshUDID",
        'getKeychainDataForKey:@"DZUDID"',"ZONUDIDBridgeDidUpdateNotification",
        "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler","ZONUDIDBridgeForceRefreshWithUnavailableHandler",
    ]:
        if marker not in api: fail("API marker missing: " + marker)

    old_pbx = git_show("testmod.xcodeproj/project.pbxproj")
    new_pbx = PBX.read_text(errors="replace")
    before, after = source_names(old_pbx), source_names(new_pbx)
    if len(before) != 76 or len(after) != 77: fail(f"source count {len(before)} -> {len(after)}")
    if set(after)-set(before) != {"ZonoeUDIDAPI.m"}: fail("source add delta")
    if set(before)-set(after): fail("source removed")
    if new_pbx.count("ZonoeUDIDAPI.m in Sources") != 2: fail("PBX build/source registration")
    if new_pbx.count('path = "testmod/ZONServices/ZonoeUDIDAPI.m";') != 1: fail("PBX file ref")

    protected = [
        "testmod/ZONServices/ZONUDIDBridge.h","testmod/ZONServices/ZONUDIDBridge.m","testmod/ZONServices/ZonoeUDIDAPI.h",
        "testmod/Bsphp/main.m","testmod/Bsphp/WX_NongShiFu123.mm","testmod/ZONBootstrap/ZONBootstrap.m",
        "testmod/ZONCore/ZONModuleLoader.m","testmod/ZONCore/ZONFeatureDispatcher.m","testmod/菜单/PubgLoad.mm",
    ]
    for path in protected:
        if Path(path).read_text(errors="replace") != git_show(path): fail("protected source changed: " + path)

    print("p42-contract: PASS (P41 exact API body migrated; UI isolated; Sources 76 -> 77)")

if __name__ == "__main__":
    main()
