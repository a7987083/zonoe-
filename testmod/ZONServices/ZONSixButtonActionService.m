#import "ZONSixButtonActionService.h"
#import "ZONAuthorizationResetService.h"
#import "ZONGameDataResetService.h"
#import "PubgLoad.h"
#import "daochucd.h"
#import "YYYPicker.h"
#import "SVProgressHUD.h"
#import <stdlib.h>

typedef void (^ZONDestructiveConfirmationHandler)(void);

@implementation ZONSixButtonActionService

#pragma mark - Shared helpers

+ (NSString *)temporaryDirectoryPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}

+ (BOOL)ensureTemporaryDirectory
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *tmpPath = [self temporaryDirectoryPath];
    BOOL isDirectory = NO;

    if ([manager fileExistsAtPath:tmpPath isDirectory:&isDirectory]) {
        if (isDirectory) return YES;
        [manager removeItemAtPath:tmpPath error:nil];
    }

    NSError *error = nil;
    BOOL created = [manager createDirectoryAtPath:tmpPath
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:&error];
    if (!created) {
        NSLog(@"❌ 创建 tmp 目录失败 %@: %@", tmpPath, error.localizedDescription);
    }
    return created;
}

+ (void)presentDestructiveConfirmationFromViewController:(UIViewController *)hostViewController
                                                   title:(NSString *)title
                                                 message:(NSString *)message
                                                 handler:(ZONDestructiveConfirmationHandler)handler
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(__unused UIAlertAction *action) {
        if (handler) handler();
    }]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

+ (NSString *)statusTextForGameDataResetStage:(ZONGameDataResetStage)stage
{
    switch (stage) {
        case ZONGameDataResetStagePreparing:
            return @"正在准备清理…";
        case ZONGameDataResetStageDocuments:
            return @"正在清理游戏存档…";
        case ZONGameDataResetStageLibrary:
            return @"正在清理游戏数据…";
        case ZONGameDataResetStageTemporary:
            return @"正在清理临时文件…";
        case ZONGameDataResetStagePreferences:
            return @"正在重置本地设置…";
        case ZONGameDataResetStageVerification:
            return @"正在检查清理结果…";
        case ZONGameDataResetStageCompleted:
            return @"清理完成，正在退出…";
    }
    return @"正在处理…";
}

#pragma mark - Existing action adapters

+ (BOOL)performRemoteDownloadFromViewController:(__unused UIViewController *)hostViewController
{
    [[PubgLoad alloc] yuanchengdwon];
    return YES;
}

+ (BOOL)performCloudSaveFromViewController:(__unused UIViewController *)hostViewController
{
    [self ensureTemporaryDirectory];
    [[PubgLoad alloc] checkCloudSaveStatus];
    return YES;
}

+ (BOOL)performBackupSaveFromViewController:(__unused UIViewController *)hostViewController
{
    [[daochucd alloc] backupasd];
    return YES;
}

+ (BOOL)performRestoreSaveFromViewController:(__unused UIViewController *)hostViewController
{
    [[YYYPicker alloc] addBtnAction];
    return YES;
}

+ (BOOL)performClearGameDataFromViewController:(UIViewController *)hostViewController
{
    [self presentDestructiveConfirmationFromViewController:hostViewController
                                                     title:@"清除游戏数据"
                                                   message:@"此操作会清除本地游戏数据，且不可恢复。\n确定要继续吗？"
                                                   handler:^{
        [SVProgressHUD showWithStatus:@"正在准备清理…"];

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSError *error = nil;
            BOOL success = [ZONGameDataResetService resetGameDataWithProgress:^(ZONGameDataResetStage stage) {
                NSString *status = [self statusTextForGameDataResetStage:stage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showWithStatus:status];
                });
            } error:&error];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [SVProgressHUD showWithStatus:@"清理完成，正在退出…"];
                    exit(0);
                }

                NSLog(@"❌ 清除游戏数据失败：%@", error);
                [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"清理失败，请重新尝试"];
            });
        });
    }];
    return YES;
}

+ (BOOL)performClearAuthorizationFromViewController:(UIViewController *)hostViewController
{
    [self presentDestructiveConfirmationFromViewController:hostViewController
                                                     title:@"清除授权记录"
                                                   message:@"此操作会删除授权信息，删除后需要重新授权。\n确定继续吗？"
                                                   handler:^{
        NSError *error = nil;
        BOOL cleared = [ZONAuthorizationResetService clearAuthorizationData:&error];
        if (!cleared) {
            NSLog(@"❌清除授权信息失败：%@", error);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];
    return YES;
}

#pragma mark - Compatibility surface

+ (void)clearGameDataPreservingTemporaryDirectory
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        BOOL success = [ZONGameDataResetService resetGameDataWithProgress:nil error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                exit(0);
            } else {
                NSLog(@"❌ 兼容入口清除游戏数据失败：%@", error);
            }
        });
    });
}

@end
