//
//  ImgTool.h
//  JSQ
//
//  Created by 紫贝壳 on 2019/6/18.
//  Copyright © 2019 zibeike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImgTool : NSObject

+(instancetype)share;

@property(nonatomic,assign)int NeiGou;
@property(nonatomic,assign)int ADSpeed;
@property(nonatomic,assign)int LianDianPD;
@property(nonatomic,assign)float ADBiansu;
@property(nonatomic,assign)BOOL games;
@property(nonatomic,assign)int gamespeedeed;

@property(nonatomic,assign)CGFloat num;

@property(nonatomic,assign)float multiple;


+(UIImage *)stringToImage:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
