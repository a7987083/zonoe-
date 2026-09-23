from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
six = (root / 'testmod/ZONServices/ZONSixButtonActionService.m').read_text()
coord_h = (root / 'testmod/ZONServices/ZONSaveTransferCoordinator.h').read_text()
coord_m = (root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m').read_text()
remote_path = root / 'testmod/ZONServices/ZONRemoteRestoreCoordinator.m'
remote_m = remote_path.read_text() if remote_path.exists() else ''
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

for marker in ['@interface ZONSaveTransferCoordinator', '+ (instancetype)sharedCoordinator;', 'presentRemoteDownloadFromViewController:', 'presentCloudSaveFromViewController:']:
    assert marker in coord_h, f'missing coordinator declaration: {marker}'

transfer_behavior = coord_m + '\n' + remote_m
for marker in [
    '[ZONRemoteDownloadService sharedService]', '[ZONRestoreAPI sharedAPI]', '[ZONCloudSaveService sharedService]',
    'downloadArchiveFromURL:url', 'restoreArchiveAtPath:archivePath', 'fetchMetadataForBundleIdentifier:',
    'effectiveDownloadAddressForFunction:', 'resolveDownloadURLForBundleIdentifier:', 'bypassEntitlement:testMode',
    'BOOL testMode = NO;', 'restoreStagingRootPath', '@"远程下载存档"', '@"正在检查云存档文件..."',
]:
    assert marker in transfer_behavior, f'missing coordinator behavior marker: {marker}'

for marker in [
    '#import "ZONSaveTransferCoordinator.h"', '[ZONSaveTransferCoordinator sharedCoordinator]',
    'presentRemoteDownloadFromViewController:hostViewController', 'presentCloudSaveFromViewController:hostViewController',
]:
    assert marker in six, f'missing six-button coordinator route: {marker}'

assert '#import "PubgLoad.h"' not in six
assert '[[PubgLoad alloc] yuanchengdwon]' not in six
assert '[[PubgLoad alloc] checkCloudSaveStatus]' not in six

for marker in [
    '#import "ZONSaveTransferCoordinator.h"', '[JHPP currentViewController]',
    'presentRemoteDownloadFromViewController:host', 'presentCloudSaveFromViewController:host', '[self checkCloudSaveStatus];',
]:
    assert marker in pubg, f'missing PubgLoad compatibility shim marker: {marker}'

for forbidden in [
    'ZONRemoteDownloadService', 'ZONRestoreAPI', 'ZONCloudSaveService', 'getKeychain', 'SVProgressHUD',
    'JDStatusBarNotification', 'downloadArchiveFromURL:', 'restoreArchiveAtPath:', 'fetchMetadataForBundleIdentifier:',
]:
    assert forbidden not in pubg, f'PubgLoad still owns save-transfer business: {forbidden}'

assert 'enumeratorAtPath:' not in coord_m
assert 'NSHomeDirectory() stringByAppendingPathComponent:@"tmp"' not in coord_m
assert pbx.count('ZONSaveTransferCoordinator.m in Sources') == 2
if version == 'v1_p77':
    assert remote_path.exists(), 'P77 remote restore coordinator missing'
    assert pbx.count('ZONRemoteRestoreCoordinator.m in Sources') == 2
    assert '#import "ZONRemoteDownloadService.h"' not in coord_m
    assert 'downloadArchiveFromURL:' not in coord_m
    assert '#import "ZONRemoteRestoreCoordinator.h"' in coord_m
assert version in {'v1_p69', 'v1_p70', 'v1_p71', 'v1_p72', 'v1_p73', 'v1_p74', 'v1_p76', 'v1_p77'}, f'unexpected VERSION: {version}'

print('P69 save transfer coordinator contract: PASS')
