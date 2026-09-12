#ifndef ZONFeatureDispatcher_h
#define ZONFeatureDispatcher_h

#import <UIKit/UIKit.h>
#import "ZONFeatureRegistry.h"
#import "SandboxBrowserVC.h"
#import "daochucd.h"
#import "YYYPicker.h"
#import "PubgLoad.h"
#import "ImgTool.h"
#import "SVProgressHUD.h"
#import "WX_NongShiFu123.h"

NS_ASSUME_NONNULL_BEGIN

NSString *ZONTmpDirectoryPath(void);
BOOL ZONEnsureTmpDirectory(void);
void ZONClearGameDataPreservingTmp(void);
void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController);
void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController);
BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                            UIViewController *hostViewController);
BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on);

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureDispatcher_h */
