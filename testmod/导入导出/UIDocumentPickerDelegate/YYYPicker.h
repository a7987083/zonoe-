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

/// Semantic entry for restoring an already-prepared staging tree through ZONRestoreAPI.
- (void)restorePreparedArchiveStaging;

/// Legacy compatibility shim. Historical callers keep working, while all real
/// restore behavior now lives behind ZONRestoreAPI.
- (void)yidongwenjian;

@end

NS_ASSUME_NONNULL_END
