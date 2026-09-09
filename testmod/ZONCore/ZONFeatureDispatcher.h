#ifndef ZONFeatureDispatcher_h
#define ZONFeatureDispatcher_h

#import <UIKit/UIKit.h>
#import "ZONFeatureRegistry.h"
#import "SandboxBrowserVC.h"

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

    // A registry entry should never silently swallow a legacy action. Until each
    // feature has an explicit handler, return NO so PopupMenuVC can use the old path.
    return NO;
}

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureDispatcher_h */
