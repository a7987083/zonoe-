#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONCloudSaveService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONCloudSaveService.m'

for required in (PBX, PUBG, SERVICE_H, SERVICE_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B68000112F7B680100C0FFEE'
file_id = 'B68000122F7B680100C0FFEE'
name = 'ZONCloudSaveService.m'
path = 'testmod/ZONServices/ZONCloudSaveService.m'
build_anchor = '\t\tB67A00112F7B67A100C0FFEE /* ZONRestoreAPI.m in Sources */ = {isa = PBXBuildFile; fileRef = B67A00122F7B67A100C0FFEE /* ZONRestoreAPI.m */; };'
file_anchor = '\t\tB67A00122F7B67A100C0FFEE /* ZONRestoreAPI.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONRestoreAPI.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB67A00112F7B67A100C0FFEE /* ZONRestoreAPI.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'
if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P67a build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P67a file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P67a sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

src = PUBG.read_text(encoding='utf-8')
if '#import "ZONCloudSaveService.h"' not in src:
    anchor = '#import "ZONRestoreAPI.h"\n'
    if anchor not in src: raise SystemExit('P67a restore API import anchor missing')
    src = src.replace(anchor, anchor + '#import "ZONCloudSaveService.h"\n', 1)

# P68: collapse historical duplicate cloud entry onto the canonical path.
loadddd_start = '-(void)loadddd\n{'
loadddd_end = '#pragma mark ---获取时间\n'
if loadddd_start in src:
    before, tail = src.split(loadddd_start, 1)
    if loadddd_end not in tail: raise SystemExit('loadddd end marker missing')
    _, after = tail.split(loadddd_end, 1)
    replacement = '''-(void)loadddd\n{\n    // Legacy compatibility entry. P68 keeps a single cloud-save orchestration path.\n    [self checkCloudSaveStatus];\n}\n'''
    src = before + replacement + loadddd_end + after

# Entitlement policy now belongs to ZONCloudSaveService.
ent_start = '- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code\n'
ent_end = '-(void)yuanchengdwon\n'
if ent_start in src:
    before, tail = src.split(ent_start, 1)
    if ent_end not in tail: raise SystemExit('entitlement end marker missing')
    _, after = tail.split(ent_end, 1)
    src = before + ent_end + after

cloud_start = '- (void)checkCloudSaveStatus {'
cloud_end = '- (void)cleanupTemporaryFiles\n'
if cloud_start not in src or cloud_end not in src:
    raise SystemExit('P68 cloud section markers missing')

replacement = r'''- (void)checkCloudSaveStatus
{
    [SVProgressHUD showWithStatus:@"正在检查云存档文件..."];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    [[ZONCloudSaveService sharedService]
     fetchMetadataForBundleIdentifier:bundleID ?: @""
     metadataBaseURLString:homeurl ?: @""
     completion:^(NSDictionary *metadata, NSError *error) {
        [SVProgressHUD dismiss];
        if (error || !metadata) {
            NSString *message = error.localizedDescription ?: @"未查询到数据";
            if (error.code == ZONCloudSaveErrorNoArchive) {
                [SVProgressHUD showWithStatus:message];
            } else {
                [SVProgressHUD showErrorWithStatus:message];
            }
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }
        [self presentCloudSaveAlertWithJSON:metadata];
     }];
}

- (void)presentCloudSaveAlertWithJSON:(NSDictionary *)metadata
{
    NSString *mainTitle = [metadata[@"主标题"] isKindOfClass:[NSString class]] ? metadata[@"主标题"] : @"云存档";
    NSString *subTitle = [metadata[@"副标题"] isKindOfClass:[NSString class]] ? metadata[@"副标题"] : nil;
    NSArray *functions = [metadata[@"功能"] isKindOfClass:[NSArray class]] ? metadata[@"功能"] : @[];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:mainTitle message:subTitle preferredStyle:UIAlertControllerStyleAlert];
    for (id object in functions) {
        if (![object isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *functionDictionary = (NSDictionary *)object;
        NSString *buttonName = [functionDictionary[@"按钮名字"] isKindOfClass:[NSString class]] ? functionDictionary[@"按钮名字"] : @"云存档";
        UIAlertAction *action = [UIAlertAction actionWithTitle:buttonName style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self handleCloudFunction:functionDictionary bundleIdentifier:bundleID];
        }];
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)presentCloudEntitlementDenied
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"你没有购买\n请先购买再尝试解锁"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"购买解锁码" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址]
                                           options:@{}
                                 completionHandler:^(__unused BOOL success) {
            exit(0);
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[JHPP currentViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)handleCloudFunction:(NSDictionary *)functionDictionary bundleIdentifier:(NSString *)bundleIdentifier
{
    NSString *deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
    NSString *downloadAddress = [[ZONCloudSaveService sharedService] effectiveDownloadAddressForFunction:functionDictionary];

    [[ZONCloudSaveService sharedService]
     resolveDownloadURLForBundleIdentifier:bundleIdentifier
     downloadAddress:downloadAddress
     archiveBaseURLString:homezip ?: @""
     deviceIdentifier:deviceIdentifier
     entitlementBaseURLString:@"https://app.zonoeios.xyz/index/index/apiface?udid="
     completion:^(NSURL *downloadURL, NSError *error) {
        if (error || !downloadURL) {
            if (error.code == ZONCloudSaveErrorEntitlementDenied) {
                [self presentCloudEntitlementDenied];
            } else {
                [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"云存档验证失败"];
                [SVProgressHUD dismissWithDelay:3.0];
            }
            return;
        }

        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];
        [presenter presentWithText:@"准备下载存档,请稍后."
                 dismissAfterDelay:0
                   includedStyle:JDStatusBarNotificationIncludedStyleWarning];
        [self cleanupTemporaryFiles];
        [self startArchiveDownloadWithURL:downloadURL];
     }];
}

'''
before, tail = src.split(cloud_start, 1)
_, after = tail.split(cloud_end, 1)
src = before + replacement + cloud_end + after
PUBG.write_text(src, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
final_src = PUBG.read_text(encoding='utf-8')
if final_pbx.count('ZONCloudSaveService.m in Sources') != 2:
    raise SystemExit('P68 service PBX marker invariant failed')
for marker in [
    '#import "ZONCloudSaveService.h"',
    '[ZONCloudSaveService sharedService]',
    'fetchMetadataForBundleIdentifier:',
    'resolveDownloadURLForBundleIdentifier:',
    'effectiveDownloadAddressForFunction:',
    '[self checkCloudSaveStatus];',
    '[self startArchiveDownloadWithURL:downloadURL]',
]:
    if marker not in final_src:
        raise SystemExit(f'missing P68 migrated marker: {marker}')
for forbidden in [
    'isCloudEntitlementValidWithCode:',
    'dataTaskWithURL:url completionHandler:',
    'stringWithContentsOfURL:checkUrl',
    'BOOL testMode = NO;',
]:
    if forbidden in final_src:
        raise SystemExit(f'legacy cloud-save business marker remains: {forbidden}')

print('P68 cloud save service migration applied successfully')
