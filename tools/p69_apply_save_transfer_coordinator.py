#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
SIX = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
COORD_H = ROOT / 'testmod/ZONServices/ZONSaveTransferCoordinator.h'
COORD_M = ROOT / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'

for required in (PBX, PUBG, SIX, COORD_H, COORD_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B69000112F7B690100C0FFEE'
file_id = 'B69000122F7B690100C0FFEE'
name = 'ZONSaveTransferCoordinator.m'
path = 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
build_anchor = '\t\tB68000112F7B680100C0FFEE /* ZONCloudSaveService.m in Sources */ = {isa = PBXBuildFile; fileRef = B68000122F7B680100C0FFEE /* ZONCloudSaveService.m */; };'
file_anchor = '\t\tB68000122F7B680100C0FFEE /* ZONCloudSaveService.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONCloudSaveService.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB68000112F7B680100C0FFEE /* ZONCloudSaveService.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P68 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P68 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P68 sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

PUBG.write_text(r'''#import "PubgLoad.h"
#import "JHPP.h"
#import "ZONSaveTransferCoordinator.h"

@implementation PubgLoad

- (void)loadddd
{
    [self checkCloudSaveStatus];
}

- (void)yuanchengdwon
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:host];
}

- (void)checkCloudSaveStatus
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:host];
}

@end
''', encoding='utf-8')

six = SIX.read_text(encoding='utf-8')
six = six.replace('#import "PubgLoad.h"', '#import "ZONSaveTransferCoordinator.h"')
old_remote = '''+ (BOOL)performRemoteDownloadFromViewController:(__unused UIViewController *)hostViewController\n{\n    [[PubgLoad alloc] yuanchengdwon];\n    return YES;\n}'''
new_remote = '''+ (BOOL)performRemoteDownloadFromViewController:(UIViewController *)hostViewController\n{\n    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:hostViewController];\n    return YES;\n}'''
old_cloud = '''+ (BOOL)performCloudSaveFromViewController:(__unused UIViewController *)hostViewController\n{\n    [self ensureTemporaryDirectory];\n    [[PubgLoad alloc] checkCloudSaveStatus];\n    return YES;\n}'''
new_cloud = '''+ (BOOL)performCloudSaveFromViewController:(UIViewController *)hostViewController\n{\n    [self ensureTemporaryDirectory];\n    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:hostViewController];\n    return YES;\n}'''
if old_remote in six:
    six = six.replace(old_remote, new_remote, 1)
elif new_remote not in six:
    raise SystemExit('remote route marker missing')
if old_cloud in six:
    six = six.replace(old_cloud, new_cloud, 1)
elif new_cloud not in six:
    raise SystemExit('cloud route marker missing')
SIX.write_text(six, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
final_pubg = PUBG.read_text(encoding='utf-8')
final_six = SIX.read_text(encoding='utf-8')
if final_pbx.count('ZONSaveTransferCoordinator.m in Sources') != 2:
    raise SystemExit('P69 coordinator PBX marker invariant failed')
for marker in [
    '#import "ZONSaveTransferCoordinator.h"',
    '[ZONSaveTransferCoordinator sharedCoordinator]',
    'presentRemoteDownloadFromViewController:',
    'presentCloudSaveFromViewController:',
]:
    if marker not in final_six:
        raise SystemExit(f'missing P69 six-button marker: {marker}')
for forbidden in ['ZONRemoteDownloadService', 'ZONRestoreAPI', 'ZONCloudSaveService', 'getKeychain', 'SVProgressHUD', 'JDStatusBarNotification']:
    if forbidden in final_pubg:
        raise SystemExit(f'PubgLoad still owns transfer business: {forbidden}')
print('P69 save transfer coordinator migration applied successfully')
