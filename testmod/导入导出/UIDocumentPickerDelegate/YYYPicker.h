//
//  ViewController.h
//  DocumentPicker
//
//  Created by 聂宽 on 2018/6/27.
//  Copyright © 2018年 聂宽. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYYPicker : UIViewController

- (void)addBtnAction;

/// Semantic entry for restoring an already-prepared staging tree.
- (void)restorePreparedArchiveStaging;

/// Legacy compatibility shim. Keep existing callers working while routing them
/// through the semantic restore entry above.
- (void)yidongwenjian;

/// Shared legacy post-restore success tail used by local, remote and cloud
/// restore entry points. This intentionally preserves the P66 behavior:
/// PreferenceManager reload -> synchronize -> cleanup -> process exit.
+ (void)completeRestoreSuccessWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
