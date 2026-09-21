#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
PICKER_H = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h'
PICKER_M = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
API_H = ROOT / 'testmod/ZONServices/ZONRestoreAPI.h'
API_M = ROOT / 'testmod/ZONServices/ZONRestoreAPI.m'
PREF = ROOT / 'testmod/导入导出/PreferenceManager.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

pubg = PUBG.read_text(encoding='utf-8')
picker_h = PICKER_H.read_text(encoding='utf-8')
picker_m = PICKER_M.read_text(encoding='utf-8')
api_h = API_H.read_text(encoding='utf-8')
api_m = API_M.read_text(encoding='utf-8')
pref = PREF.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')

for marker in [
    '@interface ZONRestoreAPI',
    '+ (instancetype)sharedAPI;',
    'restoreArchiveAtPath:',
    'restorePreparedStagingAtPath:',
]:
    if marker not in api_h:
        raise SystemExit(f'missing restore API declaration: {marker}')

if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' not in api_m:
    raise SystemExit('restore API does not preserve the P66 post-success PreferenceManager tail')
if 'exit(0);' not in pref:
    raise SystemExit('PreferenceManager no longer contains the P66 post-restore exit behavior')

for marker in [
    '- (void)restorePreparedArchiveStaging;',
    '- (void)yidongwenjian;',
]:
    if marker not in picker_h:
        raise SystemExit(f'missing YYYPicker compatibility declaration: {marker}')

for marker in [
    '[ZONRestoreAPI sharedAPI]',
    '[self restorePreparedArchiveStaging];',
]:
    if marker not in picker_m:
        raise SystemExit(f'missing YYYPicker restore API shim marker: {marker}')

if '[ZONRestoreService sharedService]' in picker_m:
    raise SystemExit('YYYPicker bypasses ZONRestoreAPI and directly calls ZONRestoreService')
if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' in picker_m:
    raise SystemExit('YYYPicker duplicates the post-restore lifecycle instead of using ZONRestoreAPI')

for marker in [
    '#import "ZONRestoreAPI.h"',
    '[ZONRestoreAPI sharedAPI]',
    'restoreArchiveAtPath:archivePath',
]:
    if marker not in pubg:
        raise SystemExit(f'PubgLoad does not route through restore API: {marker}')

start = '#pragma mark - P67 remote download orchestration'
end = '- (BOOL)isCloudEntitlementValidWithCode:'
if start not in pubg or end not in pubg:
    raise SystemExit('P67 remote restore block markers missing')
remote_block = pubg.split(start, 1)[1].split(end, 1)[0]

if '[ZONRestoreService sharedService]' in remote_block:
    raise SystemExit('P67 remote restore block bypasses ZONRestoreAPI')
if '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' in remote_block:
    raise SystemExit('P67 remote restore block duplicates P66 post-restore lifecycle')
if 'exit(0);' in remote_block:
    raise SystemExit('P67 remote restore block duplicates direct process termination')

if pbx.count('ZONRestoreAPI.m in Sources') != 2:
    raise SystemExit('ZONRestoreAPI.m is not registered exactly once in PBX sources')

print('P67a restore API / yidongwenjian compatibility contract passed')
