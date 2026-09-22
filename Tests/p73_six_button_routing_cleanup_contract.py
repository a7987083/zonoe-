from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
six_h = (root / 'testmod/ZONServices/ZONSixButtonActionService.h').read_text()
six_m = (root / 'testmod/ZONServices/ZONSixButtonActionService.m').read_text()
dispatcher = (root / 'testmod/ZONCore/ZONFeatureDispatcher.m').read_text()
transfer = (root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m').read_text()
runtime_h = (root / 'testmod/ZONServices/ZONRuntimeDirectoryService.h').read_text()
runtime_m = (root / 'testmod/ZONServices/ZONRuntimeDirectoryService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version == 'v1_p73', f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONRuntimeDirectoryService',
    '+ (NSString *)temporaryDirectoryPath;',
    '+ (BOOL)ensureTemporaryDirectory;',
]:
    assert marker in runtime_h, f'missing runtime directory API marker: {marker}'

for marker in [
    'NSHomeDirectory()',
    'stringByAppendingPathComponent:@"tmp"',
    'NSFileManager.defaultManager',
    'fileExistsAtPath:',
    'createDirectoryAtPath:',
    'withIntermediateDirectories:YES',
]:
    assert marker in runtime_m, f'missing runtime directory behavior marker: {marker}'

for forbidden in ['UIKit', 'UIAlertController', 'SVProgressHUD', 'ZONResetCoordinator']:
    assert forbidden not in runtime_m, f'runtime directory service gained unrelated dependency: {forbidden}'

# SixButton keeps its historical Objective-C compatibility selectors, but they are now thin forwarders.
for marker in [
    '#import "ZONRuntimeDirectoryService.h"',
    'return [ZONRuntimeDirectoryService temporaryDirectoryPath];',
    'return [ZONRuntimeDirectoryService ensureTemporaryDirectory];',
    '[[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];',
]:
    assert marker in six_m, f'missing SixButton compatibility forwarder: {marker}'

for forbidden in [
    'NSFileManager', 'NSHomeDirectory()', 'createDirectoryAtPath:', 'fileExistsAtPath:',
    'stringByAppendingPathComponent:@"tmp"',
]:
    assert forbidden not in six_m, f'SixButton still owns filesystem implementation: {forbidden}'

# The six primary actions remain routed through explicit coordinators.
for marker in [
    'presentRemoteDownloadFromViewController:hostViewController',
    'presentCloudSaveFromViewController:hostViewController',
    'presentBackupFromViewController:hostViewController',
    'presentLocalRestoreFromViewController:hostViewController',
    'presentClearGameDataFromViewController:hostViewController',
    'presentClearAuthorizationFromViewController:hostViewController',
]:
    assert marker in six_m, f'missing SixButton action route: {marker}'

# C compatibility functions no longer route tmp/reset helpers through SixButton.
for marker in [
    '#import "../ZONServices/ZONRuntimeDirectoryService.h"',
    '#import "../ZONServices/ZONResetCoordinator.h"',
    'return [ZONRuntimeDirectoryService temporaryDirectoryPath];',
    'return [ZONRuntimeDirectoryService ensureTemporaryDirectory];',
    '[[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];',
    '[[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];',
    '[[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];',
]:
    assert marker in dispatcher, f'missing dispatcher compatibility boundary marker: {marker}'

for forbidden in [
    '[ZONSixButtonActionService temporaryDirectoryPath]',
    '[ZONSixButtonActionService ensureTemporaryDirectory]',
    '[ZONSixButtonActionService clearGameDataPreservingTemporaryDirectory]',
]:
    assert forbidden not in dispatcher, f'dispatcher still routes compatibility helper through SixButton: {forbidden}'

# Cloud-save keeps the historical tmp-preparation behavior, now at the save-transfer boundary.
for marker in [
    '#import "ZONRuntimeDirectoryService.h"',
    '- (void)presentCloudSaveFromViewController:',
    '[ZONRuntimeDirectoryService ensureTemporaryDirectory];',
]:
    assert marker in transfer, f'missing cloud tmp-preparation marker: {marker}'

assert '[self ensureTemporaryDirectory];' not in six_m
assert 'temporaryDirectoryPath' in six_h
assert 'ensureTemporaryDirectory' in six_h
assert 'clearGameDataPreservingTemporaryDirectory' in six_h
assert pbx.count('ZONRuntimeDirectoryService.m in Sources') == 2

print('P73 six-button routing cleanup contract: PASS')
