#!/usr/bin/env python3
from pathlib import Path
import re

UI = Path("testmod/视图菜单/NSObject+UI.m")
API_IMPL = Path("testmod/ZONServices/ZonoeUDIDAPI.m")
PBX = Path("testmod.xcodeproj/project.pbxproj")
VERSION = Path("VERSION")

START = "#pragma mark - Stable public UDID API\n"
END = "\n@implementation NSObject (UI)"

REMOVED_UI_IMPORTS = [
    '#import "../ZONServices/ZONUDIDBridge.h"\n',
    '#import "../ZONServices/ZonoeUDIDAPI.h"\n',
    '#import "../Bsphp/WX_NongShiFu123.h"\n',
    '#import "../category/getKeychain.h"\n',
]

API_IMPORTS = '''#import "ZonoeUDIDAPI.h"\n#import "ZONUDIDBridge.h"\n#import "../Bsphp/WX_NongShiFu123.h"\n#import "../category/getKeychain.h"\n\n'''


def fail(message: str) -> None:
    raise SystemExit("p42-apply-zonoe-udid-api-boundary: FAIL: " + message)


def active_source_names(pbx: str) -> list[str]:
    names: list[str] = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    return names


def extract_api_block(ui: str) -> str:
    if ui.count(START) != 1 or ui.count(END) != 1:
        fail("unexpected NSObject+UI.m UDID API boundary markers")
    return ui.split(START, 1)[1].split(END, 1)[0].rstrip() + "\n"


def strip_api_from_ui(ui: str) -> str:
    block = START + ui.split(START, 1)[1].split(END, 1)[0]
    result = ui.replace(block, "", 1)
    for imp in REMOVED_UI_IMPORTS:
        if result.count(imp) != 1:
            fail("UI import anchor mismatch: " + imp.strip())
        result = result.replace(imp, "", 1)
    while "\n\n\n" in result[:500]:
        result = result.replace("\n\n\n", "\n\n", 1)
    return result


def patch_pbx(pbx: str) -> str:
    if "ZonoeUDIDAPI.m in Sources" in pbx or 'testmod/ZONServices/ZonoeUDIDAPI.m' in pbx:
        fail("ZonoeUDIDAPI.m already registered in PBX")

    build_anchor = '\t\t7ECBD43F2F3A614A00C56F1C /* ZONUDIDBridge.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD43E2F3A614A00C56F1C /* ZONUDIDBridge.m */; };\n'
    file_anchor = '\t\t7ECBD43E2F3A614A00C56F1C /* ZONUDIDBridge.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONUDIDBridge.m"; sourceTree = SOURCE_ROOT; };\n'
    source_anchor = '\t\t\t\t7ECBD43F2F3A614A00C56F1C /* ZONUDIDBridge.m in Sources */,\n'

    for anchor, label in [(build_anchor, "build file"), (file_anchor, "file ref"), (source_anchor, "source phase")]:
        if pbx.count(anchor) != 1:
            fail(f"PBX {label} anchor mismatch")

    pbx = pbx.replace(
        build_anchor,
        build_anchor + '\t\t7ECBD4412F3A614B00C56F1C /* ZonoeUDIDAPI.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD4402F3A614B00C56F1C /* ZonoeUDIDAPI.m */; };\n',
        1,
    )
    pbx = pbx.replace(
        file_anchor,
        file_anchor + '\t\t7ECBD4402F3A614B00C56F1C /* ZonoeUDIDAPI.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZonoeUDIDAPI.m"; sourceTree = SOURCE_ROOT; };\n',
        1,
    )
    pbx = pbx.replace(
        source_anchor,
        source_anchor + '\t\t\t\t7ECBD4412F3A614B00C56F1C /* ZonoeUDIDAPI.m in Sources */,\n',
        1,
    )
    return pbx


def main() -> None:
    if VERSION.read_text().strip() != "v1_p41":
        fail("expected v1_p41 input")
    if API_IMPL.exists():
        fail("ZonoeUDIDAPI.m already exists")

    ui_before = UI.read_text()
    api_block = extract_api_block(ui_before)

    required_markers = [
        "gZonoeUDIDCallback",
        "gZonoeUDIDObserverToken",
        "gZonoeLegacyWebFallbackInFlight",
        "ZonoeStartLegacyWebUDIDFallback",
        "ZonoeDeliverUDIDIfNeeded",
        "ZonoeEnsureUDIDObserver",
        "ZonoeCurrentUDID",
        "ZonoeSetUDIDCallback",
        "ZonoeRequestUDIDIfNeeded",
        "ZonoeRequestUDID",
        "ZonoeForceRefreshUDID",
        "WX_NongShiFu123",
        'getKeychainDataForKey:@"DZUDID"',
        "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
        "ZONUDIDBridgeForceRefreshWithUnavailableHandler",
    ]
    for marker in required_markers:
        if marker not in api_block:
            fail("required API behavior marker missing: " + marker)

    ui_after = strip_api_from_ui(ui_before)
    if "ZonoeCurrentUDID(" in ui_after or "ZonoeRequestUDIDIfNeeded(" in ui_after or "WX_NongShiFu123" in ui_after:
        fail("UDID API implementation residue remains in NSObject+UI.m")
    if "@implementation NSObject (UI)" not in ui_after or "- (void)显示图标" not in ui_after or "- (void)vip菜单显示" not in ui_after:
        fail("UI implementation markers changed unexpectedly")

    impl = API_IMPORTS + "#pragma mark - Stable public UDID API\n\n" + api_block

    pbx_before = PBX.read_text(errors="replace")
    before_sources = active_source_names(pbx_before)
    if len(before_sources) != 76:
        fail(f"expected 76 active sources before P42, got {len(before_sources)}")

    pbx_after = patch_pbx(pbx_before)
    after_sources = active_source_names(pbx_after)
    if len(after_sources) != 77:
        fail(f"expected 77 active sources after P42, got {len(after_sources)}")
    if set(after_sources) - set(before_sources) != {"ZonoeUDIDAPI.m"}:
        fail("PBX source delta is not exactly ZonoeUDIDAPI.m")
    if set(before_sources) - set(after_sources):
        fail("existing PBX source disappeared")

    UI.write_text(ui_after)
    API_IMPL.write_text(impl)
    PBX.write_text(pbx_after)
    VERSION.write_text("v1_p42\n")

    print("p42-apply-zonoe-udid-api-boundary: PASS (76 -> 77 sources; API implementation moved verbatim)")


if __name__ == "__main__":
    main()
