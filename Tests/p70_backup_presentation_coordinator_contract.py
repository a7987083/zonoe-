from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
six = (root / 'testmod/ZONServices/ZONSixButtonActionService.m').read_text()
legacy = (root / 'testmod/导入导出/daochucd.m').read_text()
coord_h = (root / 'testmod/ZONServices/ZONBackupCoordinator.h').read_text()
coord_m = (root / 'testmod/ZONServices/ZONBackupCoordinator.m').read_text()
service_h = (root / 'testmod/ZONServices/ZONBackupService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONBackupService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version in {'v1_p70', 'v1_p71', 'v1_p72'}, f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONBackupCoordinator', '+ (instancetype)sharedCoordinator;', 'presentBackupFromViewController:',
]:
    assert marker in coord_h, f'missing P70 coordinator API marker: {marker}'

for marker in [
    '#import "ZONBackupService.h"', 'createBackupNamed:', 'largeItemDecision:',
    'requestBackupDecisionForRelativePath:', 'ZONBackupStagePreparing', 'ZONBackupStageScanning',
    'ZONBackupStageCopyingDocuments', 'ZONBackupStageCopyingLibrary', 'ZONBackupStageArchiving',
    '@"请输入文件名字\\n直接确定是BundID名字"', '@"备份完成"', 'UIDocumentInteractionController',
    'presentOptionsMenuFromRect:', 'cleanupBackupArtifacts', '@"Documents/zonoe"', '@"tmp/zonoe"',
]:
    assert marker in coord_m, f'missing P70 coordinator behavior marker: {marker}'

for marker in ['#import "ZONBackupCoordinator.h"', '[ZONBackupCoordinator sharedCoordinator]', 'presentBackupFromViewController:hostViewController']:
    assert marker in six, f'missing six-button P70 route: {marker}'

assert '#import "daochucd.h"' not in six
assert '[[daochucd alloc] backupasd]' not in six

for marker in ['#import "ZONBackupCoordinator.h"', '[JHPP currentViewController]', '[ZONBackupCoordinator sharedCoordinator]', 'presentBackupFromViewController:host']:
    assert marker in legacy, f'missing legacy backup shim marker: {marker}'

for forbidden in ['ZONBackupService', 'SVProgressHUD', 'UIDocumentInteractionController', 'createBackupNamed:', 'requestBackupDecisionForRelativePath:', 'cleanupBackupArtifacts', 'Documents/zonoe', 'tmp/zonoe']:
    assert forbidden not in legacy, f'daochucd still owns backup orchestration: {forbidden}'

for forbidden in ['UIKit', 'SVProgressHUD', 'UIAlertController', 'UIDocumentInteractionController']:
    assert forbidden not in service_m, f'backup engine gained presentation dependency: {forbidden}'

assert 'createBackupNamed:' in service_h
assert pbx.count('ZONBackupCoordinator.m in Sources') == 2

print('P70 backup presentation coordinator contract: PASS')
