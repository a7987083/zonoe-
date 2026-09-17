#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = "841da61c51e8c7fef81c15a56ecdb92c31b9f96d"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
TRACE = ROOT / "testmod/ZONServices/ZONLaunchTrace.h"

TOUCHED = [
    "testmod/Bsphp/main.m",
    "testmod/ZONBootstrap/ZONBootstrap.m",
    "testmod/ZONCore/ZONModuleLoader.m",
    "testmod/ZONServices/ZONAuthorizationCoordinator.m",
    "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m",
    "testmod/视图菜单/NSObject+UI.m",
]

PROTECTED = [
    "testmod/Bsphp/WX_NongShiFu123.mm",
    "testmod/ZONServices/ZonoeUDIDAPI.m",
    "testmod/ZONServices/ZONUDIDBridge.h",
    "testmod/ZONServices/ZONUDIDBridge.m",
    "testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.h",
    "testmod/ZONServices/ZONAuthorizationCoordinator.h",
    "testmod/菜单/PubgLoad.mm",
]


def fail(msg):
    raise SystemExit(f"p46-contract: {msg}")


def git_show(path, binary=False):
    data = subprocess.check_output(["git", "show", f"{BASE}:{path}"])
    return data if binary else data.decode("utf-8")


def strip_trace(text):
    kept = []
    for line in text.splitlines(keepends=True):
        if "ZONLaunchTrace.h" in line:
            continue
        if "ZONLaunchTraceRecord(" in line:
            continue
        kept.append(line)
    return "".join(kept)


def main():
    if (ROOT / "VERSION").read_text().strip() != "v1_p46":
        fail("VERSION != v1_p46")

    if not TRACE.exists():
        fail("ZONLaunchTrace.h missing")
    trace = TRACE.read_text(encoding="utf-8")
    for marker in [
        "mach_absolute_time()",
        "os_log_create(\"com.zonoemenu.launch\", \"startup\")",
        "os_signpost_event_emit",
        "[zonoemenu][TRACE][launch]",
        "NSThread.isMainThread",
    ]:
        if marker not in trace:
            fail(f"trace marker missing: {marker}")
    for forbidden in ["dispatch_async(", "dispatch_after(", "sleep(", "usleep(", "NSTimer", "performSelector"]:
        if forbidden in trace:
            fail(f"trace header may alter scheduling: {forbidden}")

    for path in TOUCHED:
        current = (ROOT / path).read_text(encoding="utf-8")
        base = git_show(path)
        normalized = strip_trace(current)
        if normalized != base:
            fail(f"non-observational change detected after stripping trace calls: {path}")
        if "ZONLaunchTraceRecord(" not in current:
            fail(f"expected trace call missing: {path}")

    for path in PROTECTED:
        if (ROOT / path).read_bytes() != git_show(path, binary=True):
            fail(f"protected runtime changed: {path}")

    current_pbx = PBX.read_bytes()
    base_pbx = git_show("testmod.xcodeproj/project.pbxproj", binary=True)
    if current_pbx != base_pbx:
        fail("PBX changed; P46 must remain header-only instrumentation")
    pbx_text = current_pbx.decode("utf-8")
    source_section = pbx_text.split("/* Begin PBXSourcesBuildPhase section */",1)[1].split("/* End PBXSourcesBuildPhase section */",1)[0]
    active = source_section.count(" in Sources */,")
    if active != 79:
        fail(f"expected 79 active source entries, got {active}")
    if "ZONLaunchTrace" in pbx_text:
        fail("trace header unexpectedly registered in PBX")

    main_text = (ROOT / "testmod/Bsphp/main.m").read_text(encoding="utf-8")
    ordered = [
        "ZONLaunchTraceMainLoadEnter",
        "ZONInstallAuthorizationResetExtension();",
        "ZONLaunchTraceAuthResetInstalled",
        "ZONBootstrapStart(^{",
        "ZONLaunchTraceBootstrapPreflightBegin",
        "[self tryLoadAppLovinSDK];",
        "ZONLaunchTraceAppLovinPreflightComplete",
        "[self UnityFramework];",
        "ZONLaunchTraceUnityPreflightComplete",
    ]
    pos = -1
    for marker in ordered:
        new = main_text.find(marker, pos + 1)
        if new < 0:
            fail(f"main launch ordering marker missing: {marker}")
        pos = new

    print("p46-contract: OK")


if __name__ == "__main__":
    main()
