#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTION_M = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
RESET_H = ROOT / 'testmod/ZONServices/ZONGameDataResetService.h'
RESET_M = ROOT / 'testmod/ZONServices/ZONGameDataResetService.m'
AUTH_RESET_M = ROOT / 'testmod/ZONServices/ZONAuthorizationResetService.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
VERSION = ROOT / 'VERSION'

for path in (ACTION_M, RESET_H, RESET_M, AUTH_RESET_M, PBX, VERSION):
    if not path.exists():
        raise SystemExit(f'missing required file: {path.relative_to(ROOT)}')

action = ACTION_M.read_text(encoding='utf-8')
reset_h = RESET_H.read_text(encoding='utf-8')
reset_m = RESET_M.read_text(encoding='utf-8')
auth_reset = AUTH_RESET_M.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')
version = VERSION.read_text(encoding='utf-8').strip()

if version != 'v1_p63b':
    raise SystemExit(f'unexpected VERSION: {version}')

for marker in (
    'ZONGameDataResetStagePreparing',
    'ZONGameDataResetStageDocuments',
    'ZONGameDataResetStageLibrary',
    'ZONGameDataResetStageTemporary',
    'ZONGameDataResetStagePreferences',
    'ZONGameDataResetStageVerification',
    'ZONGameDataResetStageCompleted',
    'resetGameDataWithProgress:',
):
    if marker not in reset_h:
        raise SystemExit(f'missing reset service contract marker: {marker}')

for marker in (
    '[home stringByAppendingPathComponent:@"Documents"]',
    '[home stringByAppendingPathComponent:@"Library"]',
    '[home stringByAppendingPathComponent:@"tmp"]',
    'removePersistentDomainForName:bundleIdentifier',
    'persistentDomainForName:bundleIdentifier',
    'verifyDirectoryIsEmptyAtPath:',
    'clearContentsOfDirectoryAtPath:',
    'NSFileNoSuchFileError',
):
    if marker not in reset_m:
        raise SystemExit(f'missing reset implementation marker: {marker}')

for forbidden in (
    'dispatch_after',
    'NSEC_PER_SEC',
    'SVProgressHUD',
    '#import <UIKit/UIKit.h>',
    'ZONAuthorizationResetService',
    'getKeychain',
    'ZONKeychain',
):
    if forbidden in reset_m:
        raise SystemExit(f'reset engine contains forbidden dependency/behavior: {forbidden}')

for marker in (
    '#import "ZONGameDataResetService.h"',
    'QOS_CLASS_USER_INITIATED',
    '正在准备清理…',
    '正在清理游戏存档…',
    '正在清理游戏数据…',
    '正在清理临时文件…',
    '正在重置本地设置…',
    '正在检查清理结果…',
    '清理完成，正在退出…',
    '[ZONGameDataResetService resetGameDataWithProgress:',
    'if (success)',
    'exit(0);',
    'showErrorWithStatus:',
):
    if marker not in action:
        raise SystemExit(f'missing staged clear-game-data UI marker: {marker}')

# Clear-game-data must not retain the old fixed five-second timing.
if '(int64_t)(5 * NSEC_PER_SEC)' in action:
    raise SystemExit('legacy five-second clear-game-data delay still present')

# Authorization reset remains independently scoped and retains its P62 clear set.
for marker in ('SJUSERID', 'ShiSanGeDZKM', 'rjyyz', 'DZUDID', 'zonoe.udid.bridge.value', 'com.china.TestKeyChain'):
    if marker not in auth_reset:
        raise SystemExit(f'authorization reset contract drift: {marker}')

build_id = 'B63B00012F7B300100C0FFEE'
file_id = 'B63B00022F7B300100C0FFEE'
marker = 'ZONGameDataResetService.m in Sources'
file_marker = 'ZONGameDataResetService.m'
if pbx.count(marker) != 2:
    raise SystemExit(f'expected exactly 2 P63B source markers, found {pbx.count(marker)}')
if f'{build_id} /* {marker} */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_marker} */; }};' not in pbx:
    raise SystemExit('P63B PBXBuildFile declaration missing')
if f'{build_id} /* {marker} */,' not in pbx:
    raise SystemExit('P63B source missing from PBXSourcesBuildPhase')
if f'{file_id} /* {file_marker} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc;' not in pbx:
    raise SystemExit('P63B PBXFileReference missing')

print('P63B_GAME_DATA_RESET_CONTRACT=PASS')
print('NO_FIXED_CLEAR_DELAY=true')
print('STAGED_PROGRESS=true')
print('BACKGROUND_RESET=true')
print('SUCCESS_EXITS_IMMEDIATELY=true')
print('FAILURE_DOES_NOT_EXIT=true')
print('AUTHORIZATION_STORAGE_OUT_OF_SCOPE=true')
