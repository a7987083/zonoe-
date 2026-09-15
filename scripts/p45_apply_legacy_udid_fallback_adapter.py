#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "testmod/ZONServices/ZonoeUDIDAPI.m"
HEADER = ROOT / "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.h"
IMPL = ROOT / "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
VERSION = ROOT / "VERSION"

FILE_REF_ID = "7ECBD4442F3A614B00C56F1C"
BUILD_FILE_ID = "7ECBD4452F3A614B00C56F1C"
START = "static BOOL gZonoeLegacyWebFallbackInFlight = NO;\n\nstatic void ZonoeStartLegacyWebUDIDFallback(void)\n"
END = "static void ZonoeDeliverUDIDIfNeeded(NSString *udid)\n"


def fail(msg):
    raise SystemExit(f"p45-apply: {msg}")


def only_line(lines, predicate, name):
    found = [line for line in lines if predicate(line)]
    if len(found) != 1:
        fail(f"expected one {name}, found {len(found)}")
    return found[0]


def main():
    text = API.read_text(encoding="utf-8")
    if HEADER.exists() or IMPL.exists():
        fail("adapter files already exist")
    if START not in text or END not in text:
        fail("fallback block markers not found")

    start = text.index(START)
    end = text.index(END)
    block = text[start:end]
    required = [
        "gZonoeLegacyWebFallbackInFlight",
        "dispatch_async(dispatch_get_main_queue()",
        "WX_NongShiFu123 *legacyAuth = [WX_NongShiFu123 new];",
        "[legacyAuth getUDID:^{",
        "[getKeychain getKeychainDataForKey:@\"DZUDID\"]",
        "ZONUDIDBridgeIsPlausibleUDID(udid)",
        "ZONUDIDBridgeStoreUDID(udid);",
    ]
    for marker in required:
        if marker not in block:
            fail(f"missing expected marker: {marker}")

    moved = block.replace(
        "static void ZonoeStartLegacyWebUDIDFallback(void)",
        "void ZONStartLegacyWebUDIDFallback(void)",
        1,
    )

    HEADER.write_text(
        '#import <Foundation/Foundation.h>\n\n'
        'void ZONStartLegacyWebUDIDFallback(void) __attribute__((visibility("hidden")));\n',
        encoding="utf-8",
    )
    IMPL.write_text(
        '#import "ZONLegacyUDIDFallbackAdapter.h"\n'
        '#import "ZONUDIDBridge.h"\n'
        '#import "../Bsphp/WX_NongShiFu123.h"\n'
        '#import "../category/getKeychain.h"\n\n' + moved,
        encoding="utf-8",
    )

    new_text = text[:start] + text[end:]
    new_text = new_text.replace('#import "ZONUDIDBridge.h"\n', '#import "ZONUDIDBridge.h"\n#import "ZONLegacyUDIDFallbackAdapter.h"\n', 1)
    new_text = new_text.replace('#import "../Bsphp/WX_NongShiFu123.h"\n', '', 1)
    new_text = new_text.replace('#import "../category/getKeychain.h"\n', '', 1)
    new_text = new_text.replace('ZonoeStartLegacyWebUDIDFallback();', 'ZONStartLegacyWebUDIDFallback();')
    if "ZonoeStartLegacyWebUDIDFallback" in new_text or "gZonoeLegacyWebFallbackInFlight" in new_text:
        fail("legacy fallback implementation remains in ZonoeUDIDAPI.m")
    API.write_text(new_text, encoding="utf-8")

    pbx = PBX.read_text(encoding="utf-8")
    if "ZONLegacyUDIDFallbackAdapter.m" in pbx:
        fail("PBX already contains adapter")
    lines = pbx.splitlines()
    file_line = only_line(lines, lambda x: "/* ZonoeUDIDAPI.m */ = {isa = PBXFileReference;" in x, "ZonoeUDIDAPI fileRef")
    build_line = only_line(lines, lambda x: "/* ZonoeUDIDAPI.m in Sources */ = {isa = PBXBuildFile;" in x, "ZonoeUDIDAPI buildRef")
    old_build_id = build_line.strip().split()[0]
    source_line = only_line(lines, lambda x: x.strip() == f"{old_build_id} /* ZonoeUDIDAPI.m in Sources */,", "ZonoeUDIDAPI source item")

    pbx = pbx.replace(
        file_line,
        file_line + f'\n\t\t{FILE_REF_ID} /* ZONLegacyUDIDFallbackAdapter.m */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m"; sourceTree = SOURCE_ROOT; }};',
        1,
    )
    pbx = pbx.replace(
        build_line,
        build_line + f'\n\t\t{BUILD_FILE_ID} /* ZONLegacyUDIDFallbackAdapter.m in Sources */ = {{isa = PBXBuildFile; fileRef = {FILE_REF_ID} /* ZONLegacyUDIDFallbackAdapter.m */; }};',
        1,
    )
    indent = source_line[:len(source_line) - len(source_line.lstrip())]
    pbx = pbx.replace(source_line, source_line + f'\n{indent}{BUILD_FILE_ID} /* ZONLegacyUDIDFallbackAdapter.m in Sources */,', 1)
    PBX.write_text(pbx, encoding="utf-8")
    VERSION.write_text("v1_p45\n", encoding="utf-8")
    print("p45-apply: OK")


if __name__ == "__main__":
    main()
