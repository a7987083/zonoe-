#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
REMOTE_COORD = ROOT / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
LOCAL_COORD = ROOT / 'testmod/ZONServices/ZONLocalRestoreCoordinator.m'
PICKER_H = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h'
PICKER_M = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
API_H = ROOT / 'testmod/ZONServices/ZONRestoreAPI.h'
API_M = ROOT / 'testmod/ZONServices/ZONRestoreAPI.m'
PREF = ROOT / 'testmod/导入导出/PreferenceManager.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

pubg = PUBG.read_text(encoding='utf-8')
remote_coord = REMOTE_COORD.read_text(encoding='utf-8') if REMOTE_COORD.exists() else pubg
local_coord = LOCAL_COORD.read_text(encoding='utf-8') if LOCAL_COORD.exists() else PICKER_M.read_text(encoding='utf-8')
picker_h = PICKER_H.read_text(encoding='utf-8')
picker_m = PICKER_M.read_text(encoding='utf-8')
api_h = API_H.read_text(encoding='utf-8')
api_m = API_M.read_text(encoding='utf-8')
pref = PREF.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')

for marker in ['@interface ZONRestoreAPI', '+ (instancetype)sharedAPI;', 'restoreArchiveAtPath:', 'restorePreparedStagingAtPath:']:
    if marker not in api_h:
        raise SystemExit(f'missing restore API declaration: {marker}')

if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' not in api_m:
    raise SystemExit('restore API does not preserve the P66 post-success PreferenceManager tail')
if 'exit(0);' not in pref:
    raise SystemExit('PreferenceManager no longer contains the P66 post-restore exit behavior')

for marker in ['- (void)restorePreparedArchiveStaging;', '- (void)yidongwenjian;']:
    if marker not in picker_h:
        raise SystemExit(f'missing YYYPicker compatibility declaration: {marker}')
for marker in ['[ZONLocalRestoreCoordinator sharedCoordinator]', '[self restorePreparedArchiveStaging];']:
    if marker not in picker_m:
        raise SystemExit(f'missing YYYPicker local-restore compatibility shim marker: {marker}')
if 'ZONRestoreAPI' in picker_m or '[ZONRestoreService sharedService]' in picker_m:
    raise SystemExit('YYYPicker still owns or bypasses local restore execution')

for marker in ['#import "ZONRestoreAPI.h"', '[ZONRestoreAPI sharedAPI]', 'restoreArchiveAtPath:archivePath', 'restorePreparedStagingAtPath:stagingRoot']:
    if marker not in local_coord:
        raise SystemExit(f'local restore coordinator does not route through restore API: {marker}')
if '[ZONRestoreService sharedService]' in local_coord:
    raise SystemExit('local restore coordinator bypasses ZONRestoreAPI')
if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' in local_coord:
    raise SystemExit('local restore coordinator duplicates P66 post-restore lifecycle')

for marker in ['#import "ZONRestoreAPI.h"', '[ZONRestoreAPI sharedAPI]', 'restoreArchiveAtPath:archivePath']:
    if marker not in remote_coord:
        raise SystemExit(f'remote restore orchestration does not route through restore API: {marker}')
if '[ZONRestoreService sharedService]' in remote_coord:
    raise SystemExit('remote restore orchestration bypasses ZONRestoreAPI')
if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' in remote_coord:
    raise SystemExit('remote restore orchestration duplicates P66 post-restore lifecycle')

if pbx.count('ZONRestoreAPI.m in Sources') != 2:
    raise SystemExit('ZONRestoreAPI.m is not registered exactly once in PBX sources')

print('P67a restore API / yidongwenjian compatibility contract passed')
