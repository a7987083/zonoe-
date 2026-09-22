from pathlib import Path

root = Path(__file__).resolve().parents[1]
pubg = (root / 'testmod/菜单/PubgLoad.mm').read_text()
coord_path = root / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
coord = coord_path.read_text() if coord_path.exists() else pubg
service_h = (root / 'testmod/ZONServices/ZONCloudSaveService.h').read_text()
service_m = (root / 'testmod/ZONServices/ZONCloudSaveService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()
version = (root / 'VERSION').read_text().strip()

for marker in [
    'ZONCloudSaveErrorEntitlementDenied', 'fetchMetadataForBundleIdentifier:',
    'effectiveDownloadAddressForFunction:', 'resolveDownloadURLForBundleIdentifier:',
    'bypassEntitlement:', 'NSURLSession sharedSession', 'dataTaskWithURL:',
    'statusCode < 200 || http.statusCode >= 300', 'NSJSONSerialization JSONObjectWithData:',
    'metadata[@"功能"]', 'dictionary[@"expire"]',
]:
    assert marker in service_h or marker in service_m, f'missing P68 service marker: {marker}'

for marker in [
    '#import "ZONCloudSaveService.h"', '[ZONCloudSaveService sharedService]',
    'fetchMetadataForBundleIdentifier:', 'effectiveDownloadAddressForFunction:',
    'resolveDownloadURLForBundleIdentifier:', 'bypassEntitlement:testMode',
    'BOOL testMode = NO;', '[self startArchiveDownloadWithURL:downloadURL]',
    '[ZONRemoteDownloadService sharedService]', '[ZONRestoreAPI sharedAPI]',
]:
    assert marker in coord, f'missing P68 orchestration marker: {marker}'

for forbidden in ['NSURLSession *session', 'dataTaskWithURL:', 'NSJSONSerialization JSONObjectWithData:', 'stringWithContentsOfURL:', 'isCloudEntitlementValidWithCode:']:
    assert forbidden not in coord, f'UI orchestration still owns cloud business/networking: {forbidden}'

assert pbx.count('ZONCloudSaveService.m in Sources') == 2
assert version in {'v1_p68', 'v1_p69', 'v1_p70'}, f'unexpected VERSION: {version}'

print('P68 cloud save contract: PASS')
