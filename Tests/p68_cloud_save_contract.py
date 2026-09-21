from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
service_h = (root / 'testmod/ZONServices/ZONCloudSaveService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONCloudSaveService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

for marker in [
    'ZONCloudSaveErrorEntitlementDenied',
    'fetchMetadataForBundleIdentifier:',
    'effectiveDownloadAddressForFunction:',
    'resolveDownloadURLForBundleIdentifier:',
    'bypassEntitlement:',
    'NSURLSessionDataTask',
    'metadata[@"功能"]',
    'dictionary[@"expire"]',
]:
    assert marker in service_h or marker in service_m, f'missing P68 service marker: {marker}'

for marker in [
    '#import "ZONCloudSaveService.h"',
    '[ZONCloudSaveService sharedService]',
    'fetchMetadataForBundleIdentifier:',
    'effectiveDownloadAddressForFunction:',
    'resolveDownloadURLForBundleIdentifier:',
    'bypassEntitlement:testMode',
    'BOOL testMode = NO;',
    '[self startArchiveDownloadWithURL:downloadURL]',
    '[self checkCloudSaveStatus];',
    '[ZONRemoteDownloadService sharedService]',
    '[ZONRestoreAPI sharedAPI]',
]:
    assert marker in pubg, f'missing P68 PubgLoad marker: {marker}'

cloud_start = pubg.index('- (void)checkCloudSaveStatus')
cleanup_start = pubg.index('- (void)cleanupTemporaryFiles')
cloud = pubg[cloud_start:cleanup_start]
for forbidden in [
    'NSURLSession *session',
    'dataTaskWithURL:',
    'NSJSONSerialization JSONObjectWithData:',
    'stringWithContentsOfURL:',
    'isCloudEntitlementValidWithCode:',
]:
    assert forbidden not in cloud, f'PubgLoad still owns cloud business/networking: {forbidden}'

assert pbx.count('ZONCloudSaveService.m in Sources') == 2
assert version == 'v1_p68', f'unexpected VERSION: {version}'

print('P68 cloud save contract: PASS')
