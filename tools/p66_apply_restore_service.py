#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
PICKER = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
ZIP = ROOT / 'testmod/菜单/UNZip/SSZipArchive.m'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONRestoreService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONRestoreService.m'
POLICY_H = ROOT / 'testmod/ZONServices/ZONRestorePolicy.h'
POLICY_M = ROOT / 'testmod/ZONServices/ZONRestorePolicy.m'

for required in (PBX, PICKER, ZIP, SERVICE_H, SERVICE_M, POLICY_H, POLICY_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

# 1) Register P66 sources in the active target.
pbx = PBX.read_text(encoding='utf-8')
entries = [
    ('B66000112F7B660100C0FFEE', 'B66000122F7B660100C0FFEE', 'ZONRestoreService.m', 'testmod/ZONServices/ZONRestoreService.m'),
    ('B66000212F7B660100C0FFEE', 'B66000222F7B660100C0FFEE', 'ZONRestorePolicy.m', 'testmod/ZONServices/ZONRestorePolicy.m'),
]
build_anchor = '\t\tB65000212F7B400100C0FFEE /* ZONBackupPolicy.m in Sources */ = {isa = PBXBuildFile; fileRef = B65000222F7B400100C0FFEE /* ZONBackupPolicy.m */; };'
file_anchor = '\t\tB65000222F7B400100C0FFEE /* ZONBackupPolicy.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONBackupPolicy.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB65000212F7B400100C0FFEE /* ZONBackupPolicy.m in Sources */,'

for build_id, file_id, name, path in entries:
    build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
    file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
    source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'
    if build_line not in pbx:
        if build_anchor not in pbx: raise SystemExit('P65 build anchor missing')
        pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
        build_anchor = build_line
    if file_line not in pbx:
        if file_anchor not in pbx: raise SystemExit('P65 file anchor missing')
        pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
        file_anchor = file_line
    if source_line not in pbx:
        if source_anchor not in pbx: raise SystemExit('P65 sources anchor missing')
        pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
        source_anchor = source_line

PBX.write_text(pbx, encoding='utf-8')

# 2) Make YYYPicker a UI/orchestration adapter while preserving addBtnAction and yidongwenjian compatibility.
picker = PICKER.read_text(encoding='utf-8')
if '#import "ZONRestoreService.h"' not in picker:
    import_anchor = '#import "jhpp.h"\n'
    if import_anchor not in picker: raise SystemExit('YYYPicker import anchor missing')
    picker = picker.replace(import_anchor, import_anchor + '#import "ZONRestoreService.h"\n', 1)

start_marker = '#pragma mark - Restore engine\n'
end_marker = '#pragma mark - UICollectionViewDataSource\n'
if start_marker not in picker or end_marker not in picker:
    raise SystemExit('YYYPicker restore section markers missing')

replacement = '''#pragma mark - Restore orchestration

- (void)reloadRestoredPreferences
{
    [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];
}

- (void)presentRestoreResult:(BOOL)success error:(NSError *)error
{
    if (!success) {
        NSString *message = error.localizedDescription.length ? error.localizedDescription : @"恢复失败";
        [SVProgressHUD showErrorWithStatus:message];
        return;
    }

    [self reloadRestoredPreferences];
    if (error.code == ZONRestoreErrorCleanupFailed) {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
    } else {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
    }
}

- (void)handlePickedRestoreURL:(NSURL *)fileUrl
{
    if (!fileUrl) return;

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    ZONRestoreService *service = [ZONRestoreService sharedService];
    NSString *inboxPath = [service restoreInboxPathForBundleIdentifier:bundleIdentifier];
    NSString *archivePath = fileUrl.path;

    if (![[NSFileManager defaultManager] fileExistsAtPath:archivePath]) {
        NSString *decodedFileName = [[[fileUrl absoluteString] componentsSeparatedByString:@"/"] lastObject].stringByRemovingPercentEncoding;
        archivePath = [inboxPath stringByAppendingPathComponent:decodedFileName ?: @""];
    }

    self->_dataArr = nil;
    [self.collectionView reloadData];
    [SVProgressHUD showWithStatus:@"处理中..."];

    [service restoreArchiveAtPath:archivePath inboxPath:inboxPath completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

#pragma mark - Restore UI entry

- (void)addBtnAction
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[NKSeleDocumentTool shareDocumentTool]
         seleDocumentWithDocumentTypes:@[@"public.data"]
         Mode:UIDocumentPickerModeImport
         controller:self
         finishBlock:^(NSArray<NSURL *> *urls) {
            [self handlePickedRestoreURL:urls.firstObject];
        }];
    });
}

- (void)yidongwenjian
{
    ZONRestoreService *service = [ZONRestoreService sharedService];
    NSString *stagingRoot = [service restoreStagingRootPath];
    [service restorePreparedStagingAtPath:stagingRoot completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

'''
prefix, rest = picker.split(start_marker, 1)
_, suffix = rest.split(end_marker, 1)
picker = prefix + replacement + end_marker + suffix
PICKER.write_text(picker, encoding='utf-8')

# 3) Harden the shared unzip primitive so every restore path (including nested archives) is contained.
zip_src = ZIP.read_text(encoding='utf-8')
old = '\t\t\tNSString *fullPath = [destination stringByAppendingPathComponent:strPath];'
new = '''\t\t\tNSString *destinationRoot = [destination stringByStandardizingPath];
\t\t\tNSString *fullPath = [[destination stringByAppendingPathComponent:strPath] stringByStandardizingPath];
\t\t\tNSString *destinationPrefix = [destinationRoot stringByAppendingString:@"/"];
\t\t\tif (!([fullPath isEqualToString:destinationRoot] || [fullPath hasPrefix:destinationPrefix])) {
\t\t\t\tNSLog(@"[SSZipArchive] blocked unsafe archive path: %@", strPath);
\t\t\t\tif (error) {
\t\t\t\t\t*error = [NSError errorWithDomain:@"SSZipArchiveErrorDomain"
\t\t\t\t\t                             code:-9
\t\t\t\t\t                         userInfo:@{NSLocalizedDescriptionKey: @"unsafe archive entry path"}];
\t\t\t\t}
\t\t\t\tsuccess = NO;
\t\t\t\tunzCloseCurrentFile(zip);
\t\t\t\tbreak;
\t\t\t}'''
if 'blocked unsafe archive path' not in zip_src:
    if zip_src.count(old) != 1:
        raise SystemExit(f'unexpected SSZipArchive fullPath anchor count: {zip_src.count(old)}')
    zip_src = zip_src.replace(old, new, 1)
ZIP.write_text(zip_src, encoding='utf-8')

# Final invariants.
final_pbx = PBX.read_text(encoding='utf-8')
for _, _, name, _ in entries:
    if final_pbx.count(f'{name} in Sources') != 2:
        raise SystemExit(f'PBX source marker invariant failed for {name}')
final_picker = PICKER.read_text(encoding='utf-8')
if 'recursivelyCopyContentsOfDirectory:' in final_picker:
    raise SystemExit('legacy restore copy engine still present in YYYPicker')
if final_picker.count('[ZONRestoreService sharedService]') < 2:
    raise SystemExit('YYYPicker is not routed through ZONRestoreService')
if 'blocked unsafe archive path' not in ZIP.read_text(encoding='utf-8'):
    raise SystemExit('unsafe archive path guard missing')

print('P66 restore service migration applied successfully')
