#import "ZONFeatureDispatcher.h"
#import "ZONFeatureRegistry.h"
#import "SandboxBrowserVC.h"
#import "daochucd.h"
#import "YYYPicker.h"
#import "PubgLoad.h"
#import "ImgTool.h"
#import "SVProgressHUD.h"
#import "WX_NongShiFu123.h"

typedef BOOL (^ZONFeatureActionHandler)(UIViewController *hostViewController);
typedef BOOL (^ZONFeatureToggleHandler)(BOOL on);

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

        if (ZONEnsureTmpDirectory()) {
            NSArray<NSString *> *tmpChildren = [manager contentsOfDirectoryAtPath:tmpPath error:nil];
            for (NSString *child in tmpChildren) {
                [manager removeItemAtPath:[tmpPath stringByAppendingPathComponent:child] error:nil];
            }
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

        ZONEnsureTmpDirectory();
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(0);
    });
}

typedef void (^ZONDestructiveConfirmationHandler)(void);
typedef void (^ZONRuntimeToggleSideEffect)(BOOL on);

static void ZONPresentDestructiveConfirmation(UIViewController *hostViewController,
                                              NSString *title,
                                              NSString *message,
                                              ZONDestructiveConfirmationHandler handler)
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

void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    ZONPresentDestructiveConfirmation(hostViewController,
                                      @"清除游戏数据",
                                      @"此操作会清除本地游戏数据，且不可恢复。\n确定要继续吗？",
                                      ^{
        [SVProgressHUD showWithStatus:@"处理中..."];
        ZONClearGameDataPreservingTmp();
    });
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    ZONPresentDestructiveConfirmation(hostViewController,
                                      @"清除授权记录",
                                      @"此操作会删除授权信息，删除后需要重新授权。\n确定继续吗？",
                                      ^{
        [[WX_NongShiFu123 alloc] deletekm];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    });
}

static void ZONApplyRuntimeToggle(NSUserDefaults *defaults,
                                  NSString *integerKey,
                                  NSString *booleanKey,
                                  BOOL on,
                                  ZONRuntimeToggleSideEffect sideEffect)
{
    [defaults setInteger:on forKey:integerKey];
    [defaults setBool:on forKey:booleanKey];
    [defaults synchronize];
    if (sideEffect) sideEffect(on);
}

static NSDictionary<NSString *, ZONFeatureActionHandler> *ZONActionRoutes(void)
{
    static NSDictionary<NSString *, ZONFeatureActionHandler> *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            @"base.remote-download": ^BOOL(__unused UIViewController *host) {
                [[PubgLoad alloc] yuanchengdwon];
                return YES;
            },
            @"base.cloud-save": ^BOOL(__unused UIViewController *host) {
                ZONEnsureTmpDirectory();
                [[PubgLoad alloc] checkCloudSaveStatus];
                return YES;
            },
            @"base.local-files": ^BOOL(UIViewController *host) {
                SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                if (@available(iOS 13.0, *)) {
                    nav.modalPresentationStyle = UIModalPresentationPageSheet;
                } else {
                    nav.modalPresentationStyle = UIModalPresentationFullScreen;
                }
                [host presentViewController:nav animated:YES completion:nil];
                return YES;
            },
            @"data.backup-save": ^BOOL(__unused UIViewController *host) {
                [[daochucd alloc] backupasd];
                return YES;
            },
            @"data.restore-save": ^BOOL(__unused UIViewController *host) {
                [[YYYPicker alloc] addBtnAction];
                return YES;
            },
            @"data.clear-game-data": ^BOOL(UIViewController *host) {
                ZONPresentClearGameDataConfirmation(host);
                return YES;
            },
            @"auth.clear-records": ^BOOL(UIViewController *host) {
                ZONPresentClearAuthorizationConfirmation(host);
                return YES;
            },
        };
    });
    return routes;
}

static NSDictionary<NSString *, ZONFeatureToggleHandler> *ZONToggleRoutes(void)
{
    static NSDictionary<NSString *, ZONFeatureToggleHandler> *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            @"runtime.iap-noads": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"NNGG", @"NNGGNNGG", on,
                                      ^(BOOL enabled) { [ImgTool share].NeiGou = enabled; });
                return YES;
            },
            @"runtime.ad-speed": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"AADD", @"AADDAADD", on,
                                      ^(BOOL enabled) { [ImgTool share].ADSpeed = enabled; });
                return YES;
            },
        };
    });
    return routes;
}

/// Routes registry-owned actions. Registry metadata remains the source of truth;
/// route tables only map a registered identifier to its existing implementation.
BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                            UIViewController *hostViewController)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureActionHandler handler = ZONActionRoutes()[identifier];
    return handler ? handler(hostViewController) : NO;
}

/// Toggle dispatch preserves the exact UserDefaults keys, synchronize call and
/// ImgTool side effects used by the promoted P49 runtime.
BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureToggleHandler handler = ZONToggleRoutes()[identifier];
    return handler ? handler(on) : NO;
}
