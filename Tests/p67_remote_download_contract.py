from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
coord_path = root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
coord = coord_path.read_text() if coord_path.exists() else pubg
remote_coord_path = root / 'testmod/ZONServices/ZONRemoteRestoreCoordinator.m'
remote_coord = remote_coord_path.read_text() if remote_coord_path.exists() else coord
service_h = (root / 'testmod/ZONServices/ZONRemoteDownloadService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONRemoteDownloadService.m').read_text()
api_h = (root / 'testmod/ZONServices/ZONRestoreAPI.h').read_text()
api_m = (root / 'testmod/ZONServices/ZONRestoreAPI.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

orchestration = coord + '\n' + remote_coord
required_orchestration = [
    '#import "ZONRemoteDownloadService.h"', '#import "ZONRestoreAPI.h"',
    '[ZONRemoteDownloadService sharedService]', '[ZONRestoreAPI sharedAPI]',
    'downloadArchiveFromURL:url', 'restoreArchiveAtPath:archivePath', 'BOOL testMode = NO;',
]
for marker in required_orchestration:
    assert marker in orchestration, f'missing P67 orchestration marker: {marker}'

required_service = [
    'ZONRemoteDownloadErrorInvalidURL', 'ZONRemoteDownloadErrorAlreadyRunning',
    'ZONRemoteDownloadErrorTransportFailed', 'ZONRemoteDownloadErrorInvalidResponse',
    'ZONRemoteDownloadErrorInvalidArchive', 'NSURLSessionDownloadDelegate', 'activeTask',
    'downloadArchiveFromURL:', 'totalBytesExpectedToWrite',
    'statusCode < 200 || http.statusCode >= 300', '@"tmp/zonoe-download"', 'moveItemAtURL:location',
]
for marker in required_service:
    assert marker in service_h or marker in service_m, f'missing P67 service marker: {marker}'

required_api = [
    '@interface ZONRestoreAPI', '+ (instancetype)sharedAPI;', 'restoreArchiveAtPath:',
    'restorePreparedStagingAtPath:', '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]',
]
for marker in required_api:
    assert marker in api_h or marker in api_m, f'missing restore API marker: {marker}'

assert 'downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:' not in pubg
assert 'URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:' not in pubg
assert '[ZONRestoreService sharedService]' not in orchestration
assert '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' not in orchestration
assert pbx.count('ZONRemoteDownloadService.m in Sources') == 2
assert pbx.count('ZONRestoreAPI.m in Sources') == 2
if version == 'v1_p77':
    assert remote_coord_path.exists(), 'P77 remote restore coordinator missing'
    assert pbx.count('ZONRemoteRestoreCoordinator.m in Sources') == 2
assert version in {'v1_p67', 'v1_p67a', 'v1_p68', 'v1_p69', 'v1_p70', 'v1_p71', 'v1_p72', 'v1_p73', 'v1_p74', 'v1_p76', 'v1_p77'}, f'unexpected VERSION: {version}'

print('P67 remote download contract: PASS')
