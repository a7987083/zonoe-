#import "ZONSixButtonActionService.h"
#import "ZONSaveTransferCoordinator.h"
#import "ZONBackupCoordinator.h"
#import "ZONLocalRestoreCoordinator.h"
#import "ZONResetCoordinator.h"
#import "ZONRuntimeDirectoryService.h"
#import "ZONRuntimeCapabilityService.h"
#import "ZONFeatureAccessProvider.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONAuthV2/ZONAuthV2API.h"
#import "../ZONAuthV2/ZONAuthV2Verify.h"
#import "getKeychain.h"
#import "SVProgressHUD.h"

static BOOL ZONModifierLicenseIsActive(NSDictionary *license)
{
    if (![license isKindOfClass:NSDictionary.class]) return NO;
    NSInteger code = [license[@"code"] respondsToSelector:@selector(integerValue)] ? [license[@"code"] integerValue] : 0;
    NSString *message = [license[@"msg"] isKindOfClass:NSString.class] ? license[@"msg"] : @"";
    NSTimeInterval expire = [license[@"expire"] respondsToSelector:@selector(doubleValue)] ? [license[@"expire"] doubleValue] : 0;
    return code == 1 && [message.lowercaseString isEqualToString:@"ok"] && expire > NSDate.date.timeIntervalSince1970;
}

static BOOL ZONModifierVerifyAllowsActivation(NSDictionary *response)
{
    if (![response isKindOfClass:NSDictionary.class] || ![response[@"ok"] boolValue]) return NO;
    NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";
    if ([action isEqualToString:@"block"] || [action isEqualToString:@"disable_feature"]) return NO;

    NSDictionary *permissions = [ZONFeatureAccessProvider effectivePermissionsForVerifyResponse:response];
    return [permissions[@"extra_features"] boolValue];
}


@implementation ZONSixButtonActionService

#pragma mark - Shared helpers

+ (NSString *)temporaryDirectoryPath
{
    return [ZONRuntimeDirectoryService temporaryDirectoryPath];
}

+ (BOOL)ensureTemporaryDirectory
{
    return [ZONRuntimeDirectoryService ensureTemporaryDirectory];
}


#pragma mark - Existing action adapters

+ (BOOL)performRemoteDownloadFromViewController:(UIViewController *)hostViewController
{
    [[ZONSaveTransferCoordinator sharedCoordinator] presentRemoteDownloadFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performCloudSaveFromViewController:(UIViewController *)hostViewController
{
    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performModifierFromViewController:(UIViewController *)hostViewController
{
    if (!hostViewController) return NO;

    if (![ZONRuntimeCapabilityService isCapabilityAvailable:ZONRuntimeCapabilityZonoePatch]) {
        [SVProgressHUD showErrorWithStatus:@"修改器组件未加载"];
        [SVProgressHUD dismissWithDelay:2.0];
        return YES;
    }

    NSString *deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
    NSDictionary *runtimeConfig = [ZONAuthV2Storage lastRuntimeConfig];
    if (deviceIdentifier.length < 5 || ![runtimeConfig isKindOfClass:NSDictionary.class] || runtimeConfig.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"修改器验证上下文不可用，请重新启动后再试"];
        [SVProgressHUD dismissWithDelay:3.0];
        return YES;
    }

    [SVProgressHUD showWithStatus:@"正在刷新设备授权..."];
    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:deviceIdentifier completion:^(NSDictionary *license, NSError *licenseError) {
        if (licenseError || !ZONModifierLicenseIsActive(license)) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:licenseError.localizedDescription ?: @"当前设备授权无效或已到期"];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }

        [SVProgressHUD showWithStatus:@"正在验证修改器权限..."];
        [[ZONAuthV2Verify sharedVerifier]
         verifyUDID:deviceIdentifier
         runtimeConfig:runtimeConfig
         completion:^(NSDictionary *response, NSError *verifyError) {
            [SVProgressHUD dismiss];

            if (verifyError) {
                [SVProgressHUD showErrorWithStatus:verifyError.localizedDescription ?: @"修改器权限验证失败"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            if (!ZONModifierVerifyAllowsActivation(response)) {
                [SVProgressHUD showErrorWithStatus:@"当前授权不包含修改器权限"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            [ZONAuthV2Storage setLastVerify:response];

            if (![ZONRuntimeCapabilityService isCapabilityAvailable:ZONRuntimeCapabilityZonoePatch]) {
                [SVProgressHUD showErrorWithStatus:@"修改器组件已卸载或不可用"];
                [SVProgressHUD dismissWithDelay:2.0];
                return;
            }

            BOOL activated = [ZONRuntimeCapabilityService activateCapability:ZONRuntimeCapabilityZonoePatch];
            if (activated) {
                [SVProgressHUD showSuccessWithStatus:@"修改器已启动"];
            } else {
                [SVProgressHUD showErrorWithStatus:@"修改器启动失败"];
            }
            [SVProgressHUD dismissWithDelay:2.0];

            NSLog(@"[zonoemenu][ZONOE_PATCH] fresh_verify ok=%d access_level=%@ activated=%d",
                  [response[@"ok"] boolValue],
                  [response[@"access_level"] isKindOfClass:NSString.class] ? response[@"access_level"] : @"",
                  activated);
         }];
    }];

    return YES;
}

+ (BOOL)performBackupSaveFromViewController:(UIViewController *)hostViewController
{
    [[ZONBackupCoordinator sharedCoordinator] presentBackupFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performRestoreSaveFromViewController:(UIViewController *)hostViewController
{
    [[ZONLocalRestoreCoordinator sharedCoordinator] presentLocalRestoreFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performClearGameDataFromViewController:(UIViewController *)hostViewController
{
    [[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];
    return YES;
}

+ (BOOL)performClearAuthorizationFromViewController:(UIViewController *)hostViewController
{
    [[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];
    return YES;
}

#pragma mark - Compatibility surface

+ (void)clearGameDataPreservingTemporaryDirectory
{
    [[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];
}

@end
