//
//  ViewController.h
//  DocumentPicker
//
//  Created by 聂宽 on 2018/6/27.
//  Copyright © 2018年 聂宽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h> // 导入 StoreKit 框架

@interface YYYPicker : UIViewController <SKStoreProductViewControllerDelegate>
- (void)showAppStoreProductPage;

- (void)addBtnAction;
-(void)yidongwenjian;
@end

