#!/usr/bin/env python3
from pathlib import Path
import re

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


def one_match(pattern, text, name):
    matches = list(re.finditer(pattern, text, re.M))
    if len(matches) != 1:
        fail(f"expected one {name} anchor, found {len(matches)}")
    return matches[0]


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
        "void ZONInstallAuthorizationResetExtension(void)", 1,
    ).replace(
        "static void ZONStartCustomerAuthorization(void)",
        "void ZONStartCustomerAuthorization(void)", 1,
    )

    HEADER.write_text(
        '#import <Foundation/Foundation.h>\n\n'
        'void ZONInstallAuthorizationResetExtension(void) __attribute__((visibility("hidden")));\n'
        'void ZONStartCustomerAuthorization(void) __attribute__((visibility("hidden")));\n',
        encoding="utf-8",
    )
    IMPL.write_text(
        '#import "ZONAuthorizationCoordinator.h"\n'
        '#import "../Bsphp/WX_NongShiFu123.h"\n'
        '#import "../category/getKeychain.h"\n'
        '#import "JDStatusBarNotification.h"\n'
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
    if "ZONAuthorizationCoordinator.m" in pbx:
        fail("PBX already contains coordinator")

    file_ref = one_match(r'^\s*([A-F0-9]{24}) /\* ZonoeUDIDAPI\.m \*/ = \{isa = PBXFileReference;.*path = ZonoeUDIDAPI\.m;.*\};$', pbx, "fileRef")
    old_file_id = file_ref.group(1)
    file_line = file_ref.group(0)
    pbx = pbx.replace(
        file_line,
        file_line + f'\n\t\t{FILE_REF_ID} /* ZONAuthorizationCoordinator.m */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = ZONAuthorizationCoordinator.m; sourceTree = "<group>"; }};',
        1,
    )

    build_ref = one_match(rf'^\s*([A-F0-9]{{24}}) /\* ZonoeUDIDAPI\.m in Sources \*/ = \{{isa = PBXBuildFile; fileRef = {old_file_id} /\* ZonoeUDIDAPI\.m \*/; \}};$', pbx, "buildRef")
    old_build_id = build_ref.group(1)
    build_line = build_ref.group(0)
    pbx = pbx.replace(
        build_line,
        build_line + f'\n\t\t{BUILD_FILE_ID} /* ZONAuthorizationCoordinator.m in Sources */ = {{isa = PBXBuildFile; fileRef = {FILE_REF_ID} /* ZONAuthorizationCoordinator.m */; }};',
        1,
    )

    group_match = one_match(rf'^\s*{old_file_id} /\* ZonoeUDIDAPI\.m \*/,$', pbx, "group item")
    group_line = group_match.group(0)
    indent = group_line[:len(group_line) - len(group_line.lstrip())]
    pbx = pbx.replace(group_line, group_line + f'\n{indent}{FILE_REF_ID} /* ZONAuthorizationCoordinator.m */,', 1)

    source_match = one_match(rf'^\s*{old_build_id} /\* ZonoeUDIDAPI\.m in Sources \*/,$', pbx, "source item")
    source_line = source_match.group(0)
    indent = source_line[:len(source_line) - len(source_line.lstrip())]
    pbx = pbx.replace(source_line, source_line + f'\n{indent}{BUILD_FILE_ID} /* ZONAuthorizationCoordinator.m in Sources */,', 1)

    PBX.write_text(pbx, encoding="utf-8")
    VERSION.write_text("v1_p44\n", encoding="utf-8")
    print(f"p44-apply: OK old_file={old_file_id} old_build={old_build_id}")


if __name__ == "__main__":
    main()
