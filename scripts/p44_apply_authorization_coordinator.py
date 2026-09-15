#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "testmod/Bsphp/main.m"
HEADER = ROOT / "testmod/ZONServices/ZONAuthorizationCoordinator.h"
IMPL = ROOT / "testmod/ZONServices/ZONAuthorizationCoordinator.m"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
VERSION = ROOT / "VERSION"

START = "#pragma mark - Authorization reset compatibility\n"
END = "@implementation NSObject (mian)\n"
COORD_IMPORT = '#import "../ZONServices/ZONAuthorizationCoordinator.h"\n'
FILE_REF_ID = "7ECBD4422F3A614B00C56F1C"
BUILD_FILE_ID = "7ECBD4432F3A614B00C56F1C"


def fail(msg):
    raise SystemExit(f"p44-apply: {msg}")


def main():
    text = MAIN.read_text(encoding="utf-8")
    if START not in text or END not in text:
        fail("authorization block markers not found in main.m")
    if COORD_IMPORT in text:
        fail("coordinator import already exists")
    if HEADER.exists() or IMPL.exists():
        fail("coordinator files already exist")

    start = text.index(START)
    end = text.index(END)
    block = text[start:end]

    required = [
        "static IMP gZONOriginalDeleteKM = NULL;",
        "static void ZONClearStoredUDIDState(void)",
        "static void ZONDeleteKMAndUDID(id self, SEL _cmd)",
        "static void ZONInstallAuthorizationResetExtension(void)",
        "static void ZONShowCustomerStatus(NSString *text,",
        "static void ZONContinueCustomerAuthorization(WX_NongShiFu123 *auth, NSString *udid, BOOL newlyFetched)",
        "static void ZONStartCustomerAuthorization(void)",
        "ZonoeSetUDIDCallback(^(NSString *udid)",
        "ZonoeRequestUDIDIfNeeded();",
    ]
    for marker in required:
        if marker not in block:
            fail(f"missing expected marker: {marker}")

    migrated = block.replace(
        "static void ZONInstallAuthorizationResetExtension(void)",
        "void ZONInstallAuthorizationResetExtension(void)",
        1,
    ).replace(
        "static void ZONStartCustomerAuthorization(void)",
        "void ZONStartCustomerAuthorization(void)",
        1,
    )

    HEADER.write_text(
        '#import <Foundation/Foundation.h>\n\n'
        'NS_ASSUME_NONNULL_BEGIN\n\n'
        'void ZONInstallAuthorizationResetExtension(void) __attribute__((visibility("hidden")));\n'
        'void ZONStartCustomerAuthorization(void) __attribute__((visibility("hidden")));\n\n'
        'NS_ASSUME_NONNULL_END\n',
        encoding="utf-8",
    )

    IMPL.write_text(
        '#import "ZONAuthorizationCoordinator.h"\n'
        '#import "../Bsphp/WX_NongShiFu123.h"\n'
        '#import "../category/getKeychain.h"\n'
        '#import "../导入导出/JDStatusBarNotification/Public/JDStatusBarNotification.h"\n'
        '#import "ZonoeUDIDAPI.h"\n'
        '#import <objc/runtime.h>\n\n' + migrated,
        encoding="utf-8",
    )

    new_main = text[:start] + text[end:]
    anchor = '#import "../ZONServices/ZonoeUDIDAPI.h"\n'
    if anchor not in new_main:
        fail("main.m import anchor missing")
    new_main = new_main.replace(anchor, anchor + COORD_IMPORT, 1)
    MAIN.write_text(new_main, encoding="utf-8")

    pbx = PBX.read_text(encoding="utf-8")
    if "ZONAuthorizationCoordinator.m in Sources" in pbx or "ZONAuthorizationCoordinator.m */" in pbx:
        fail("PBX already contains coordinator")

    file_ref_anchor = '7ECBD4402F3A614B00C56F1C /* ZonoeUDIDAPI.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = ZonoeUDIDAPI.m; sourceTree = "<group>"; };'
    build_anchor = '7ECBD4412F3A614B00C56F1C /* ZonoeUDIDAPI.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD4402F3A614B00C56F1C /* ZonoeUDIDAPI.m */; };'
    group_item = "\t\t\t\t7ECBD4402F3A614B00C56F1C /* ZonoeUDIDAPI.m */,"
    source_item = "\t\t\t\t7ECBD4412F3A614B00C56F1C /* ZonoeUDIDAPI.m in Sources */,"

    for marker, name in [
        (file_ref_anchor, "fileRef"),
        (build_anchor, "build"),
        (group_item, "group"),
        (source_item, "sources"),
    ]:
        if marker not in pbx:
            fail(f"PBX ZonoeUDIDAPI.m {name} anchor missing")

    pbx = pbx.replace(
        file_ref_anchor,
        file_ref_anchor + f'\n\t\t{FILE_REF_ID} /* ZONAuthorizationCoordinator.m */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = ZONAuthorizationCoordinator.m; sourceTree = "<group>"; }};',
        1,
    )
    pbx = pbx.replace(
        build_anchor,
        build_anchor + f'\n\t\t{BUILD_FILE_ID} /* ZONAuthorizationCoordinator.m in Sources */ = {{isa = PBXBuildFile; fileRef = {FILE_REF_ID} /* ZONAuthorizationCoordinator.m */; }};',
        1,
    )
    pbx = pbx.replace(
        group_item,
        group_item + f"\n\t\t\t\t{FILE_REF_ID} /* ZONAuthorizationCoordinator.m */,",
        1,
    )
    pbx = pbx.replace(
        source_item,
        source_item + f"\n\t\t\t\t{BUILD_FILE_ID} /* ZONAuthorizationCoordinator.m in Sources */,",
        1,
    )
    PBX.write_text(pbx, encoding="utf-8")

    VERSION.write_text("v1_p44\n", encoding="utf-8")
    print("p44-apply: OK")


if __name__ == "__main__":
    main()
