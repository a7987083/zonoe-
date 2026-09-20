#import "ZONSixButtonActionService.h"
#import "ZONAuthorizationResetService.h"
#import "PubgLoad.h"
#import "daochucd.h"
#import "YYYPicker.h"
#import "SVProgressHUD.h"
#import <stdlib.h>

typedef void (^ZONDestructiveConfirmationHandler)(void);

@implementation ZONSixButtonActionService

#pragma mark - Shared legacy invariants

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

+ (void)clearGameDataPreservingTemporaryDirectory
{
    // Preserve the exact promoted P62 timing and destructive-data behavior.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSFileManager *manager = NSFileManager.defaultManager;
        NSString *tmpPath = [self temporaryDirectoryPath];

        if ([self ensureTemporaryDirectory]) {
            NSArray<NSString *> *tmpChildren = [manager contentsOfDirectoryAtPath:tmpPath error:nil];
            for (NSString *child in tmpChildren) {
                [manager removeItemAtPath:[tmpPath stringByAppendingPathComponent:child] error:nil];
            }
            [self ensureTemporaryDirectory];
        }

        NSString *documentsPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
        NSLog(@"✈️删除 Documents, %@", documentsPath);
        [manager removeItemAtPath:documentsPath error:nil];

        NSString *libraryPath = [NSHomeDirectory() stringByAppendingString:@"/Library/"];
        NSLog(@"✈️删除 Library, %@", libraryPath);
        [manager removeItemAtPath:libraryPath error:nil];

        NSString *appDomain = NSBundle.mainBundle.bundleIdentifier;
        [NSUserDefaults.standardUserDefaults removePersistentDomainForName:appDomain];

        NSString *documentsRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSDirectoryEnumerator *documentsEnumerator = [manager enumeratorAtPath:documentsRoot];
        for (NSString *fileName in documentsEnumerator) {
            [manager removeItemAtPath:[documentsRoot stringByAppendingPathComponent:fileName] error:nil];
        }

        NSString *libraryRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        NSDirectoryEnumerator *libraryEnumerator = [manager enumeratorAtPath:libraryRoot];
        for (NSString *fileName in libraryEnumerator) {
            [manager removeItemAtPath:[libraryRoot stringByAppendingPathComponent:fileName] error:nil];
        }

        [self ensureTemporaryDirectory];
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(0);
    });
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

#pragma mark - Existing action adapters

+ (BOOL)performRemoteDownloadFromViewController:(__unused UIViewController *)hostViewController
{
    [[PubgLoad alloc] yuanchengdwon];
    return YES;
}

+ (BOOL)performCloudSaveFromViewController:(__unused UIViewController *)hostViewController
{
    // Preserve the promoted invariant: tmp exists before the legacy cloud-save flow begins.
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
        [SVProgressHUD showWithStatus:@"处理中..."];
        [self clearGameDataPreservingTemporaryDirectory];
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

@end
