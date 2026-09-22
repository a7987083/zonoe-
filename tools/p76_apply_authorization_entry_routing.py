#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
LEGACY = ROOT / 'testmod/Bsphp/WX_NongShiFu123.mm'
ROUTER_H = ROOT / 'testmod/ZONServices/ZONAuthorizationEntryRouter.h'
ROUTER_M = ROOT / 'testmod/ZONServices/ZONAuthorizationEntryRouter.m'

for required in (PBX, LEGACY, ROUTER_H, ROUTER_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

# Register the new UIKit-free routing policy in the target.
pbx = PBX.read_text(encoding='utf-8')
build_id = 'B76000112F7B760100C0FFEE'
file_id = 'B76000122F7B760100C0FFEE'
name = 'ZONAuthorizationEntryRouter.m'
path = 'testmod/ZONServices/ZONAuthorizationEntryRouter.m'
build_anchor = '\t\tB74000112F7B740100C0FFEE /* ZONLocalFilesCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = B74000122F7B740100C0FFEE /* ZONLocalFilesCoordinator.m */; };'
file_anchor = '\t\tB74000122F7B740100C0FFEE /* ZONLocalFilesCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONLocalFilesCoordinator.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB74000112F7B740100C0FFEE /* ZONLocalFilesCoordinator.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx:
        raise SystemExit('P74 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx:
        raise SystemExit('P74 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx:
        raise SystemExit('P74 source anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

legacy = LEGACY.read_text(encoding='utf-8')
router_import = '#import "../ZONServices/ZONAuthorizationEntryRouter.h"\n'
if router_import not in legacy:
    anchor = '#import "../ZONServices/ZONAuthorizationResetService.h"\n'
    if anchor not in legacy:
        raise SystemExit('authorization service import anchor missing')
    legacy = legacy.replace(anchor, anchor + router_import, 1)

new_loada = r'''- (void)loada {
    ZONAuthorizationEntrySnapshot *entry = [ZONAuthorizationEntryRouter currentSnapshot];

    // Preserve the legacy globals because downstream BSPHP/BSPHPy code still reads them.
    rjyyz = entry.unlockStatus;
    kmm = entry.activationCode;
    设备特征码 = entry.deviceIdentifier;

    if (entry.mode == ZONAuthorizationEntryModeFirstActivation) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
            [presenter dismissAnimated:YES];
            [presenter presentWithText:@"首次激活" dismissAfterDelay:5 includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
            [self getUDID:^{
                [self shouquanjiance];
            }];
        });
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];

        switch (entry.mode) {
            case ZONAuthorizationEntryModeAdSpeed:
                [presenter presentWithText:@"秒过广告激活中" dismissAfterDelay:5 includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
                [self BSPHP];
                break;

            case ZONAuthorizationEntryModeSoftwareSource:
                [presenter presentWithText:@"软件源激活中" dismissAfterDelay:5 includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
                [self BSPHPy];
                break;

            case ZONAuthorizationEntryModeChooseMethod:
            default:
                [presenter presentWithText:@"首次激活" dismissAfterDelay:5 includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
                [self shouquanjiance];
                break;
        }
    });
}'''

pattern = r'- \(void\)loada \{.*?\n\}\n\n\n-\(void\)shouquanjiance'
replacement = new_loada + '\n\n\n-(void)shouquanjiance'
updated, count = re.subn(pattern, replacement, legacy, count=1, flags=re.S)
if count != 1:
    if '[ZONAuthorizationEntryRouter currentSnapshot]' not in legacy:
        raise SystemExit(f'expected one legacy loada block, replaced {count}')
    updated = legacy
LEGACY.write_text(updated, encoding='utf-8')

final_legacy = LEGACY.read_text(encoding='utf-8')
final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count('ZONAuthorizationEntryRouter.m in Sources') != 2:
    raise SystemExit('P76 router PBX invariant failed')

for marker in [
    '#import "../ZONServices/ZONAuthorizationEntryRouter.h"',
    '[ZONAuthorizationEntryRouter currentSnapshot]',
    'rjyyz = entry.unlockStatus;',
    'kmm = entry.activationCode;',
    '设备特征码 = entry.deviceIdentifier;',
    'ZONAuthorizationEntryModeAdSpeed',
    'ZONAuthorizationEntryModeSoftwareSource',
    'ZONAuthorizationEntryModeChooseMethod',
    '[self BSPHP];',
    '[self BSPHPy];',
    '[self shouquanjiance];',
]:
    if marker not in final_legacy:
        raise SystemExit(f'missing P76 legacy routing marker: {marker}')

legacy_loada = final_legacy.split('- (void)loada {', 1)[1].split('-(void)shouquanjiance', 1)[0]
for forbidden in [
    '[getKeychain getKeychainDataForKey:@"rjyyz"]',
    '[getKeychain getKeychainDataForKey:@"ShiSanGeDZKM"]',
    '[getKeychain getKeychainDataForKey:@"DZUDID"]',
    '[kmm containsString:@"mg"]',
    '[rjyyz containsString:@"未查到解锁记录"]',
    '[rjyyz containsString:@"ok"]',
]:
    if forbidden in legacy_loada:
        raise SystemExit(f'loada still owns entry policy: {forbidden}')

print('P76 authorization entry routing migration applied successfully')
