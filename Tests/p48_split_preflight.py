#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "testmod/导入导出/fuhzu.m"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"
ROADMAP = ROOT / "ROADMAP.md"
DOC = ROOT / "P48_SPLIT_PREFLIGHT.md"

text = SRC.read_text()
pbx = PBX.read_text()
roadmap = ROADMAP.read_text()
doc = DOC.read_text()

required_selectors = [
    "checkbanben",
    "checkAppStoreVersionWithAppId:",
    "compareVersion:",
    "checkbanbencn",
    "checkAppStoreVersionWithAppIdcn:",
    "compareVersioncn:",
]

for selector in required_selectors:
    base = selector.rstrip(":")
    if base not in text:
        raise AssertionError(f"missing P48 selector candidate in fuhzu.m: {selector}")
    if selector not in doc:
        raise AssertionError(f"preflight doc missing selector: {selector}")

for protected in [
    "https://itunes.apple.com/lookup?bundleId=%@",
    "https://itunes.apple.com/cn/lookup?bundleId=%@",
    "服务器版本号",
    "应用名称",
    "下载地址",
    "最新版本日期",
    "游戏版本ID",
    "NSNumericSearch",
]:
    if protected not in text:
        raise AssertionError(f"protected version-check marker missing from fuhzu.m: {protected}")

if "ZONAppStoreVersionChecker.m" in pbx:
    raise AssertionError("P48 runtime implementation started before promotion gate")
if (ROOT / "testmod/ZONServices/ZONAppStoreVersionChecker.m").exists():
    raise AssertionError("P48 runtime TU exists before promotion gate")

if "P48 — Legacy God-Object Split #1" not in roadmap or "blocked until P46/P47 promotion" not in roadmap:
    raise AssertionError("ROADMAP no longer records the P48 promotion gate")

# Count only active Sources build phase references.
phase = re.search(r"/\* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/", pbx, re.S)
if not phase:
    raise AssertionError("PBXSourcesBuildPhase section missing")
source_members = sum(1 for line in phase.group(1).splitlines() if " in Sources */" in line)
if source_members != 79:
    raise AssertionError(f"active sources drift before P48 implementation: {source_members}")

print("p48-split-preflight: OK")
print("selected unit: testmod/导入导出/fuhzu.m")
print("selected responsibility: App Store version lookup/comparison")
print("runtime implementation: correctly blocked")
print("active PBX Sources: 79")
