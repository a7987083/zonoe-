#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

P40 = "09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33"
BRIDGE_HEADER = "testmod/ZONServices/ZONUDIDBridge.h"
BRIDGE_IMPL = "testmod/ZONServices/ZONUDIDBridge.m"
PBX_PATH = "testmod.xcodeproj/project.pbxproj"

FUNCTIONS = [
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

PROTECTED_UNCHANGED = [
    "testmod/Bsphp/main.m",
    "testmod/Bsphp/WX_NongShiFu123.mm",
    "testmod/ZONBootstrap/ZONBootstrap.m",
    "testmod/ZONCore/ZONModuleLoader.m",
    "testmod/ZONCore/ZONFeatureRegistry.m",
    "testmod/ZONCore/ZONFeatureDispatcher.h",
    "testmod/ZONCore/ZONFeatureDispatcher.m",
    "testmod/ZONCore/ZONMenuEventBridge.m",
    "testmod/ZONCore/ZONMenuCoordinator.m",
    "testmod/视图菜单/NSObject+UI.m",
    "testmod/菜单/PopupMenuVC.m",
    "testmod/菜单/JHDragView.m",
    "testmod/菜单/PubgLoad.mm",
    "testmod/菜单/SandboxBrowserVC.m",
    "testmod/导入导出/daochucd.m",
    "testmod/导入导出/fuhzu.m",
    "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m",
    "testmod/工具箱/Hook/JiangHuHook.m",
    "testmod/工具箱/变速器/HookClass.m",
    "testmod/工具箱/变速器/ImgTool.m",
    "testmod/工具箱/变速器/fishhook/fishhook.c",
]


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True, errors="replace").strip()


def fail(message: str) -> None:
    raise SystemExit("p41-udidbridge-boundary-contract: FAIL: " + message)


def show(ref: str, path: str) -> str:
    return subprocess.check_output(["git", "show", f"{ref}:{path}"], text=True, errors="replace")


def tree(ref: str, path: str) -> str:
    return out("git", "rev-parse", f"{ref}:{path}")


def active_source_names(pbx: str) -> list[str]:
    names: list[str] = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    return names


def expected_impl_from_p40_header(old: str) -> str:
    begin = "NS_ASSUME_NONNULL_BEGIN\n"
    end = "\nNS_ASSUME_NONNULL_END"
    if old.count(begin) != 1 or old.count(end) != 1:
        fail("P40 bridge header structure changed unexpectedly")
    body = old.split(begin, 1)[1].rsplit(end, 1)[0]
    body = body.replace('static NSString * const ', 'NSString * const ')
    body = body.replace('static const uint16_t ', 'const uint16_t ')
    body = body.replace('static inline ', '')
    return '''#import "ZONUDIDBridge.h"\n\n#include <arpa/inet.h>\n#include <netinet/in.h>\n#include <sys/socket.h>\n#include <sys/time.h>\n#include <unistd.h>\n\n''' + body.strip() + "\n"


if Path("VERSION").read_text().strip() != "v1_p41":
    fail("VERSION must be v1_p41")

expected_product_diff = {
    "VERSION",
    BRIDGE_HEADER,
    BRIDGE_IMPL,
    PBX_PATH,
}
actual_product_diff = set(filter(None, out(
    "git", "diff", "--name-only", P40, "HEAD", "--",
    "VERSION", "testmod", "testmod.xcodeproj"
).splitlines()))
if actual_product_diff != expected_product_diff:
    fail(f"unexpected product diff vs P40: {sorted(actual_product_diff)}")

header = Path(BRIDGE_HEADER).read_text(errors="replace")
impl = Path(BRIDGE_IMPL).read_text(errors="replace")
old_header = show(P40, BRIDGE_HEADER)
expected_impl = expected_impl_from_p40_header(old_header)
if impl != expected_impl:
    fail("ZONUDIDBridge.m is not a mechanical implementation move from P40 header")

if "static inline" in header:
    fail("bridge header still owns inline implementation")
for leaked in ["arpa/inet.h", "netinet/in.h", "sys/socket.h", "sys/time.h", "unistd.h"]:
    if leaked in header:
        fail(f"bridge header still leaks implementation dependency: {leaked}")
if "visibility(\"hidden\")" not in header:
    fail("bridge declarations are not explicitly hidden from dylib exports")
for function in FUNCTIONS:
    if header.count(function + "(") != 1:
        fail(f"bridge declaration count mismatch for {function}")
    if impl.count(function + "(") < 1:
        fail(f"bridge implementation missing {function}")

for key in [
    "zonoe.udid.bridge.value",
    "zonoe.udid.bridge.scheme",
    "zonoe.udid.bridge.requestTimestamp",
    "zonoe.udid.bridge.requestNonce",
    "zonoe.udid.bridge.didUpdate",
    "14302",
    "700000",
    "attempt < 6",
    "usleep(250000)",
    "age > 90.0",
    "now - previous < 10.0",
    "unable to open zonoe://udid; using web fallback",
]:
    if key not in impl:
        fail(f"UDID state-machine invariant marker missing: {key}")

base_pbx = show(P40, PBX_PATH)
pbx = Path(PBX_PATH).read_text(errors="replace")
base_sources = active_source_names(base_pbx)
current_sources = active_source_names(pbx)
if len(base_sources) != 75:
    fail(f"P40 baseline source count is not 75: {len(base_sources)}")
if len(current_sources) != 76:
    fail(f"P41 source count must be 76: {len(current_sources)}")
if set(current_sources) - set(base_sources) != {"ZONUDIDBridge.m"}:
    fail("P41 source addition is not exactly ZONUDIDBridge.m")
if set(base_sources) - set(current_sources):
    fail("P41 removed a P40 active source")
if pbx.count("ZONUDIDBridge.m in Sources") != 2:
    fail("ZONUDIDBridge.m PBX build-file/source-phase registration mismatch")
if pbx.count('path = "testmod/ZONServices/ZONUDIDBridge.m"') != 1:
    fail("ZONUDIDBridge.m PBX file reference mismatch")

for path in PROTECTED_UNCHANGED:
    if tree(P40, path) != tree("HEAD", path):
        fail(f"protected runtime source changed: {path}")

ui = Path("testmod/视图菜单/NSObject+UI.m").read_text(errors="replace")
for marker in [
    "ZONUDIDBridgeCurrentUDID",
    "ZONUDIDBridgeIsPlausibleUDID",
    "ZONUDIDBridgeStoreUDID",
    "ZONUDIDBridgeDidUpdateNotification",
    "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
    "ZONUDIDBridgeForceRefreshWithUnavailableHandler",
    "ZonoeStartLegacyWebUDIDFallback",
]:
    if marker not in ui:
        fail(f"UI/UDID consumer marker disappeared: {marker}")

main = Path("testmod/Bsphp/main.m").read_text(errors="replace")
for marker in ["+(void)load", "ZONBootstrapStart", "ZONStartCustomerAuthorization", "ZonoeRequestUDIDIfNeeded"]:
    if marker not in main and marker.replace("+(void)", "+ (void)") not in main:
        fail(f"startup/authorization marker disappeared: {marker}")

print("p41-udidbridge-boundary-contract: PASS (mechanical bridge move; 75 -> 76 sources; protected behavior unchanged)")
