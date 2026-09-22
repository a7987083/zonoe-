from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
coord_path = root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
coord = coord_path.read_text() if coord_path.exists() else pubg
service_h = (root / 'testmod/ZONServices/ZONRemoteDownloadService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONRemoteDownloadService.m').read_text()
api_h = (root / 'testmod/ZONServices/ZONRestoreAPI.h').read_text()
api_m = (root / 'testmod/ZONServices/ZONRestoreAPI.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

required_orchestration = [
    '#import "ZONRemoteDownloadService.h"', '#import "ZONRestoreAPI.h"',
    '[ZONRemoteDownloadService sharedService]', '[ZONRestoreAPI sharedAPI]',
    'downloadArchiveFromURL:url', 'restoreArchiveAtPath:archivePath', 'BOOL testMode = NO;',
]
for marker in required_orchestration:
    assert marker in coord, f'missing P67 orchestration marker: {marker}'

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
assert '[ZONRestoreService sharedService]' not in coord
assert '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]' not in coord
assert pbx.count('ZONRemoteDownloadService.m in Sources') == 2
assert pbx.count('ZONRestoreAPI.m in Sources') == 2
assert version in {'v1_p67', 'v1_p67a', 'v1_p68', 'v1_p69', 'v1_p70', 'v1_p71', 'v1_p72'}, f'unexpected VERSION: {version}'

print('P67 remote download contract: PASS')
