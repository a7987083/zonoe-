#!/usr/bin/env python3
from pathlib import Path
import re

P40_SOURCE = "09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33"
HEADER = Path("testmod/ZONServices/ZONUDIDBridge.h")
IMPL = Path("testmod/ZONServices/ZONUDIDBridge.m")
PBX = Path("testmod.xcodeproj/project.pbxproj")
VERSION = Path("VERSION")

PUBLIC_FUNCTIONS = [
    "ZONUDIDBridgeCallbackScheme",
    "ZONUDIDBridgeCallbackHost",
    "ZONUDIDBridgeCallbackURL",
    "ZONUDIDBridgeIsPlausibleNonce",
    "ZONUDIDBridgeNewNonce",
    "ZONUDIDBridgeRequestURLForNonce",
    "ZONUDIDBridgeRequestURL",
    "ZONUDIDBridgeIsPlausibleUDID",
    "ZONUDIDBridgeCurrentUDID",
    "ZONUDIDBridgeClearPendingRequest",
    "ZONUDIDBridgeStoreUDID",
    "ZONUDIDBridgeHandleURL",
    "ZONUDIDBridgeFetchLocalResultOnce",
    "ZONUDIDBridgeFetchPendingResult",
    "ZONUDIDBridgeStart",
    "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
    "ZONUDIDBridgeRequestIfNeeded",
    "ZONUDIDBridgeForceRefreshWithUnavailableHandler",
    "ZONUDIDBridgeForceRefresh",
]

DECLARATION_HEADER = r'''#ifndef ZONUDIDBridge_h
#define ZONUDIDBridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN

#define ZONUDID_BRIDGE_HIDDEN __attribute__((visibility("hidden")))

FOUNDATION_EXPORT NSString * const ZONUDIDBridgeValueKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeSchemeKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeRequestTimestampKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeRequestNonceKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeDidUpdateNotification ZONUDID_BRIDGE_HIDDEN;
extern const uint16_t ZONUDIDBridgePort ZONUDID_BRIDGE_HIDDEN;

NSString * _Nullable ZONUDIDBridgeCallbackScheme(void) ZONUDID_BRIDGE_HIDDEN;
NSString *ZONUDIDBridgeCallbackHost(void) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeCallbackURL(void) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeIsPlausibleNonce(NSString *value) ZONUDID_BRIDGE_HIDDEN;
NSString *ZONUDIDBridgeNewNonce(void) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeRequestURLForNonce(NSString *nonce) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeRequestURL(void) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeIsPlausibleUDID(NSString *value) ZONUDID_BRIDGE_HIDDEN;
NSString * _Nullable ZONUDIDBridgeCurrentUDID(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeClearPendingRequest(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeStoreUDID(NSString *udid) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeHandleURL(NSURL *url) ZONUDID_BRIDGE_HIDDEN;
NSDictionary * _Nullable ZONUDIDBridgeFetchLocalResultOnce(NSString *nonce) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeFetchPendingResult(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeStart(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeRequestIfNeeded(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeForceRefreshWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeForceRefresh(void) ZONUDID_BRIDGE_HIDDEN;

#undef ZONUDID_BRIDGE_HIDDEN

NS_ASSUME_NONNULL_END

#endif /* ZONUDIDBridge_h */
'''


def fail(message: str) -> None:
    raise SystemExit("p41-apply-udidbridge-boundary: FAIL: " + message)


def extract_body(old: str) -> str:
    begin = "NS_ASSUME_NONNULL_BEGIN\n"
    end = "\nNS_ASSUME_NONNULL_END"
    if old.count(begin) != 1 or old.count(end) != 1:
        fail("unexpected ZONUDIDBridge.h assume-nonnull structure")
    body = old.split(begin, 1)[1].rsplit(end, 1)[0]
    return body


def transformed_implementation(old: str) -> str:
    body = extract_body(old)
    body = body.replace('static NSString * const ', 'NSString * const ')
    body = body.replace('static const uint16_t ', 'const uint16_t ')
    body = body.replace('static inline ', '')
    return '''#import "ZONUDIDBridge.h"\n\n#include <arpa/inet.h>\n#include <netinet/in.h>\n#include <sys/socket.h>\n#include <sys/time.h>\n#include <unistd.h>\n\n''' + body.strip() + "\n"


def active_source_names(pbx: str) -> list[str]:
    names: list[str] = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    return names


def patch_pbx(pbx: str) -> str:
    if "ZONUDIDBridge.m in Sources" in pbx or 'testmod/ZONServices/ZONUDIDBridge.m' in pbx:
        fail("ZONUDIDBridge.m already registered in PBX")

    build_anchor = '\t\t7ECBD43D2F3A614900C56F1C /* ZONBootstrap.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD43C2F3A614900C56F1C /* ZONBootstrap.m */; };\n'
    file_anchor = '\t\t7ECBD43C2F3A614900C56F1C /* ZONBootstrap.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONBootstrap/ZONBootstrap.m"; sourceTree = SOURCE_ROOT; };\n'
    source_anchor = '\t\t\t\t7ECBD43D2F3A614900C56F1C /* ZONBootstrap.m in Sources */,\n'

    for anchor, label in [(build_anchor, "build file"), (file_anchor, "file ref"), (source_anchor, "source phase")]:
        if pbx.count(anchor) != 1:
            fail(f"PBX {label} anchor mismatch")

    pbx = pbx.replace(
        build_anchor,
        build_anchor + '\t\t7ECBD43F2F3A614A00C56F1C /* ZONUDIDBridge.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD43E2F3A614A00C56F1C /* ZONUDIDBridge.m */; };\n',
        1,
    )
    pbx = pbx.replace(
        file_anchor,
        file_anchor + '\t\t7ECBD43E2F3A614A00C56F1C /* ZONUDIDBridge.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONUDIDBridge.m"; sourceTree = SOURCE_ROOT; };\n',
        1,
    )
    pbx = pbx.replace(
        source_anchor,
        source_anchor + '\t\t\t\t7ECBD43F2F3A614A00C56F1C /* ZONUDIDBridge.m in Sources */,\n',
        1,
    )
    return pbx


def main() -> None:
    if VERSION.read_text().strip() != "v1_p40":
        fail("expected v1_p40 input")
    if IMPL.exists():
        fail("ZONUDIDBridge.m already exists")

    old = HEADER.read_text()
    for function in PUBLIC_FUNCTIONS:
        if old.count(function + "(") < 1:
            fail(f"expected function missing from old header: {function}")

    impl = transformed_implementation(old)
    pbx_before = PBX.read_text(errors="replace")
    before_sources = active_source_names(pbx_before)
    if len(before_sources) != 75:
        fail(f"expected 75 active sources before P41, got {len(before_sources)}")

    pbx_after = patch_pbx(pbx_before)
    after_sources = active_source_names(pbx_after)
    if len(after_sources) != 76:
        fail(f"expected 76 active sources after P41, got {len(after_sources)}")
    if set(after_sources) - set(before_sources) != {"ZONUDIDBridge.m"}:
        fail("PBX source delta is not exactly ZONUDIDBridge.m")
    if set(before_sources) - set(after_sources):
        fail("existing PBX source disappeared")

    HEADER.write_text(DECLARATION_HEADER)
    IMPL.write_text(impl)
    PBX.write_text(pbx_after)
    VERSION.write_text("v1_p41\n")

    print("p41-apply-udidbridge-boundary: PASS (75 -> 76 sources; bridge implementation moved verbatim)")


if __name__ == "__main__":
    main()
