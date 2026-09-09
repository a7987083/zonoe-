#ifndef ZONFeatureDispatcher_h
#define ZONFeatureDispatcher_h

#import <UIKit/UIKit.h>
#import "ZONFeatureRegistry.h"
#import "SandboxBrowserVC.h"
#import "daochucd.h"
#import "YYYPicker.h"
#import "PubgLoad.h"
#import "ImgTool.h"

NS_ASSUME_NONNULL_BEGIN

/// Routes only features whose registry metadata explicitly marks them as migrated.
/// Returns YES when the migrated path handled the action; NO lets the caller fall
/// back to the legacy tag handler during the staged migration period.
static inline BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                                          UIViewController *hostViewController)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];

    if ([identifier isEqualToString:@"base.remote-download"]) {
        [[PubgLoad alloc] yuanchengdwon];
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

    // A registry entry should never silently swallow a legacy action. Until each
    // feature has an explicit handler, return NO so PopupMenuVC can use the old path.
    return NO;
}

/// Toggle/placeholder dispatch for migrated runtime controls. This preserves the
/// exact legacy UserDefaults keys and ImgTool side effects used by PopupMenuVC.
static inline BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)
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

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureDispatcher_h */
