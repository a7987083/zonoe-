#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = "e87b683a9c868e00d13582c8145bb9368878fee3"
MAIN = ROOT / "testmod/Bsphp/main.m"
COORD = ROOT / "testmod/ZONServices/ZONAuthorizationCoordinator.m"
HEADER = ROOT / "testmod/ZONServices/ZONAuthorizationCoordinator.h"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
START = "#pragma mark - Authorization reset compatibility\n"
END = "@implementation NSObject (mian)\n"
IMPORT = '#import "../ZONServices/ZONAuthorizationCoordinator.h"\n'


def die(msg):
    raise SystemExit(f"p44-contract: FAIL: {msg}")


def git_show(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT, text=True)


def extract(text):
    if START not in text or END not in text:
        die("baseline authorization block markers missing")
    return text[text.index(START):text.index(END)]


def main():
    if (ROOT / "VERSION").read_text().strip() != "v1_p44":
        die("VERSION is not v1_p44")

    old_main = git_show("testmod/Bsphp/main.m")
    new_main = MAIN.read_text()
    coord = COORD.read_text()
    header = HEADER.read_text()
    pbx = PBX.read_text()

    old_block = extract(old_main)
    expected = old_block.replace(
        "static void ZONInstallAuthorizationResetExtension(void)",
        "void ZONInstallAuthorizationResetExtension(void)", 1,
    ).replace(
        "static void ZONStartCustomerAuthorization(void)",
        "void ZONStartCustomerAuthorization(void)", 1,
    )
    marker = START
    if marker not in coord:
        die("coordinator missing moved block")
    actual = coord[coord.index(marker):]
    if actual != expected:
        die("moved authorization block is not mechanically equivalent to P42")

    expected_main = old_main.replace(old_block, "", 1)
    anchor = '#import "../ZONServices/ZonoeUDIDAPI.h"\n'
    expected_main = expected_main.replace(anchor, anchor + IMPORT, 1)
    if new_main != expected_main:
        die("main.m changed outside mechanical block removal/import insertion")

    for symbol in ["ZONInstallAuthorizationResetExtension", "ZONStartCustomerAuthorization"]:
        if symbol not in header:
            die(f"header missing {symbol}")
    for forbidden in ["ZONClearStoredUDIDState", "ZONContinueCustomerAuthorization", "gZONOriginalDeleteKM"]:
        if forbidden in header:
            die(f"private coordinator detail leaked in header: {forbidden}")

    if pbx.count("ZONAuthorizationCoordinator.m in Sources") != 2:
        die("PBX coordinator Sources registration count mismatch")
    source_entries = [line for line in pbx.splitlines() if " in Sources */," in line]
    if len(source_entries) != 78:
        die(f"expected 78 active Sources, found {len(source_entries)}")

    protected = [
        "testmod/Bsphp/WX_NongShiFu123.mm",
        "testmod/ZONServices/ZonoeUDIDAPI.m",
        "testmod/ZONServices/ZONUDIDBridge.m",
        "testmod/ZONBootstrap/ZONBootstrap.m",
        "testmod/ZONCore/ZONModuleLoader.m",
        "testmod/工具箱/Hook/JiangHuHook.m",
        "testmod/菜单/PubgLoad.mm",
    ]
    for path in protected:
        if subprocess.check_output(["git", "diff", "--name-only", BASE, "HEAD", "--", path], cwd=ROOT, text=True).strip():
            die(f"protected runtime file changed: {path}")

    print("p44-contract: OK")


if __name__ == "__main__":
    main()
