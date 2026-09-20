#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / 'testmod/ZONCore/ZONFeatureRegistry.m'
DISPATCHER = ROOT / 'testmod/ZONCore/ZONFeatureDispatcher.m'
ACTION_M = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
RESET_H = ROOT / 'testmod/ZONServices/ZONGameDataResetService.h'
RESET_M = ROOT / 'testmod/ZONServices/ZONGameDataResetService.m'
AUTH_RESET_M = ROOT / 'testmod/ZONServices/ZONAuthorizationResetService.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
VERSION = ROOT / 'VERSION'

for path in (REGISTRY, DISPATCHER, ACTION_M, RESET_H, RESET_M, AUTH_RESET_M, PBX, VERSION):
    if not path.exists():
        raise SystemExit(f'missing required file: {path.relative_to(ROOT)}')

registry = REGISTRY.read_text(encoding='utf-8')
dispatcher = DISPATCHER.read_text(encoding='utf-8')
action = ACTION_M.read_text(encoding='utf-8')
reset_h = RESET_H.read_text(encoding='utf-8')
reset_m = RESET_M.read_text(encoding='utf-8')
auth_reset = AUTH_RESET_M.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')
version = VERSION.read_text(encoding='utf-8').strip()

if version != 'v1_p64a':
    raise SystemExit(f'unexpected VERSION: {version}')

expected_actions = {
    'base.remote-download': 1,
    'base.cloud-save': 2,
    'base.local-files': 3,
    'data.backup-save': 100,
    'data.restore-save': 101,
    'data.clear-game-data': 102,
    'auth.clear-records': 103,
}
for identifier, tag in expected_actions.items():
    if not re.search(rf'@"{re.escape(identifier)}".*?ZONFeatureLegacyTagKey:@{tag}\b', registry):
        raise SystemExit(f'registry identifier/tag drift: {identifier} -> {tag}')

service_routes = {
    'base.remote-download': 'performRemoteDownloadFromViewController:',
    'base.cloud-save': 'performCloudSaveFromViewController:',
    'data.backup-save': 'performBackupSaveFromViewController:',
    'data.restore-save': 'performRestoreSaveFromViewController:',
    'data.clear-game-data': 'performClearGameDataFromViewController:',
    'auth.clear-records': 'performClearAuthorizationFromViewController:',
}
for identifier, selector in service_routes.items():
    pattern = rf'@"{re.escape(identifier)}"\s*:\s*\^BOOL\([^)]*\)\s*\{{[^}}]*ZONSixButtonActionService {re.escape(selector)}'
    if not re.search(pattern, dispatcher, re.S):
        raise SystemExit(f'dispatcher route drift: {identifier}')

for forbidden in (
    '#import "PubgLoad.h"', '#import "daochucd.h"', '#import "YYYPicker.h"',
    '#import "WX_NongShiFu123.h"', '#import "SVProgressHUD.h"'
):
    if forbidden in dispatcher:
        raise SystemExit(f'legacy dependency leaked back into dispatcher: {forbidden}')

for marker in (
    'ZONGameDataResetStagePreparing', 'ZONGameDataResetStageDocuments',
    'ZONGameDataResetStageLibrary', 'ZONGameDataResetStageTemporary',
    'ZONGameDataResetStagePreferences', 'ZONGameDataResetStageVerification',
    'ZONGameDataResetStageCompleted', 'resetGameDataWithProgress:'
):
    if marker not in reset_h:
        raise SystemExit(f'missing reset service contract marker: {marker}')

for marker in (
    'clearDirectoryContentsAtPath:',
    'allowRuntimeResidue:',
    'directoryContainsPayloadAtPath:',
    'verifyPayloadClearedAtPath:',
    'isDirectoryEmptyAtPath:',
    'isEqualToString:@"Caches"',
    '保留运行期空目录',
    '运行期目录被系统/框架重新占用',
    'removePersistentDomainForName:bundleIdentifier',
    'persistentDomainForName:bundleIdentifier',
    '[home stringByAppendingPathComponent:@"Documents"]',
    '[home stringByAppendingPathComponent:@"Library"]',
    '[home stringByAppendingPathComponent:@"tmp"]',
):
    if marker not in reset_m:
        raise SystemExit(f'missing P64a reset marker: {marker}')

for forbidden in (
    'verifyDirectoryIsEmptyAtPath:',
    'dispatch_after', 'NSEC_PER_SEC', 'SVProgressHUD', '#import <UIKit/UIKit.h>',
    'ZONAuthorizationResetService', 'getKeychain', 'ZONKeychain'
):
    if forbidden in reset_m:
        raise SystemExit(f'P64a reset engine contains forbidden dependency/old behavior: {forbidden}')

for marker in (
    '#import "ZONGameDataResetService.h"', 'QOS_CLASS_USER_INITIATED',
    '正在准备清理…', '正在清理游戏存档…', '正在清理游戏数据…',
    '正在清理临时文件…', '正在重置本地设置…', '正在检查清理结果…',
    '清理完成，正在退出…', '[ZONGameDataResetService resetGameDataWithProgress:',
    'if (success)', 'exit(0);', 'showErrorWithStatus:'
):
    if marker not in action:
        raise SystemExit(f'missing staged clear-game-data UI marker: {marker}')

if '(int64_t)(5 * NSEC_PER_SEC)' in action:
    raise SystemExit('legacy five-second clear-game-data delay still present')
if '(int64_t)(3 * NSEC_PER_SEC)' not in action:
    raise SystemExit('authorization action timing changed unexpectedly')

for marker in ('SJUSERID', 'ShiSanGeDZKM', 'rjyyz', 'DZUDID', 'zonoe.udid.bridge.value', 'com.china.TestKeyChain'):
    if marker not in auth_reset:
        raise SystemExit(f'authorization reset contract drift: {marker}')

# Existing P64 service PBX membership remains authoritative; P64a changes behavior only.
build_id = 'B63B00012F7B300100C0FFEE'
file_id = 'B63B00022F7B300100C0FFEE'
source_marker = 'ZONGameDataResetService.m in Sources'
file_marker = 'ZONGameDataResetService.m'
if pbx.count(source_marker) != 2:
    raise SystemExit(f'expected exactly 2 reset service source markers, found {pbx.count(source_marker)}')
if f'{build_id} /* {source_marker} */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_marker} */; }};' not in pbx:
    raise SystemExit('reset service PBXBuildFile declaration missing')
if f'{build_id} /* {source_marker} */,' not in pbx:
    raise SystemExit('reset service missing from PBXSourcesBuildPhase')

print('P64A_RUNTIME_DIRECTORY_RESET_CONTRACT=PASS')
print('EMPTY_RUNTIME_DIRECTORIES_ALLOWED=true')
print('CACHE_RUNTIME_RESIDUE_TOLERATED=true')
print('BUSINESS_PAYLOAD_STILL_VERIFIED=true')
print('NO_FIXED_CLEAR_DELAY=true')
print('STAGED_PROGRESS=true')
print('AUTHORIZATION_STORAGE_OUT_OF_SCOPE=true')
