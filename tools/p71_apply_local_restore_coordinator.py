#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SIX = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
PICKER = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
COORD_H = ROOT / 'testmod/ZONServices/ZONLocalRestoreCoordinator.h'
COORD_M = ROOT / 'testmod/ZONServices/ZONLocalRestoreCoordinator.m'

for required in (PBX, SIX, PICKER, COORD_H, COORD_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B71000112F7B710100C0FFEE'
file_id = 'B71000122F7B710100C0FFEE'
name = 'ZONLocalRestoreCoordinator.m'
path = 'testmod/ZONServices/ZONLocalRestoreCoordinator.m'
build_anchor = '\t\tB70000112F7B700100C0FFEE /* ZONBackupCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = B70000122F7B700100C0FFEE /* ZONBackupCoordinator.m */; };'
file_anchor = '\t\tB70000122F7B700100C0FFEE /* ZONBackupCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONBackupCoordinator.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB70000112F7B700100C0FFEE /* ZONBackupCoordinator.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P70 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P70 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P70 sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

picker = PICKER.read_text(encoding='utf-8')
for old in [
    '#import "NKSeleDocumentTool.h"\n',
    '#import "SVProgressHUD.h"\n',
    '#import "SSZipArchive.h"\n',
    '#import "jhpp.h"\n',
    '#import "ZONRestoreAPI.h"\n',
]:
    picker = picker.replace(old, '')
if '#import "ZONLocalRestoreCoordinator.h"' not in picker:
    picker = picker.replace('#import <QuickLook/QuickLook.h>\n', '#import <QuickLook/QuickLook.h>\n#import "ZONLocalRestoreCoordinator.h"\n', 1)

start_marker = '#pragma mark - Restore orchestration'
end_marker = '#pragma mark - UICollectionViewDataSource'
if start_marker not in picker or end_marker not in picker:
    raise SystemExit('YYYPicker restore section markers missing')
start = picker.index(start_marker)
end = picker.index(end_marker, start)
replacement = r'''#pragma mark - Restore compatibility surface

- (void)addBtnAction
{
    __weak typeof(self) weakSelf = self;
    [[ZONLocalRestoreCoordinator sharedCoordinator]
     presentLocalRestoreFromViewController:self
     selectionHandler:^(__unused NSURL *selectedURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self->_dataArr = nil;
        [self.collectionView reloadData];
    }];
}

- (void)restorePreparedArchiveStaging
{
    [[ZONLocalRestoreCoordinator sharedCoordinator] restorePreparedArchiveStaging];
}

- (void)yidongwenjian
{
    // Legacy compatibility entry retained for historical callers.
    [self restorePreparedArchiveStaging];
}

'''
picker = picker[:start] + replacement + picker[end:]
PICKER.write_text(picker, encoding='utf-8')

six = SIX.read_text(encoding='utf-8')
six = six.replace('#import "YYYPicker.h"', '#import "ZONLocalRestoreCoordinator.h"')
old = '''+ (BOOL)performRestoreSaveFromViewController:(__unused UIViewController *)hostViewController\n{\n    [[YYYPicker alloc] addBtnAction];\n    return YES;\n}'''
new = '''+ (BOOL)performRestoreSaveFromViewController:(UIViewController *)hostViewController\n{\n    [[ZONLocalRestoreCoordinator sharedCoordinator] presentLocalRestoreFromViewController:hostViewController];\n    return YES;\n}'''
if old in six:
    six = six.replace(old, new, 1)
elif new not in six:
    raise SystemExit('local restore route marker missing')
SIX.write_text(six, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
final_six = SIX.read_text(encoding='utf-8')
final_picker = PICKER.read_text(encoding='utf-8')
if final_pbx.count('ZONLocalRestoreCoordinator.m in Sources') != 2:
    raise SystemExit('P71 coordinator PBX marker invariant failed')
for marker in [
    '#import "ZONLocalRestoreCoordinator.h"',
    '[ZONLocalRestoreCoordinator sharedCoordinator]',
    'presentLocalRestoreFromViewController:hostViewController',
]:
    if marker not in final_six:
        raise SystemExit(f'missing P71 six-button marker: {marker}')
for forbidden in ['ZONRestoreAPI', 'NKSeleDocumentTool', 'SVProgressHUD', 'restoreArchiveAtPath:', 'restoreInboxPathForBundleIdentifier:']:
    if forbidden in final_picker:
        raise SystemExit(f'YYYPicker still owns local restore orchestration: {forbidden}')
print('P71 local restore coordinator migration applied successfully')
