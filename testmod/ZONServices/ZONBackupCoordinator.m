#import "ZONBackupCoordinator.h"
#import "ZONBackupService.h"
#import "SVProgressHUD.h"

@interface ZONBackupCoordinator () <UIDocumentInteractionControllerDelegate>
@property (nonatomic, weak) UIViewController *hostViewController;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;
@end

@implementation ZONBackupCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONBackupCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [[ZONBackupCoordinator alloc] init];
    });
    return coordinator;
}

- (UIViewController *)topmostViewController
{
    UIViewController *host = self.hostViewController;
    while (host.presentedViewController) {
        host = host.presentedViewController;
    }
    return host;
}

- (void)presentBackupFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) {
        NSLog(@"❌ 无可用控制器展示备份入口");
        return;
    }

    self.hostViewController = hostViewController;
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

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSString *backupName = alert.textFields.firstObject.text;
        if (backupName.length == 0) backupName = NSBundle.mainBundle.bundleIdentifier;
        [self startBackupNamed:backupName ?: @""];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void)requestBackupDecisionForRelativePath:(NSString *)relativePath
                                         size:(unsigned long long)size
                                   completion:(ZONBackupLargeItemDecisionReply)completion
{
    UIViewController *host = [self topmostViewController];
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
                                           handler:^(__unused UIAlertAction *action) {
        if (completion) completion(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"备份"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        if (completion) completion(NO);
    }]];
    [host presentViewController:alert animated:YES completion:nil];
}

- (void)showProgressForStage:(ZONBackupStage)stage fraction:(double)fraction
{
    switch (stage) {
        case ZONBackupStagePreparing:
            [SVProgressHUD showProgress:0 status:@"准备备份..."];
            break;
        case ZONBackupStageScanning:
            [SVProgressHUD showProgress:fraction status:@"扫描备份数据..."];
            break;
        case ZONBackupStageCopyingDocuments:
            [SVProgressHUD showProgress:fraction status:[NSString stringWithFormat:@"拷贝 Documents %.0f%%", fraction * 100.0]];
            break;
        case ZONBackupStageCopyingLibrary:
            [SVProgressHUD showProgress:fraction status:[NSString stringWithFormat:@"拷贝 Library %.0f%%", fraction * 100.0]];
            break;
        case ZONBackupStageArchiving:
            [SVProgressHUD showProgress:fraction status:@"开始压缩..."];
            break;
        case ZONBackupStageCompleted:
            break;
    }
}

- (void)startBackupNamed:(NSString *)backupName
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
        [self requestBackupDecisionForRelativePath:relativePath size:size completion:reply];
    }
                               progress:^(ZONBackupStage stage, __unused NSString *detail, double fraction) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self showProgressForStage:stage fraction:fraction];
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

- (void)shareArchiveAtURL:(NSURL *)archiveURL
{
    if (!archiveURL) return;
    UIViewController *host = [self topmostViewController];
    if (!host || !host.view) {
        NSLog(@"❌ 无可用控制器展示备份分享菜单");
        return;
    }

    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:archiveURL];
    self.documentController.delegate = self;
    [self.documentController presentOptionsMenuFromRect:host.view.bounds inView:host.view animated:YES];
}

- (void)cleanupBackupArtifacts
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *outputDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zonoe"];
    NSString *stagingDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];

    NSError *error = nil;
    if ([manager fileExistsAtPath:outputDirectory] && ![manager removeItemAtPath:outputDirectory error:&error]) {
        NSLog(@"⚠️ 清理备份输出目录失败 %@: %@", outputDirectory, error.localizedDescription);
    }

    error = nil;
    if ([manager fileExistsAtPath:stagingDirectory] && ![manager removeItemAtPath:stagingDirectory error:&error]) {
        NSLog(@"⚠️ 清理备份临时目录失败 %@: %@", stagingDirectory, error.localizedDescription);
    }
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(__unused UIDocumentInteractionController *)controller
{
    return [self topmostViewController];
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
    self.documentController = nil;
}

@end
