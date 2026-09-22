from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
router_h = (root / 'testmod/ZONServices/ZONAuthorizationEntryRouter.h').read_text()
router_m = (root / 'testmod/ZONServices/ZONAuthorizationEntryRouter.m').read_text()
legacy = (root / 'testmod/Bsphp/WX_NongShiFu123.mm').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version == 'v1_p76', f'unexpected VERSION: {version}'

for marker in [
    'ZONAuthorizationEntryModeFirstActivation',
    'ZONAuthorizationEntryModeAdSpeed',
    'ZONAuthorizationEntryModeSoftwareSource',
    'ZONAuthorizationEntryModeChooseMethod',
    '@interface ZONAuthorizationEntrySnapshot',
    '+ (ZONAuthorizationEntrySnapshot *)currentSnapshot;',
]:
    assert marker in router_h, f'missing P76 router API marker: {marker}'

# The router owns only entry policy/data acquisition, not UIKit or network authorization execution.
for marker in [
    '[getKeychain getKeychainDataForKey:@"rjyyz"]',
    '[getKeychain getKeychainDataForKey:@"ShiSanGeDZKM"]',
    '[getKeychain getKeychainDataForKey:@"DZUDID"]',
    'deviceIdentifier.length < 5',
    '[activationCode containsString:@"mg"]',
    '[unlockStatus containsString:@"未查到解锁记录"]',
    'deviceIdentifier.length > 16',
    '[unlockStatus containsString:@"ok"]',
    'ZONAuthorizationEntryModeFirstActivation',
    'ZONAuthorizationEntryModeAdSpeed',
    'ZONAuthorizationEntryModeSoftwareSource',
    'ZONAuthorizationEntryModeChooseMethod',
]:
    assert marker in router_m, f'missing P76 routing-policy marker: {marker}'

for forbidden in [
    'UIKit', 'UIAlertController', 'JDStatusBarNotification', 'SVProgressHUD',
    'NetTool', 'BSPHP_HOST', 'exit(0)',
]:
    assert forbidden not in router_m, f'entry router gained unrelated dependency: {forbidden}'

assert router_m.index('deviceIdentifier.length < 5') < router_m.index('[activationCode containsString:@"mg"]')
assert router_m.index('[activationCode containsString:@"mg"]') < router_m.index('deviceIdentifier.length > 16')

loada = legacy.split('- (void)loada {', 1)[1].split('-(void)shouquanjiance', 1)[0]
for marker in [
    '#import "../ZONServices/ZONAuthorizationEntryRouter.h"',
    '[ZONAuthorizationEntryRouter currentSnapshot]',
    'rjyyz = entry.unlockStatus;',
    'kmm = entry.activationCode;',
    '设备特征码 = entry.deviceIdentifier;',
    '5 * NSEC_PER_SEC',
    '@"首次激活"',
    '@"秒过广告激活中"',
    '@"软件源激活中"',
    '[self getUDID:^{',
    '[self BSPHP];',
    '[self BSPHPy];',
    '[self shouquanjiance];',
]:
    assert marker in (legacy if marker.startswith('#import') else loada), f'missing legacy behavior marker: {marker}'

for forbidden in [
    '[getKeychain getKeychainDataForKey:@"rjyyz"]',
    '[getKeychain getKeychainDataForKey:@"ShiSanGeDZKM"]',
    '[getKeychain getKeychainDataForKey:@"DZUDID"]',
    '[kmm containsString:@"mg"]',
    '[rjyyz containsString:@"未查到解锁记录"]',
    '[rjyyz containsString:@"ok"]',
]:
    assert forbidden not in loada, f'legacy loada still owns entry policy: {forbidden}'

# P76 must not rewrite the established authorization protocol bodies.
for marker in [
    '- (void)BSPHP{',
    '- (BOOL)getNet {',
    'param[@"api"] = @"BSphpSeSsL.in";',
    'param[@"api"] = @"globalinfo.in";',
    'param[@"api"] = @"timeout.ic";',
]:
    assert marker in legacy, f'legacy authorization protocol marker drifted: {marker}'

assert pbx.count('ZONAuthorizationEntryRouter.m in Sources') == 2
print('P76 authorization entry routing contract: PASS')
