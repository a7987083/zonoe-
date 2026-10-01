#import "ZONSaveTransferCoordinator.h"
#import "ZONRemoteDownloadService.h"
#import "ZONRestoreAPI.h"
#import "ZONCloudSaveService.h"
#import "ZONRuntimeDirectoryService.h"
#import "ZONFeatureAccessProvider.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONAuthV2/ZONAuthV2API.h"
#import "../ZONAuthV2/ZONAuthV2Verify.h"
#import "getKeychain.h"
#import "SVProgressHUD.h"
#import "JDStatusBarNotification.h"

static NSString * const ZONCloudMetadataBaseURLString = @"https://yun.zonoeios.xyz/d/a/json/";
static NSString * const ZONCloudArchiveBaseURLString = @"https://yun.zonoeios.xyz/d/a/yuncundang/";

static NSString *ZONStringValue(NSDictionary *dictionary, NSString *key)
{
    id value = [dictionary isKindOfClass:NSDictionary.class] ? dictionary[key] : nil;
    return [value isKindOfClass:NSString.class] ? value : @"";
}

static BOOL ZONCloudLicenseIsActive(NSDictionary *license)
{
    if (![license isKindOfClass:NSDictionary.class]) return NO;
    NSInteger code = [license[@"code"] respondsToSelector:@selector(integerValue)] ? [license[@"code"] integerValue] : 0;
    NSString *msg = [license[@"msg"] isKindOfClass:NSString.class] ? license[@"msg"] : @"";
    NSTimeInterval expire = [license[@"expire"] respondsToSelector:@selector(doubleValue)] ? [license[@"expire"] doubleValue] : 0;
    return code == 1 && [msg.lowercaseString isEqualToString:@"ok"] && expire > NSDate.date.timeIntervalSince1970;
}

static NSString *ZONPurchaseURLString(void)
{
    NSDictionary *verify = [ZONAuthV2Storage lastVerify];
    NSString *url = ZONStringValue(verify, @"purchase_url");
    if (!url.length) url = ZONStringValue(verify, @"software_url");
    if (url.length) return url;

    NSDictionary *runtimeConfig = [ZONAuthV2Storage lastRuntimeConfig];
    url = ZONStringValue(runtimeConfig, @"purchase_url");
    if (!url.length) url = ZONStringValue(runtimeConfig, @"software_url");
    return url;
}

@implementation ZONSaveTransferCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONSaveTransferCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [[ZONSaveTransferCoordinator alloc] init]; });
    return coordinator;
}

- (BOOL)cloudPermissionGrantedInVerifyResponse:(NSDictionary *)response
{
    if (![response isKindOfClass:NSDictionary.class] || ![response[@"ok"] boolValue]) return NO;
    NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";
    if ([action isEqualToString:@"block"] || [action isEqualToString:@"disable_feature"]) return NO;
    NSDictionary *permissions = [ZONFeatureAccessProvider effectivePermissionsForVerifyResponse:response];
    return [permissions[@"extra_features"] boolValue];
}

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

        [[ZONRestoreAPI sharedAPI]
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
        }];
     }];
}

- (void)presentRemoteDownloadFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"远程下载存档"
                                                                   message:@"✅支持本菜单备份的zip文件"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"请填写下载地址";
        textField.secureTextEntry = NO;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.layer.masksToBounds = YES;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        if (text.length == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentRemoteDownloadFromViewController:hostViewController];
            });
            return;
        }
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"准备下载存档,请稍后."
                 dismissAfterDelay:10
                     includedStyle:JDStatusBarNotificationIncludedStyleWarning];
        [self startArchiveDownloadWithURL:[NSURL URLWithString:text]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentCloudSaveFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) return;

    NSDictionary *sessionVerify = [ZONAuthV2Storage lastVerify];
    if (![self cloudPermissionGrantedInVerifyResponse:sessionVerify]) {
        NSLog(@"[zonoemenu][P79.8K2_CLOUD_PERMISSION] session permission denied before cloud menu");
        [self presentCloudEntitlementDeniedFromViewController:hostViewController];
        return;
    }

    [ZONRuntimeDirectoryService ensureTemporaryDirectory];
    [SVProgressHUD showWithStatus:@"正在检查云存档文件..."];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    [[ZONCloudSaveService sharedService]
     fetchMetadataForBundleIdentifier:bundleID ?: @""
     metadataBaseURLString:ZONCloudMetadataBaseURLString
     completion:^(NSDictionary *metadata, NSError *error) {
        [SVProgressHUD dismiss];
        if (error || !metadata) {
            NSString *message = error.localizedDescription ?: @"未查询到数据";
            if (error.code == ZONCloudSaveErrorNoArchive) [SVProgressHUD showWithStatus:message];
            else [SVProgressHUD showErrorWithStatus:message];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }
        [self presentCloudSaveAlertWithJSON:metadata hostViewController:hostViewController];
     }];
}

