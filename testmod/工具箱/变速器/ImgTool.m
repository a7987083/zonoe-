//
//  ImgTool.m
//  JSQ
//
//  Created by 紫贝壳 on 2019/6/18.
//  Copyright © 2019 zibeike. All rights reserved.
//

#import "ImgTool.h"

@implementation ImgTool

+(instancetype)share{
    static ImgTool *Share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Share = [[ImgTool alloc]init];
        Share.multiple = 1.0;
    });
    return Share;
}

+(UIImage *)stringToImage:(NSString *)str{
    NSData * imageData =[[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *photo = [UIImage imageWithData:imageData ];
    return photo;
}

@end
