from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
save = (root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m').read_text()
remote_h = (root / 'testmod/ZONServices/ZONRemoteRestoreCoordinator.h').read_text()
remote_m = (root / 'testmod/ZONServices/ZONRemoteRestoreCoordinator.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version == 'v1_p77', f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONRemoteRestoreCoordinator',
    '+ (instancetype)sharedCoordinator;',
    'startArchiveDownloadWithURL:',
]:
    assert marker in remote_h, f'missing P77 API marker: {marker}'

for marker in [
    '#import "ZONRemoteDownloadService.h"',
    '#import "ZONRestoreAPI.h"',
    '[ZONRemoteDownloadService sharedService]',
    'downloadArchiveFromURL:url',
    '[ZONRestoreAPI sharedAPI]',
    'restoreArchiveAtPath:archivePath',
    '@"请耐心等待,下载中...',
    '@"下载成功，正在恢复存档..."',
    '@"下载失败"',
    '@"恢复失败"',
    '@"恢复完成"',
    'ZONRestoreErrorCleanupFailed',
]:
    assert marker in remote_m, f'missing P77 remote-restore behavior marker: {marker}'

for marker in [
    '#import "ZONRemoteRestoreCoordinator.h"',
    '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:[NSURL URLWithString:text]];',
    '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:downloadURL];',
    'BOOL testMode = NO;',
    '[ZONCloudSaveService sharedService]',
    'resolveDownloadURLForBundleIdentifier:',
]:
    assert marker in save, f'missing P77 save-transfer route marker: {marker}'

for forbidden in [
    '#import "ZONRemoteDownloadService.h"',
    'downloadArchiveFromURL:',
    'presentRemoteDownloadProgressReceived:',
    '- (void)startArchiveDownloadWithURL:',
]:
    assert forbidden not in save, f'P77 save-transfer still owns remote restore orchestration: {forbidden}'

for forbidden in [
    '[ZONRestoreService sharedService]',
    '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]',
]:
    assert forbidden not in remote_m, f'P77 coordinator bypasses restore API boundary: {forbidden}'

assert pbx.count('ZONRemoteRestoreCoordinator.m in Sources') == 2
print('P77 remote restore coordinator contract: PASS')