- (void)presentCloudSaveAlertWithJSON:(NSDictionary *)metadata hostViewController:(UIViewController *)hostViewController
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
        [alert addAction:[UIAlertAction actionWithTitle:buttonName style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self handleCloudFunction:functionDictionary bundleIdentifier:bundleID hostViewController:hostViewController];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentCloudEntitlementDeniedFromViewController:(UIViewController *)hostViewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"当前授权不包含 VIP云存档权限"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    NSString *purchaseURLString = ZONPurchaseURLString();
    NSURL *purchaseURL = purchaseURLString.length ? [NSURL URLWithString:purchaseURLString] : nil;
    if (purchaseURL) {
        [alert addAction:[UIAlertAction actionWithTitle:@"购买解锁码" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:purchaseURL options:@{} completionHandler:nil];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)handleCloudFunction:(NSDictionary *)functionDictionary
           bundleIdentifier:(NSString *)bundleIdentifier
         hostViewController:(UIViewController *)hostViewController
{
    NSString *deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
    NSDictionary *runtimeConfig = [ZONAuthV2Storage lastRuntimeConfig];
    if (deviceIdentifier.length < 5 || ![runtimeConfig isKindOfClass:NSDictionary.class] || runtimeConfig.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"云存档验证上下文不可用，请重新启动后再试"];
        [SVProgressHUD dismissWithDelay:3.0];
        return;
    }

    NSString *downloadAddress = [[ZONCloudSaveService sharedService] effectiveDownloadAddressForFunction:functionDictionary];
    [SVProgressHUD showWithStatus:@"正在刷新设备授权..."];

    // auth_proof is deliberately one-shot/session-only and is consumed by startup Verify.
    // A fresh cloud-sensitive action must re-read /apiface so it gets both the current
    // authorization projection and a new short-lived proof before Challenge/Verify.
    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:deviceIdentifier completion:^(NSDictionary *license, NSError *licenseError) {
        if (licenseError || !ZONCloudLicenseIsActive(license)) {
            [SVProgressHUD dismiss];
            NSString *message = licenseError.localizedDescription ?: @"当前设备授权无效或已到期";
            [SVProgressHUD showErrorWithStatus:message];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }

        [SVProgressHUD showWithStatus:@"正在验证云存档权限..."];
        [[ZONAuthV2Verify sharedVerifier]
         verifyUDID:deviceIdentifier
         runtimeConfig:runtimeConfig
         completion:^(NSDictionary *response, NSError *verifyError) {
            [SVProgressHUD dismiss];
            BOOL allowed = [self cloudPermissionGrantedInVerifyResponse:response];
            NSString *accessLevel = [response[@"access_level"] isKindOfClass:NSString.class] ? response[@"access_level"] : @"";
            NSDictionary *permissions = [ZONFeatureAccessProvider effectivePermissionsForVerifyResponse:response];
            NSLog(@"[zonoemenu][P79.8K2_CLOUD_PERMISSION] fresh_verify allowed=%d access_level=%@ extra_features=%d error=%@",
                  allowed,
                  accessLevel,
                  [permissions[@"extra_features"] boolValue],
                  verifyError ? verifyError.domain : @"none");

            if (verifyError) {
                [SVProgressHUD showErrorWithStatus:verifyError.localizedDescription ?: @"云存档权限验证失败"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }
            if (!allowed) {
                [self presentCloudEntitlementDeniedFromViewController:hostViewController];
                return;
            }

            [ZONAuthV2Storage setLastVerify:response];

            [[ZONCloudSaveService sharedService]
             resolveDownloadURLForBundleIdentifier:bundleIdentifier
             downloadAddress:downloadAddress
             archiveBaseURLString:ZONCloudArchiveBaseURLString
             deviceIdentifier:deviceIdentifier
             entitlementBaseURLString:@""
             bypassEntitlement:YES
             completion:^(NSURL *downloadURL, NSError *error) {
                if (error || !downloadURL) {
                    [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"云存档下载地址解析失败"];
                    [SVProgressHUD dismissWithDelay:3.0];
                    return;
                }
                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                [presenter dismissAnimated:YES];
                [presenter presentWithText:@"准备下载存档,请稍后."
                         dismissAfterDelay:0
                             includedStyle:JDStatusBarNotificationIncludedStyleWarning];
                [self cleanupRestoreStaging];
                [self startArchiveDownloadWithURL:downloadURL];
             }];
         }];
    }];
}

- (void)cleanupRestoreStaging
{
    NSString *stagingRoot = [[ZONRestoreAPI sharedAPI] restoreStagingRootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stagingRoot]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:stagingRoot error:&error]) {
            NSLog(@"P69 staging cleanup failed %@: %@", stagingRoot, error.localizedDescription);
        }
    }
}

@end
