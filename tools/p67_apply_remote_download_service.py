#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONRemoteDownloadService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONRemoteDownloadService.m'
RESTORE_H = ROOT / 'testmod/ZONServices/ZONRestoreService.h'

for required in (PBX, PUBG, SERVICE_H, SERVICE_M, RESTORE_H):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B67000112F7B670100C0FFEE'
file_id = 'B67000122F7B670100C0FFEE'
name = 'ZONRemoteDownloadService.m'
path = 'testmod/ZONServices/ZONRemoteDownloadService.m'
build_anchor = '\t\tB66000212F7B660100C0FFEE /* ZONRestorePolicy.m in Sources */ = {isa = PBXBuildFile; fileRef = B66000222F7B660100C0FFEE /* ZONRestorePolicy.m */; };'
file_anchor = '\t\tB66000222F7B660100C0FFEE /* ZONRestorePolicy.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONRestorePolicy.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB66000212F7B660100C0FFEE /* ZONRestorePolicy.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'
if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P66 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P66 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P66 sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

src = PUBG.read_text(encoding='utf-8')
if '#import "ZONRemoteDownloadService.h"' not in src:
    anchor = '#import "SVProgressHUD.h"\n'
    if anchor not in src: raise SystemExit('PubgLoad import anchor missing')
    src = src.replace(anchor, anchor + '#import "ZONRemoteDownloadService.h"\n#import "ZONRestoreService.h"\n', 1)
src = src.replace('@interface PubgLoad()<SSZipArchiveDelegate,NSURLSessionDownloadDelegate>', '@interface PubgLoad()', 1)

legacy_tmp_start = '                            NSString *cachePath = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"] ;\n'
legacy_tmp_end = '                            NSLog(@"存档 数据");\n'
if legacy_tmp_start in src and legacy_tmp_end in src:
    before, tail = src.split(legacy_tmp_start, 1)
    _, after = tail.split(legacy_tmp_end, 1)
    src = before + '                            [self cleanupTemporaryFiles];\n                            NSLog(@"存档 数据");\n' + after

legacy_direct = '''                                 NSURL *url = [NSURL URLWithString:下载地址];
                                 NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                                // 2、利用NSURLSessionDownloadTask创建任务(task)
                                NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
//                                NSLog(@"验证成功=%@",task);
                       
                            
                                // 3、执行任务
                                [task resume];'''
if legacy_direct in src:
    src = src.replace(legacy_direct, '''                                 NSURL *url = [NSURL URLWithString:下载地址];
                                 [self startArchiveDownloadWithURL:url];''', 1)

start_marker = '/*\n 1.接收到服务器返回的数据\n'
end_marker = '- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code\n'
if start_marker not in src or end_marker not in src:
    raise SystemExit('PubgLoad download-engine section markers missing')

replacement = r'''#pragma mark - P67 remote download orchestration

- (void)presentRemoteDownloadProgressReceived:(int64_t)received expected:(int64_t)expected
{
    JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
    if (expected > 0 && expected != NSURLSessionTransferSizeUnknown) {
        float progress = MAX(0.0f, MIN(1.0f, (float)received / (float)expected));
        if (progress < 1.0f) {
            [presenter updateText:[NSString stringWithFormat:@"请耐心等待,下载中... %.0f%%", progress * 100.0f]];
            [presenter displayProgressBarWithPercentage:progress];
        }
    } else {
        double downloadedMB = (double)received / (1024.0 * 1024.0);
        [presenter updateText:[NSString stringWithFormat:@"请耐心等待,下载中... %.1f MB", downloadedMB]];
    }
}

- (void)startArchiveDownloadWithURL:(NSURL *)url
{
    if (!url) {
        [SVProgressHUD showErrorWithStatus:@"下载链接无效"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }

    [[ZONRemoteDownloadService sharedService]
     downloadArchiveFromURL:url
     progress:^(int64_t receivedBytes, int64_t expectedBytes) {
        [self presentRemoteDownloadProgressReceived:receivedBytes expected:expectedBytes];
     }
     completion:^(NSString *archivePath, NSError *downloadError) {
        if (downloadError || archivePath.length == 0) {
            [[JDStatusBarNotificationPresenter sharedPresenter] dismissAnimated:YES];
            [SVProgressHUD showErrorWithStatus:downloadError.localizedDescription ?: @"下载失败"];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }

        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"下载成功，正在恢复存档..."
                 dismissAfterDelay:0
                   includedStyle:JDStatusBarNotificationIncludedStyleSuccess];

        [[ZONRestoreService sharedService]
         restoreArchiveAtPath:archivePath
         inboxPath:nil
         completion:^(BOOL success, NSError *restoreError) {
            [presenter dismissAnimated:YES];
            if (!success) {
                [SVProgressHUD showErrorWithStatus:restoreError.localizedDescription ?: @"恢复失败"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }
            if (restoreError.code == ZONRestoreErrorCleanupFailed) {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
            } else {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
            }

            // P67A_RESTORE_P66_POST_SUCCESS: preserve the P66/yidongwenjian success tail.
            // PreferenceManager reloads restored preferences, synchronizes them, performs legacy cleanup,
            // and terminates the game after successful synchronization.
            [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];
        }];
     }];
}

'''
prefix, rest = src.split(start_marker, 1)
_, suffix = rest.split(end_marker, 1)
src = prefix + replacement + end_marker + suffix

cleanup_start = '- (void)cleanupTemporaryFiles {'
if cleanup_start in src:
    before, tail = src.split(cleanup_start, 1)
    if '\n@end' not in tail:
        raise SystemExit('PubgLoad @end missing after cleanupTemporaryFiles')
    _, after_end = tail.split('\n@end', 1)
    cleanup = r'''- (void)cleanupTemporaryFiles
{
    // P67 intentionally does not enumerate or clear the application's entire /tmp tree.
    // ZONRestoreService owns /tmp/zonoe and removes the selected downloaded archive after restore.
    NSString *stagingRoot = [[ZONRestoreService sharedService] restoreStagingRootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stagingRoot]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:stagingRoot error:&error]) {
            NSLog(@"P67 staging cleanup failed %@: %@", stagingRoot, error.localizedDescription);
        }
    }
}
'''
    src = before + cleanup + '\n@end' + after_end
PUBG.write_text(src, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count('ZONRemoteDownloadService.m in Sources') != 2:
    raise SystemExit('P67 service PBX marker invariant failed')
final_src = PUBG.read_text(encoding='utf-8')
for marker in [
    '#import "ZONRemoteDownloadService.h"',
    '#import "ZONRestoreService.h"',
    '#import "PreferenceManager.h"',
    '[ZONRemoteDownloadService sharedService]',
    '[ZONRestoreService sharedService]',
    'downloadArchiveFromURL:url',
    'restoreArchiveAtPath:archivePath',
    'startArchiveDownloadWithURL:downloadURL',
    'P67A_RESTORE_P66_POST_SUCCESS',
    '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]',
]:
    if marker not in final_src:
        raise SystemExit(f'missing P67/P67a migrated marker: {marker}')
for forbidden in [
    'downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:',
    'URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:',
    'NSDirectoryEnumerator *enumerator1 = [[NSFileManager defaultManager] enumeratorAtPath:LibraryPath]',
    'P67A_POST_RESTORE_EXIT',
]:
    if forbidden in final_src:
        raise SystemExit(f'legacy or incorrect P67a marker remains: {forbidden}')

print('P67a remote download post-restore compatibility migration applied successfully')
