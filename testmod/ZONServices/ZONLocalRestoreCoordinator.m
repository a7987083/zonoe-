#import "ZONLocalRestoreCoordinator.h"
#import "NKSeleDocumentTool.h"
#import "SVProgressHUD.h"
#import "ZONRestoreAPI.h"

@implementation ZONLocalRestoreCoordinator

+ (instancetype)sharedCoordinator
{
    static ZONLocalRestoreCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [[self alloc] init];
    });
    return coordinator;
}

- (void)presentRestoreResult:(BOOL)success error:(NSError *)error
{
    if (!success) {
        NSString *message = error.localizedDescription.length ? error.localizedDescription : @"恢复失败";
        [SVProgressHUD showErrorWithStatus:message];
        return;
    }

    // A successful restore normally terminates through ZONRestoreAPI's preserved
    // P66 post-success tail. This is only a fallback if PreferenceManager returns.
    if (error.code == ZONRestoreErrorCleanupFailed) {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
    } else {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
    }
}

- (void)restoreSelectedURL:(NSURL *)fileURL
{
    if (!fileURL) return;

    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    ZONRestoreAPI *api = [ZONRestoreAPI sharedAPI];
    NSString *inboxPath = [api restoreInboxPathForBundleIdentifier:bundleIdentifier ?: @""];
    NSString *archivePath = fileURL.path;

    if (![[NSFileManager defaultManager] fileExistsAtPath:archivePath]) {
        NSString *decodedFileName = [[[fileURL absoluteString] componentsSeparatedByString:@"/"] lastObject].stringByRemovingPercentEncoding;
        archivePath = [inboxPath stringByAppendingPathComponent:decodedFileName ?: @""];
    }

    [SVProgressHUD showWithStatus:@"处理中..."];
    [api restoreArchiveAtPath:archivePath inboxPath:inboxPath completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

- (void)presentLocalRestoreFromViewController:(UIViewController *)hostViewController
{
    [self presentLocalRestoreFromViewController:hostViewController selectionHandler:nil];
}

- (void)presentLocalRestoreFromViewController:(UIViewController *)hostViewController
                             selectionHandler:(ZONLocalRestoreSelectionHandler)selectionHandler
{
    if (!hostViewController) {
        [SVProgressHUD showErrorWithStatus:@"无法打开文件选择器"];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[NKSeleDocumentTool shareDocumentTool]
         seleDocumentWithDocumentTypes:@[@"public.data"]
         Mode:UIDocumentPickerModeImport
         controller:hostViewController
         finishBlock:^(NSArray<NSURL *> *urls) {
            NSURL *selectedURL = urls.firstObject;
            if (!selectedURL) return;
            if (selectionHandler) selectionHandler(selectedURL);
            [self restoreSelectedURL:selectedURL];
        }];
    });
}

- (void)restorePreparedArchiveStaging
{
    ZONRestoreAPI *api = [ZONRestoreAPI sharedAPI];
    NSString *stagingRoot = [api restoreStagingRootPath];
    [api restorePreparedStagingAtPath:stagingRoot completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

@end
