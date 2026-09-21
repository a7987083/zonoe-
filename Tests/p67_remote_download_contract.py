from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
service_h = (root / 'testmod/ZONServices/ZONRemoteDownloadService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONRemoteDownloadService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

required_pubg = [
    '#import "ZONRemoteDownloadService.h"',
    '#import "ZONRestoreService.h"',
    '[ZONRemoteDownloadService sharedService]',
    '[ZONRestoreService sharedService]',
    'downloadArchiveFromURL:url',
    'restoreArchiveAtPath:archivePath',
    '-(void)yuanchengdwon',
    '- (void)checkCloudSaveStatus',
    'startArchiveDownloadWithURL:downloadURL',
    'BOOL testMode = NO;',
]
for marker in required_pubg:
    assert marker in pubg, f'missing P67 PubgLoad marker: {marker}'

required_service = [
    'ZONRemoteDownloadErrorInvalidURL',
    'ZONRemoteDownloadErrorAlreadyRunning',
    'ZONRemoteDownloadErrorTransportFailed',
    'ZONRemoteDownloadErrorInvalidResponse',
    'ZONRemoteDownloadErrorInvalidArchive',
    'NSURLSessionDownloadDelegate',
    'activeTask',
    'downloadArchiveFromURL:',
    'totalBytesExpectedToWrite',
    'statusCode < 200 || http.statusCode >= 300',
    '@"tmp/zonoe-download"',
    'moveItemAtURL:location',
]
for marker in required_service:
    assert marker in service_h or marker in service_m, f'missing P67 service marker: {marker}'

assert pubg.count('ZONRemoteDownloadService') >= 2
assert 'downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:' not in pubg
assert 'URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:' not in pubg
assert 'NSDirectoryEnumerator *enumerator1 = [[NSFileManager defaultManager] enumeratorAtPath:LibraryPath]' not in pubg
assert pbx.count('ZONRemoteDownloadService.m in Sources') == 2
assert version == 'v1_p67', f'unexpected VERSION: {version}'

print('P67 remote download contract: PASS')
