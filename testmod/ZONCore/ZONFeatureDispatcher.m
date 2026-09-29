#import "ZONFeatureDispatcher.h"
#import "ZONFeatureRegistry.h"
#import "ImgTool.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONServices/ZONSixButtonActionService.h"
#import "../ZONServices/ZONRuntimeDirectoryService.h"
#import "../ZONServices/ZONResetCoordinator.h"
#import "../ZONServices/ZONLocalFilesCoordinator.h"

typedef BOOL (^ZONFeatureActionHandler)(UIViewController *hostViewController);
typedef BOOL (^ZONFeatureToggleHandler)(BOOL on);
typedef void (^ZONRuntimeToggleSideEffect)(BOOL on);

#pragma mark - Compatibility C surface

NSString *ZONTmpDirectoryPath(void)
{
    return [ZONRuntimeDirectoryService temporaryDirectoryPath];
}

BOOL ZONEnsureTmpDirectory(void)
{
    return [ZONRuntimeDirectoryService ensureTemporaryDirectory];
}

void ZONClearGameDataPreservingTmp(void)
{
    [[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];
}

void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    [[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    [[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];
}

#pragma mark - Permission helpers

static NSDictionary<NSString *, id> *ZONCurrentServerPermissions(void)
{
    NSDictionary *verify = [ZONAuthV2Storage lastVerify];
    NSDictionary *permissions = [verify[@"permissions"] isKindOfClass:NSDictionary.class] ? verify[@"permissions"] : nil;
    return permissions ?: @{};
}

static void ZONPresentPermissionDenied(UIViewController *hostViewController, NSString *featureTitle)
{
    if (!hostViewController) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"当前授权不包含%@权限。", featureTitle.length ? featureTitle : @"该功能"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"权限不足"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [hostViewController presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Runtime toggles

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

#pragma mark - Action routes

static NSDictionary<NSString *, ZONFeatureActionHandler> *ZONActionRoutes(void)
{
    static NSDictionary<NSString *, ZONFeatureActionHandler> *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            @"base.remote-download": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performRemoteDownloadFromViewController:host];
            },
            @"base.cloud-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performCloudSaveFromViewController:host];
            },
            @"base.local-files": ^BOOL(UIViewController *host) {
                return [[ZONLocalFilesCoordinator sharedCoordinator] presentLocalFilesFromViewController:host];
            },
            @"data.backup-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performBackupSaveFromViewController:host];
            },
            @"data.restore-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performRestoreSaveFromViewController:host];
            },
            @"data.clear-game-data": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performClearGameDataFromViewController:host];
            },
            @"auth.clear-records": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performClearAuthorizationFromViewController:host];
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
/// route tables only map a registered identifier to its service boundary.
BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                            UIViewController *hostViewController)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSDictionary *permissions = ZONCurrentServerPermissions();
    if (!ZONFeatureIsActionAllowedWithPermissions(feature, permissions)) {
        NSLog(@"[zonoemenu][P79.8C_ACTION_PERMISSION] denied feature=%@ required=%@",
              feature[ZONFeatureIdentifierKey] ?: @"",
              feature[ZONFeatureRequiredActionPermissionKey] ?: @"");
        ZONPresentPermissionDenied(hostViewController, feature[ZONFeatureTitleKey]);
        // The route is handled even when denied, preventing any legacy fallback
        // from reaching the protected action by tag.
        return YES;
    }

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureActionHandler handler = ZONActionRoutes()[identifier];
    return handler ? handler(hostViewController) : NO;
}

/// Toggle dispatch preserves the exact UserDefaults keys, synchronize call and
/// ImgTool side effects used by the promoted runtime.
BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureToggleHandler handler = ZONToggleRoutes()[identifier];
    return handler ? handler(on) : NO;
}
