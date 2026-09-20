#import "daochucd.h"
#import "ZONBackupService.h"
#import "JHPP.h"
#import "SVProgressHUD.h"

typedef void (^ZONBackupDecisionCompletion)(BOOL skip);

@interface daochucd ()<UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *docVc;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end

@implementation daochucd

#pragma mark - Backup UI entry

- (void)backupasd
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请输入文件名字\n直接确定是BundID名字"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"在这里输入文件名字";
        textField.secureTextEntry = NO;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.layer.masksToBounds = YES;
    }];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        NSString *backupName = textField.text;
        if (backupName.length == 0) {
            backupName = NSBundle.mainBundle.bundleIdentifier;
        }
        [self bfcundang:backupName ?: @""];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Backup presentation adapter

- (void)requestBackupDecisionForRelativePath:(NSString *)relativePath
                                         size:(unsigned long long)size
                                   completion:(ZONBackupDecisionCompletion)completion
{
    UIViewController *host = [JHPP currentViewController];
    NSString *itemName = relativePath.lastPathComponent ?: relativePath;
    if (!host) {
        NSLog(@"⚠️ 无可用控制器展示大目录备份提示，默认跳过 %@", relativePath);
        if (completion) completion(YES);
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:[NSString stringWithFormat:@"备份 \"%@\" 大于 %.2f MB，是否跳过？", itemName, size / 1024.0 / 1024.0]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"跳过"
                                             style:UIAlertActionStyleCancel
                                           handler:^(__unused UIAlertAction * _Nonnull action) {
        if (completion) completion(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"备份"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction * _Nonnull action) {
        if (completion) completion(NO);
    }]];
    [host presentViewController:alert animated:YES completion:nil];
}

- (void)showProgressForStage:(ZONBackupStage)stage detail:(NSString *)detail fraction:(double)fraction
{
    switch (stage) {
        case ZONBackupStagePreparing:
            [SVProgressHUD showProgress:0 status:@"准备备份..."];
            break;
        case ZONBackupStageScanning:
            [SVProgressHUD showProgress:fraction status:@"扫描备份数据..."];
            break;
        case ZONBackupStageCopyingDocuments:
            [SVProgressHUD showProgress:fraction
                                 status:[NSString stringWithFormat:@"拷贝 Documents %.0f%%", fraction * 100.0]];
            break;
        case ZONBackupStageCopyingLibrary:
            [SVProgressHUD showProgress:fraction
                                 status:[NSString stringWithFormat:@"拷贝 Library %.0f%%", fraction * 100.0]];
            break;
        case ZONBackupStageArchiving:
            [SVProgressHUD showProgress:fraction status:@"开始压缩..."];
            break;
        case ZONBackupStageCompleted:
            break;
    }
}

- (void)bfcundang:(NSString *)backupName
{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showProgress:0 status:@"准备备份..."];

    __weak typeof(self) weakSelf = self;
    [ZONBackupService createBackupNamed:backupName
                      largeItemDecision:^(NSString *relativePath,
                                          unsigned long long size,
                                          ZONBackupLargeItemDecisionReply reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            reply(YES);
            return;
        }
        [self requestBackupDecisionForRelativePath:relativePath
                                             size:size
                                       completion:reply];
    }
                               progress:^(ZONBackupStage stage, NSString *detail, double fraction) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self showProgressForStage:stage detail:detail fraction:fraction];
    }
                             completion:^(NSURL *archiveURL, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if (archiveURL && !error) {
            [SVProgressHUD showSuccessWithStatus:@"备份完成"];
            [self shareArchiveAtURL:archiveURL];
        } else {
            NSLog(@"❌ 备份失败: %@", error);
            [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"备份失败"];
        }
    }];
}

#pragma mark - Share UI

- (void)shareArchiveAtURL:(NSURL *)archiveURL
{
    if (!archiveURL) return;

    self.docVc = [UIDocumentInteractionController interactionControllerWithURL:archiveURL];
    self.docVc.delegate = self;

    UIWindow *targetWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in UIApplication.sharedApplication.connectedScenes) {
            if (windowScene.activationState != UISceneActivationStateForegroundActive) continue;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    targetWindow = window;
                    break;
                }
            }
            if (targetWindow) break;
        }
    } else {
        targetWindow = UIApplication.sharedApplication.keyWindow;
    }

    UIViewController *rootVC = targetWindow.rootViewController;
    if (!targetWindow || !rootVC) {
        NSLog(@"❌ 无可用窗口展示备份分享菜单");
        return;
    }

    UIViewController *topmostVC = rootVC;
    while (topmostVC.presentedViewController) {
        topmostVC = topmostVC.presentedViewController;
    }
    [self.docVc presentOptionsMenuFromRect:topmostVC.view.bounds
                                    inView:topmostVC.view
                                  animated:YES];
}

- (void)cleanupBackupArtifacts
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *outputDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zonoe"];
    NSString *stagingDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];

    NSError *error = nil;
    if ([manager fileExistsAtPath:outputDirectory] &&
        ![manager removeItemAtPath:outputDirectory error:&error]) {
        NSLog(@"⚠️ 清理备份输出目录失败 %@: %@", outputDirectory, error.localizedDescription);
    }

    error = nil;
    if ([manager fileExistsAtPath:stagingDirectory] &&
        ![manager removeItemAtPath:stagingDirectory error:&error]) {
        NSLog(@"⚠️ 清理备份临时目录失败 %@: %@", stagingDirectory, error.localizedDescription);
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(__unused UIDocumentInteractionController *)controller
{
    return [JHPP currentViewController];
}

- (void)documentInteractionControllerWillBeginPreview:(__unused UIDocumentInteractionController *)controller
{
    NSLog(@"预览即将开始");
}

- (void)documentInteractionControllerDidEndPreview:(__unused UIDocumentInteractionController *)controller
{
    NSLog(@"预览已结束");
}

- (void)documentInteractionController:(__unused UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"即将发送到应用程序: %@", application);
}

- (void)documentInteractionController:(__unused UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application
{
    NSLog(@"已发送到应用程序: %@", application);
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(__unused UIDocumentInteractionController *)controller
{
    NSLog(@"“打开方式”菜单已取消");
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(__unused UIDocumentInteractionController *)controller
{
    NSLog(@"“操作”菜单已取消");
    [self cleanupBackupArtifacts];
}

@end
