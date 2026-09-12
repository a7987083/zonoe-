#import "ZONFeatureDispatcher.h"

NSString *ZONTmpDirectoryPath(void)
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}

/// Cloud-save invariant: the sandbox tmp directory must always exist before the
/// cloud-save flow starts. This is intentionally idempotent.
BOOL ZONEnsureTmpDirectory(void)
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *tmpPath = ZONTmpDirectoryPath();
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

/// Clear game data while preserving the sandbox tmp directory itself. Contents of
/// tmp are still cleared so the old "clear data" semantics remain as close as
/// possible, but cloud-save can continue to rely on the directory existing.
void ZONClearGameDataPreservingTmp(void)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSFileManager *manager = NSFileManager.defaultManager;
        NSString *tmpPath = ZONTmpDirectoryPath();

        // Preserve /tmp itself; only remove its children.
        if (ZONEnsureTmpDirectory()) {
            NSArray<NSString *> *tmpChildren = [manager contentsOfDirectoryAtPath:tmpPath error:nil];
            for (NSString *child in tmpChildren) {
                [manager removeItemAtPath:[tmpPath stringByAppendingPathComponent:child] error:nil];
            }
            // Re-assert the invariant in case a nested cleanup unexpectedly removed it.
            ZONEnsureTmpDirectory();
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

        // tmp must survive the clear operation.
        ZONEnsureTmpDirectory();
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(0);
    });
}

void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"清除游戏数据"
                                        message:@"此操作会清除本地游戏数据，且不可恢复。\n确定要继续吗？"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:nil];

    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleDestructive
                           handler:^(__unused UIAlertAction *action) {
        [SVProgressHUD showWithStatus:@"处理中..."];
        ZONClearGameDataPreservingTmp();
    }];

    [alert addAction:cancel];
    [alert addAction:confirm];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"清除授权记录"
                                        message:@"此操作会删除授权信息，删除后需要重新授权。\n确定继续吗？"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:nil];

    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleDestructive
                           handler:^(__unused UIAlertAction *action) {
        [[WX_NongShiFu123 alloc] deletekm];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];

    [alert addAction:cancel];
    [alert addAction:confirm];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

/// Routes registry-owned actions. All ten built-in features have completed staged
/// migration, so PopupMenuVC no longer carries per-tag compatibility fallbacks.
BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                                          UIViewController *hostViewController)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];

    if ([identifier isEqualToString:@"base.remote-download"]) {
        [[PubgLoad alloc] yuanchengdwon];
        return YES;
    }

    if ([identifier isEqualToString:@"base.cloud-save"]) {
        // Self-heal the tmp directory before any cloud-save checks/download work.
        ZONEnsureTmpDirectory();
        [[PubgLoad alloc] checkCloudSaveStatus];
        return YES;
    }

    if ([identifier isEqualToString:@"base.local-files"]) {
        SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

        if (@available(iOS 13.0, *)) {
            nav.modalPresentationStyle = UIModalPresentationPageSheet;
        } else {
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
        }

        [hostViewController presentViewController:nav animated:YES completion:nil];
        return YES;
    }

    if ([identifier isEqualToString:@"data.backup-save"]) {
        [[daochucd alloc] backupasd];
        return YES;
    }

    if ([identifier isEqualToString:@"data.restore-save"]) {
        [[YYYPicker alloc] addBtnAction];
        return YES;
    }

    if ([identifier isEqualToString:@"data.clear-game-data"]) {
        ZONPresentClearGameDataConfirmation(hostViewController);
        return YES;
    }

    if ([identifier isEqualToString:@"auth.clear-records"]) {
        ZONPresentClearAuthorizationConfirmation(hostViewController);
        return YES;
    }

    return NO;
}

/// Toggle/placeholder dispatch for registry-owned runtime controls. This preserves
/// the exact UserDefaults keys and ImgTool side effects previously used by PopupMenuVC.
BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;

    if ([identifier isEqualToString:@"runtime.iap-noads"]) {
        [ud setInteger:on forKey:@"NNGG"];
        [ud setBool:on forKey:@"NNGGNNGG"];
        [ud synchronize];
        [ImgTool share].NeiGou = on;
        return YES;
    }

    if ([identifier isEqualToString:@"runtime.ad-speed"]) {
        [ud setInteger:on forKey:@"AADD"];
        [ud setBool:on forKey:@"AADDAADD"];
        [ud synchronize];
        [ImgTool share].ADSpeed = on;
        return YES;
    }

    if ([identifier isEqualToString:@"runtime.placeholder-203"]) {
        NSLog(@"人物血量");
        return YES;
    }

    return NO;
}
