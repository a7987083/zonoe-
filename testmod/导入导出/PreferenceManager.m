//
//  PreferenceManager.m
//
//  Created by Your Name on 2025/06/24.
//  Copyright © 2025 Your Company. All rights reserved.
//

#import "PreferenceManager.h"
#import "JDStatusBarNotification.h"

@implementation PreferenceManager

+ (void)loadCustomPlistIntoUserDefaults:(NSString *)plistFileName {
    // 1. 获取自定义 Plist 文件的完整路径
    // Plist 文件通常放在主应用程序 Bundle 中
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    
    NSString *cachesPathplist = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];
    NSString *mulu = [NSString stringWithFormat:@"%@/Library/Preferences/",cachesPathplist];
 
     NSString *path = [mulu stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", BundID]];
  
    NSString *removeid = [NSString stringWithFormat:@"%@/%@-Inbox",cachesPathplist,BundID];

//    NSString *path = [[NSBundle mainBundle] pathForResource:plistFileName ofType:@"plist"];

    

    // 2. 将 Plist 文件的内容读取到 NSDictionary
    // NSDictionary 的 dictionaryWithContentsOfFile: 方法可以直接解析 Plist
    NSDictionary *customPlistDict = [NSDictionary dictionaryWithContentsOfFile:path];

    

    // 3. 获取标准的用户默认设置实例
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 4. 遍历自定义 Plist 字典，并将每个键值对写入 NSUserDefaults
    for (NSString *key in customPlistDict) {
        id value = customPlistDict[key];
        // NSUserDefaults 可以存储的数据类型有限制：
        // NSString, NSNumber, NSDate, NSData, NSArray, NSDictionary
        // 确保你的 Plist 值属于这些类型
        [defaults setObject:value forKey:key];
        NSLog(@"✅ Set UserDefaults key: '%@' with value: '%@' (Type: %@)", key, value, NSStringFromClass([value class]));
    }

    // 5. 立即同步 NSUserDefaults (可选但推荐)
    // synchronize 会将内存中的更改立即写入磁盘。
    // 尽管系统在某些时候会自动同步，但显式调用可以确保数据即时持久化。
    BOOL synchronized = [defaults synchronize];
    if (synchronized) {
 
        NSString *dataFile = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"] ;
            NSString *imageDir = [NSString stringWithFormat:@"%@",dataFile];
            NSLog(@"✈️删除tmp, %@", imageDir);
            NSFileManager *Manager = [NSFileManager defaultManager];
            [Manager removeItemAtPath:imageDir error:nil];
            [Manager removeItemAtPath:removeid error:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           
           
            exit(0);
        });
    }
}

+ (nullable id)getValueFromUserDefaults:(NSString *)key {
    // 从标准的用户默认设置中读取值
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

@end
