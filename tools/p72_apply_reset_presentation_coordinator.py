#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SIX = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
COORD_H = ROOT / 'testmod/ZONServices/ZONResetCoordinator.h'
COORD_M = ROOT / 'testmod/ZONServices/ZONResetCoordinator.m'

for required in (PBX, SIX, COORD_H, COORD_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B72000112F7B720100C0FFEE'
file_id = 'B72000122F7B720100C0FFEE'
name = 'ZONResetCoordinator.m'
path = 'testmod/ZONServices/ZONResetCoordinator.m'
build_anchor = '\t\tB71000112F7B710100C0FFEE /* ZONLocalRestoreCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = B71000122F7B710100C0FFEE /* ZONLocalRestoreCoordinator.m */; };'
file_anchor = '\t\tB71000122F7B710100C0FFEE /* ZONLocalRestoreCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONLocalRestoreCoordinator.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB71000112F7B710100C0FFEE /* ZONLocalRestoreCoordinator.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P71 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P71 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P71 sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

six = SIX.read_text(encoding='utf-8')
for old in [
    '#import "ZONAuthorizationResetService.h"\n',
    '#import "ZONGameDataResetService.h"\n',
    '#import "SVProgressHUD.h"\n',
    '#import <stdlib.h>\n',
]:
    six = six.replace(old, '')
if '#import "ZONResetCoordinator.h"' not in six:
    six = six.replace('#import "ZONLocalRestoreCoordinator.h"\n', '#import "ZONLocalRestoreCoordinator.h"\n#import "ZONResetCoordinator.h"\n', 1)

# Remove reset-presentation helpers from SixButton; temp-directory helpers remain.
six = re.sub(
    r'\ntypedef void \(\^ZONDestructiveConfirmationHandler\)\(void\);\n',
    '\n', six, count=1)
six = re.sub(
    r'\n\+ \(void\)presentDestructiveConfirmationFromViewController:.*?\n\}\n\n\+ \(NSString \*\)statusTextForGameDataResetStage:.*?\n\}\n',
    '\n', six, count=1, flags=re.S)

old_game = re.compile(
    r'\+ \(BOOL\)performClearGameDataFromViewController:\(UIViewController \*\)hostViewController\n\{.*?\n\}\n\n\+ \(BOOL\)performClearAuthorizationFromViewController:\(UIViewController \*\)hostViewController\n\{.*?\n\}\n',
    re.S)
new_game = '''+ (BOOL)performClearGameDataFromViewController:(UIViewController *)hostViewController\n{\n    [[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];\n    return YES;\n}\n\n+ (BOOL)performClearAuthorizationFromViewController:(UIViewController *)hostViewController\n{\n    [[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];\n    return YES;\n}\n'''
if old_game.search(six):
    six = old_game.sub(new_game, six, count=1)
elif new_game not in six:
    raise SystemExit('reset route block missing')

compat = re.compile(
    r'\+ \(void\)clearGameDataPreservingTemporaryDirectory\n\{.*?\n\}\n',
    re.S)
new_compat = '''+ (void)clearGameDataPreservingTemporaryDirectory\n{\n    [[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];\n}\n'''
if compat.search(six):
    six = compat.sub(new_compat, six, count=1)
elif new_compat not in six:
    raise SystemExit('compatibility reset entry missing')

SIX.write_text(six, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
final_six = SIX.read_text(encoding='utf-8')
if final_pbx.count('ZONResetCoordinator.m in Sources') != 2:
    raise SystemExit('P72 coordinator PBX marker invariant failed')
for marker in [
    '#import "ZONResetCoordinator.h"',
    'presentClearGameDataFromViewController:hostViewController',
    'presentClearAuthorizationFromViewController:hostViewController',
    'resetGameDataWithoutConfirmation',
]:
    if marker not in final_six:
        raise SystemExit(f'missing P72 six-button marker: {marker}')
for forbidden in [
    'ZONGameDataResetService', 'ZONAuthorizationResetService', 'SVProgressHUD',
    'UIAlertController', 'QOS_CLASS_USER_INITIATED', '(3 * NSEC_PER_SEC)', 'exit(0);'
]:
    if forbidden in final_six:
        raise SystemExit(f'SixButton still owns reset presentation/business: {forbidden}')
print('P72 reset presentation coordinator migration applied successfully')
