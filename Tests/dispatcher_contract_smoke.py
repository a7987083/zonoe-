#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
HEADER = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.h").read_text()
IMPL = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.m").read_text()
EVENT = (ROOT / "testmod/ZONCore/ZONMenuEventBridge.m").read_text()
PBX = (ROOT / "testmod.xcodeproj/project.pbxproj").read_text()


def fail(msg: str) -> None:
    print(f"dispatcher-contract: FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


if "static inline" in HEADER:
    fail("header still contains inline implementation")
if '#import "ZONFeatureDispatcher.m"' in EVENT:
    fail("EventBridge must not import implementation")
require(EVENT, '#import "ZONFeatureDispatcher.h"', "EventBridge header import")
require(PBX, "ZONFeatureDispatcher.m in Sources", "Dispatcher PBX source registration")

for declaration in [
    "NSString *ZONTmpDirectoryPath(void);",
    "BOOL ZONEnsureTmpDirectory(void);",
    "void ZONClearGameDataPreservingTmp(void);",
    "void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController);",
    "void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController);",
    "BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,",
    "BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on);",
]:
    require(HEADER, declaration, "Dispatcher declaration")

for definition in [
    "NSString *ZONTmpDirectoryPath(void)",
    "BOOL ZONEnsureTmpDirectory(void)",
    "void ZONClearGameDataPreservingTmp(void)",
    "void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)",
    "void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)",
    "BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,",
    "BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)",
]:
    require(IMPL, definition, "Dispatcher definition")

for needle in [
    '@"base.remote-download"', '[[PubgLoad alloc] yuanchengdwon];',
    '@"base.cloud-save"', '[[PubgLoad alloc] checkCloudSaveStatus];',
    '@"base.local-files"', 'SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];',
    '@"data.backup-save"', '[[daochucd alloc] backupasd];',
    '@"data.restore-save"', '[[YYYPicker alloc] addBtnAction];',
    '@"data.clear-game-data"', 'ZONPresentClearGameDataConfirmation(hostViewController);',
    '@"auth.clear-records"', 'ZONPresentClearAuthorizationConfirmation(hostViewController);',
    '[[WX_NongShiFu123 alloc] deletekm];',
    'forKey:@"NNGG"', 'forKey:@"NNGGNNGG"', '[ImgTool share].NeiGou = on;',
    'forKey:@"AADD"', 'forKey:@"AADDAADD"', '[ImgTool share].ADSpeed = on;',
    '@"runtime.placeholder-203"', 'NSLog(@"人物血量");',
]:
    require(IMPL, needle, "Dispatcher contract marker")

if IMPL.count("exit(0);") != 2:
    fail(f"expected two delayed exits, found {IMPL.count('exit(0);')}")

for needle in ['@"NNGGNNGG"', '@"AADDAADD"', '@"AADDssppeedd"',
               '[ImgTool share].NeiGou', '[ImgTool share].ADSpeed', '[ImgTool share].ADBiansu']:
    require(EVENT, needle, "EventBridge runtime sync marker")

print("dispatcher-contract: PASS")
