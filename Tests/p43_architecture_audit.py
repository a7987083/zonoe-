#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
P42_PRODUCT = "e87b683a9c868e00d13582c8145bb9368878fee3"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
MAIN = ROOT / "testmod/Bsphp/main.m"


def fail(msg: str) -> None:
    print(f"p43-audit: FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def require(cond: bool, msg: str) -> None:
    if not cond:
        fail(msg)


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


# P43 must be audit-only: canonical product runtime tree is identical to P42 product source.
diff = git("-c", "core.quotepath=false", "diff", "--name-only", P42_PRODUCT, "HEAD", "--", "testmod", "testmod.xcodeproj")
require(diff == "", f"runtime/PBX changed during audit: {diff.splitlines()}")

pbx = PBX.read_text(encoding="utf-8")
main = MAIN.read_text(encoding="utf-8")

# Count build-phase source entries only, not the PBXBuildFile declarations.
m = re.search(r"/\* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/", pbx, re.S)
require(m is not None, "PBXSourcesBuildPhase section missing")
source_phase = m.group(1)
source_entries = re.findall(r"/\* .*? in Sources \*/", source_phase)
require(len(source_entries) == 77, f"active Sources expected 77, got {len(source_entries)}")

required_active = [
    "main.m in Sources",
    "WX_NongShiFu123.mm in Sources",
    "PubgLoad.mm in Sources",
    "JiangHuHook.m in Sources",
    "daochucd.m in Sources",
    "YYYPicker.m in Sources",
    "fuhzu.m in Sources",
    "ZONUDIDBridge.m in Sources",
    "ZonoeUDIDAPI.m in Sources",
]
for marker in required_active:
    require(marker in source_phase, f"active source marker missing: {marker}")

# Lock the exact current P44 extraction markers before implementation begins.
required_main_markers = [
    "static IMP gZONOriginalDeleteKM = NULL;",
    "static void ZONClearStoredUDIDState(void)",
    "static void ZONDeleteKMAndUDID(id self, SEL _cmd)",
    "static void ZONInstallAuthorizationResetExtension(void)",
    "static void ZONShowCustomerStatus(NSString *text,",
    "static void ZONContinueCustomerAuthorization(WX_NongShiFu123 *auth, NSString *udid, BOOL newlyFetched)",
    "static void ZONStartCustomerAuthorization(void)",
    "ZONInstallAuthorizationResetExtension();",
    "ZONBootstrapStart(^{",
    "ZonoeSetUDIDCallback(^(NSString *udid)",
    "ZonoeRequestUDIDIfNeeded();",
    "[auth loada];",
]
for marker in required_main_markers:
    require(marker in main, f"P44 target marker missing: {marker}")

# Protected startup sequencing: reset hook before Bootstrap; A/B branch remains inside ready callback.
require(main.index("ZONInstallAuthorizationResetExtension();") < main.index("ZONBootstrapStart(^{"),
        "authorization reset install must precede Bootstrap")
require("#if ZON_BUILD_VARIANT_DEBUG" in main, "variant branch missing")
require("[NSObject 显示图标];" in main, "B_debug floating entry missing")
require("ZONStartCustomerAuthorization();" in main, "A_customer auth entry missing")

# P43 audit documents must identify P44 target and preserve P42 as baseline.
audit = (ROOT / "P43_ARCHITECTURE_AUDIT.md").read_text(encoding="utf-8")
roadmap = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
require("Authorization Orchestration Boundary" in audit, "P44 decision missing from P43 audit")
require("v1_p42" in audit and P42_PRODUCT in audit, "P42 baseline missing from P43 audit")
require("P43 — Architecture State Refresh & Remaining Ownership Audit" in roadmap, "P43 roadmap stage missing")

print("p43-audit: PASS")
print(f"p43-audit: active_sources={len(source_entries)}")
print("p43-audit: runtime_tree_vs_p42=identical")
print("p43-audit: p44_target=authorization_orchestration_boundary")
