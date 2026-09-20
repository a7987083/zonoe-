#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / 'testmod/ZONCore/ZONFeatureRegistry.m'
DISPATCHER = ROOT / 'testmod/ZONCore/ZONFeatureDispatcher.m'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
RESET_M = ROOT / 'testmod/ZONServices/ZONAuthorizationResetService.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

for path in (REGISTRY, DISPATCHER, SERVICE_H, SERVICE_M, RESET_M, PBX):
    if not path.exists():
        raise SystemExit(f'missing required file: {path.relative_to(ROOT)}')

registry = REGISTRY.read_text(encoding='utf-8')
dispatcher = DISPATCHER.read_text(encoding='utf-8')
service_h = SERVICE_H.read_text(encoding='utf-8')
service_m = SERVICE_M.read_text(encoding='utf-8')
reset_m = RESET_M.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')

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

if '#import "../ZONServices/ZONSixButtonActionService.h"' not in dispatcher:
    raise SystemExit('dispatcher does not import six-button service boundary')

for identifier, selector in service_routes.items():
    pattern = rf'@"{re.escape(identifier)}"\s*:\s*\^BOOL\([^)]*\)\s*\{{[^}}]*ZONSixButtonActionService {re.escape(selector)}'
    if not re.search(pattern, dispatcher, re.S):
        raise SystemExit(f'dispatcher route does not use service boundary: {identifier}')

for forbidden in (
    '#import "PubgLoad.h"',
    '#import "daochucd.h"',
    '#import "YYYPicker.h"',
    '#import "WX_NongShiFu123.h"',
    '#import "SVProgressHUD.h"',
    '[[PubgLoad alloc] yuanchengdwon]',
    '[[PubgLoad alloc] checkCloudSaveStatus]',
    '[[daochucd alloc] backupasd]',
    '[[YYYPicker alloc] addBtnAction]',
    '[[WX_NongShiFu123 alloc] deletekm]',
):
    if forbidden in dispatcher:
        raise SystemExit(f'legacy six-button dependency leaked back into dispatcher: {forbidden}')

required_header_selectors = list(service_routes.values()) + [
    'temporaryDirectoryPath',
    'ensureTemporaryDirectory',
    'clearGameDataPreservingTemporaryDirectory',
]
for selector in required_header_selectors:
    if selector not in service_h:
        raise SystemExit(f'missing service API: {selector}')

required_service_markers = [
    '[[PubgLoad alloc] yuanchengdwon]',
    '[[PubgLoad alloc] checkCloudSaveStatus]',
    '[[daochucd alloc] backupasd]',
    '[[YYYPicker alloc] addBtnAction]',
    '@"清除游戏数据"',
    '@"此操作会清除本地游戏数据，且不可恢复.\\n确定要继续吗？"'.replace('.', '。'),
    '@"清除授权记录"',
    '@"此操作会删除授权信息，删除后需要重新授权。\\n确定继续吗？"',
    '[SVProgressHUD showWithStatus:@"处理中..."]',
    '[ZONAuthorizationResetService clearAuthorizationData:&error]',
    '(int64_t)(5 * NSEC_PER_SEC)',
    '(int64_t)(3 * NSEC_PER_SEC)',
    'removePersistentDomainForName:appDomain',
    '[self ensureTemporaryDirectory]',
]
for marker in required_service_markers:
    if marker not in service_m:
        raise SystemExit(f'service behavior marker missing: {marker}')

for reset_key in ('SJUSERID', 'ShiSanGeDZKM', 'rjyyz', 'DZUDID', 'zonoe.udid.bridge.value', 'com.china.TestKeyChain'):
    if reset_key not in reset_m:
        raise SystemExit(f'P62 reset contract drift: {reset_key}')

build_id = 'B63A00012F7B200100C0FFEE'
file_id = 'B63A00022F7B200100C0FFEE'
marker = 'ZONSixButtonActionService.m in Sources'
file_marker = 'ZONSixButtonActionService.m'
if pbx.count(marker) != 2:
    raise SystemExit(f'expected exactly 2 P63A source markers, found {pbx.count(marker)}')
if f'{build_id} /* {marker} */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_marker} */; }};' not in pbx:
    raise SystemExit('P63A PBXBuildFile declaration missing')
if f'{build_id} /* {marker} */,' not in pbx:
    raise SystemExit('P63A service missing from PBXSourcesBuildPhase')
if f'{file_id} /* {file_marker} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc;' not in pbx:
    raise SystemExit('P63A PBXFileReference missing')

print('P63A_SIX_BUTTON_SERVICE_BOUNDARY_CONTRACT=PASS')
print('SIX_SCOPED_ACTIONS_ROUTE_THROUGH_SERVICE=true')
print('LEGACY_DISPATCHER_DEPENDENCIES_REMOVED=true')
print('P62_RESET_CONTRACT_PRESERVED=true')
