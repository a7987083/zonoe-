#import "ZONSaveTransferCoordinator.h"
#import "ZONRemoteRestoreCoordinator.h"
#import "ZONRestoreAPI.h"
#import "ZONCloudSaveService.h"
#import "ZONRuntimeDirectoryService.h"
#import "getKeychain.h"
#import "WX_NongShiFu123.h"
#import "Config.h"
#import "SVProgressHUD.h"
#import "JDStatusBarNotification.h"

@implementation ZONSaveTransferCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONSaveTransferCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [[ZONSaveTransferCoordinator alloc] init]; });
    return coordinator;
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
        [[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:[NSURL URLWithString:text]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentCloudSaveFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) return;
    [ZONRuntimeDirectoryService ensureTemporaryDirectory];
    [SVProgressHUD showWithStatus:@"正在检查云存档文件..."];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    [[ZONCloudSaveService sharedService]
     fetchMetadataForBundleIdentifier:bundleID ?: @""
     metadataBaseURLString:homeurl ?: @""
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
                                                                   message:@"你没有购买\n请先购买再尝试解锁"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"购买解锁码" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址] options:@{} completionHandler:^(__unused BOOL success) { exit(0); }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)handleCloudFunction:(NSDictionary *)functionDictionary
           bundleIdentifier:(NSString *)bundleIdentifier
         hostViewController:(UIViewController *)hostViewController
{
    NSString *deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
    NSString *downloadAddress = [[ZONCloudSaveService sharedService] effectiveDownloadAddressForFunction:functionDictionary];
    BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

    [[ZONCloudSaveService sharedService]
     resolveDownloadURLForBundleIdentifier:bundleIdentifier
     downloadAddress:downloadAddress
     archiveBaseURLString:homezip ?: @""
     deviceIdentifier:deviceIdentifier
     entitlementBaseURLString:@"https://app.zonoeios.xyz/index/index/apiface?udid="
     bypassEntitlement:testMode
     completion:^(NSURL *downloadURL, NSError *error) {
        if (error || !downloadURL) {
            if (error.code == ZONCloudSaveErrorEntitlementDenied) {
                [self presentCloudEntitlementDeniedFromViewController:hostViewController];
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
        [self cleanupRestoreStaging];
        [[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:downloadURL];
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
