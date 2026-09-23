#import "ZONRemoteRestoreCoordinator.h"
#import "ZONRemoteDownloadService.h"
#import "ZONRestoreAPI.h"
#import "SVProgressHUD.h"
#import "JDStatusBarNotification.h"

@implementation ZONRemoteRestoreCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONRemoteRestoreCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [[ZONRemoteRestoreCoordinator alloc] init]; });
    return coordinator;
}

- (void)presentProgressReceived:(int64_t)received expected:(int64_t)expected
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
        [self presentProgressReceived:receivedBytes expected:expectedBytes];
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

@end
