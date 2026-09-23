from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
six = (root / 'testmod/ZONServices/ZONSixButtonActionService.m').read_text()
picker_h = (root / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h').read_text()
picker_m = (root / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m').read_text()
coord_h = (root / 'testmod/ZONServices/ZONLocalRestoreCoordinator.h').read_text()
coord_m = (root / 'testmod/ZONServices/ZONLocalRestoreCoordinator.m').read_text()
api_h = (root / 'testmod/ZONServices/ZONRestoreAPI.h').read_text()
api_m = (root / 'testmod/ZONServices/ZONRestoreAPI.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version in {'v1_p71', 'v1_p72', 'v1_p73', 'v1_p74', 'v1_p76', 'v1_p77'}, f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONLocalRestoreCoordinator',
    '+ (instancetype)sharedCoordinator;',
    'presentLocalRestoreFromViewController:',
    'selectionHandler:',
    'restorePreparedArchiveStaging',
]:
    assert marker in coord_h, f'missing P71 coordinator API marker: {marker}'

for marker in [
    '#import "NKSeleDocumentTool.h"',
    '#import "SVProgressHUD.h"',
    '#import "ZONRestoreAPI.h"',
    'seleDocumentWithDocumentTypes:@[@"public.data"]',
    'UIDocumentPickerModeImport',
    '(int64_t)(1 * NSEC_PER_SEC)',
    'controller:hostViewController',
    'restoreInboxPathForBundleIdentifier:',
    'restoreArchiveAtPath:archivePath',
    'restorePreparedStagingAtPath:stagingRoot',
    '@"处理中..."',
    '@"恢复失败"',
    '@"恢复完成"',
    'ZONRestoreErrorCleanupFailed',
]:
    assert marker in coord_m, f'missing P71 coordinator behavior marker: {marker}'

for marker in [
    '#import "ZONLocalRestoreCoordinator.h"',
    '[ZONLocalRestoreCoordinator sharedCoordinator]',
    'presentLocalRestoreFromViewController:hostViewController',
]:
    assert marker in six, f'missing P71 six-button route: {marker}'

assert '#import "YYYPicker.h"' not in six
assert '[[YYYPicker alloc] addBtnAction]' not in six

for marker in [
    '- (void)addBtnAction;',
    '- (void)restorePreparedArchiveStaging;',
    '- (void)yidongwenjian;',
]:
    assert marker in picker_h, f'missing YYYPicker compatibility declaration: {marker}'

for marker in [
    '#import "ZONLocalRestoreCoordinator.h"',
    '[ZONLocalRestoreCoordinator sharedCoordinator]',
    'selectionHandler:',
    '[self restorePreparedArchiveStaging];',
]:
    assert marker in picker_m, f'missing YYYPicker compatibility shim marker: {marker}'

for forbidden in [
    'ZONRestoreAPI',
    'NKSeleDocumentTool',
    'SVProgressHUD',
    'restoreArchiveAtPath:',
    'restoreInboxPathForBundleIdentifier:',
    'restorePreparedStagingAtPath:',
]:
    assert forbidden not in picker_m, f'YYYPicker still owns local restore orchestration: {forbidden}'

for marker in [
    '@interface ZONRestoreAPI',
    'restoreArchiveAtPath:',
    'restorePreparedStagingAtPath:',
]:
    assert marker in api_h, f'missing restore API marker: {marker}'
assert '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' in api_m
assert '[ZONRestoreService sharedService]' not in coord_m
assert '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' not in coord_m
assert pbx.count('ZONLocalRestoreCoordinator.m in Sources') == 2

print('P71 local restore coordinator contract: PASS')
