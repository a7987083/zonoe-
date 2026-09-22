from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
dispatcher = (root / 'testmod/ZONCore/ZONFeatureDispatcher.m').read_text()
coord_h = (root / 'testmod/ZONServices/ZONLocalFilesCoordinator.h').read_text()
coord_m = (root / 'testmod/ZONServices/ZONLocalFilesCoordinator.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version in {'v1_p74', 'v1_p76'}, f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONLocalFilesCoordinator',
    '+ (instancetype)sharedCoordinator;',
    'presentLocalFilesFromViewController:',
]:
    assert marker in coord_h, f'missing P74 coordinator API marker: {marker}'

for marker in [
    '#import "SandboxBrowserVC.h"',
    'SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];',
    'UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];',
    '@available(iOS 13.0, *)',
    'UIModalPresentationPageSheet',
    'UIModalPresentationFullScreen',
    '[hostViewController presentViewController:nav animated:YES completion:nil];',
    'return YES;',
]:
    assert marker in coord_m, f'missing P74 local-files behavior marker: {marker}'

for marker in [
    '#import "../ZONServices/ZONLocalFilesCoordinator.h"',
    '@"base.local-files"',
    '[[ZONLocalFilesCoordinator sharedCoordinator] presentLocalFilesFromViewController:host]',
]:
    assert marker in dispatcher, f'missing P74 dispatcher route marker: {marker}'

for forbidden in [
    '#import "SandboxBrowserVC.h"',
    'SandboxBrowserVC *vc',
    'UINavigationController *nav',
    'UIModalPresentationPageSheet',
    'UIModalPresentationFullScreen',
]:
    assert forbidden not in dispatcher, f'dispatcher still owns local-files presentation: {forbidden}'

# P75 candidate behavior remains intentionally untouched in P74.
for marker in [
    'ZONApplyRuntimeToggle',
    '@"runtime.iap-noads"', '@"NNGG"', '@"NNGGNNGG"', '[ImgTool share].NeiGou = enabled',
    '@"runtime.ad-speed"', '@"AADD"', '@"AADDAADD"', '[ImgTool share].ADSpeed = enabled',
    '[defaults synchronize];',
]:
    assert marker in dispatcher, f'P74 unexpectedly changed runtime-toggle behavior: {marker}'

assert pbx.count('ZONLocalFilesCoordinator.m in Sources') == 2
print('P74 local files coordinator contract: PASS')
