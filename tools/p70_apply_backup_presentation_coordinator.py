#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SIX = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
LEGACY = ROOT / 'testmod/导入导出/daochucd.m'
COORD_H = ROOT / 'testmod/ZONServices/ZONBackupCoordinator.h'
COORD_M = ROOT / 'testmod/ZONServices/ZONBackupCoordinator.m'

for required in (PBX, SIX, LEGACY, COORD_H, COORD_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B70000112F7B700100C0FFEE'
file_id = 'B70000122F7B700100C0FFEE'
name = 'ZONBackupCoordinator.m'
path = 'testmod/ZONServices/ZONBackupCoordinator.m'
build_anchor = '\t\tB69000112F7B690100C0FFEE /* ZONSaveTransferCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = B69000122F7B690100C0FFEE /* ZONSaveTransferCoordinator.m */; };'
file_anchor = '\t\tB69000122F7B690100C0FFEE /* ZONSaveTransferCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONSaveTransferCoordinator.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB69000112F7B690100C0FFEE /* ZONSaveTransferCoordinator.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P69 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P69 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P69 sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

LEGACY.write_text(r'''#import "daochucd.h"
#import "JHPP.h"
#import "ZONBackupCoordinator.h"

@implementation daochucd

- (void)backupasd
{
    UIViewController *host = [JHPP currentViewController];
    [[ZONBackupCoordinator sharedCoordinator] presentBackupFromViewController:host];
}

@end
''', encoding='utf-8')

six = SIX.read_text(encoding='utf-8')
six = six.replace('#import "daochucd.h"', '#import "ZONBackupCoordinator.h"')
old = '''+ (BOOL)performBackupSaveFromViewController:(__unused UIViewController *)hostViewController\n{\n    [[daochucd alloc] backupasd];\n    return YES;\n}'''
new = '''+ (BOOL)performBackupSaveFromViewController:(UIViewController *)hostViewController\n{\n    [[ZONBackupCoordinator sharedCoordinator] presentBackupFromViewController:hostViewController];\n    return YES;\n}'''
if old in six:
    six = six.replace(old, new, 1)
elif new not in six:
    raise SystemExit('backup route marker missing')
SIX.write_text(six, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
final_six = SIX.read_text(encoding='utf-8')
final_legacy = LEGACY.read_text(encoding='utf-8')

if final_pbx.count('ZONBackupCoordinator.m in Sources') != 2:
    raise SystemExit('P70 coordinator PBX marker invariant failed')
for marker in [
    '#import "ZONBackupCoordinator.h"',
    '[ZONBackupCoordinator sharedCoordinator]',
    'presentBackupFromViewController:hostViewController',
]:
    if marker not in final_six:
        raise SystemExit(f'missing P70 six-button marker: {marker}')
for forbidden in ['ZONBackupService', 'SVProgressHUD', 'UIDocumentInteractionController', 'cleanupBackupArtifacts', 'requestBackupDecisionForRelativePath:']:
    if forbidden in final_legacy:
        raise SystemExit(f'daochucd still owns backup presentation/business: {forbidden}')
print('P70 backup presentation coordinator migration applied successfully')
