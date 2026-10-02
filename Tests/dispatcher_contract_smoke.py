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


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"unexpected {label}: {needle}")


# Translation-unit ownership must stay explicit.
forbid(HEADER, "static inline", "header implementation")
forbid(EVENT, '#import "ZONFeatureDispatcher.m"', "implementation import")
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

# Current action ownership: Dispatcher routes identifiers to service boundaries.
for needle in [
    '@"base.remote-download"',
    '[ZONSixButtonActionService performRemoteDownloadFromViewController:host]',
    '@"base.cloud-save"',
    '[ZONSixButtonActionService performCloudSaveFromViewController:host]',
    '@"base.modifier"',
    '[ZONSixButtonActionService performModifierFromViewController:host]',
    '@"base.local-files"',
    '[[ZONLocalFilesCoordinator sharedCoordinator] presentLocalFilesFromViewController:host]',
    '@"data.backup-save"',
    '[ZONSixButtonActionService performBackupSaveFromViewController:host]',
    '@"data.restore-save"',
    '[ZONSixButtonActionService performRestoreSaveFromViewController:host]',
    '@"data.clear-game-data"',
    '[ZONSixButtonActionService performClearGameDataFromViewController:host]',
    '@"auth.clear-records"',
    '[ZONSixButtonActionService performClearAuthorizationFromViewController:host]',
]:
    require(IMPL, needle, "current action route")

# Retired direct legacy handlers must not re-enter Dispatcher.
for needle in [
    '[[PubgLoad alloc] yuanchengdwon]',
    '[[PubgLoad alloc] checkCloudSaveStatus]',
    '[[daochucd alloc] backupasd]',
    '[[YYYPicker alloc] addBtnAction]',
    '[[WX_NongShiFu123 alloc] deletekm]',
]:
    forbid(IMPL, needle, "retired direct handler")

# Runtime toggle persistence and side effects are intentionally preserved.
for needle in [
    '@"runtime.iap-noads"', '@"NNGG", @"NNGGNNGG", on',
    '[ImgTool share].NeiGou = enabled;',
    '@"runtime.ad-speed"', '@"AADD", @"AADDAADD", on',
    '[ImgTool share].ADSpeed = enabled;',
    '[defaults synchronize];',
]:
    require(IMPL, needle, "runtime toggle contract")

# EventBridge remains the restore/sync owner for persisted runtime settings.
for needle in [
    '@"NNGGNNGG"', '@"AADDAADD"', '@"AADDssppeedd"',
    '[ImgTool share].NeiGou', '[ImgTool share].ADSpeed', '[ImgTool share].ADBiansu',
]:
    require(EVENT, needle, "EventBridge runtime sync marker")

forbid(IMPL, "runtime.placeholder-203", "retired tag-203 route")
forbid(IMPL, "人物血量", "retired tag-203 placeholder")

print("dispatcher-contract: PASS")
