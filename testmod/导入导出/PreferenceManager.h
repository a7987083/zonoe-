//
//  PreferenceManager.h
//
//  Created by Your Name on 2025/06/24.
//  Copyright © 2025 Your Company. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class PreferenceManager
 * @brief 管理从自定义 Plist 文件加载数据到 NSUserDefaults 的工具类。
 *
 * 该类提供了一个便捷的方法，用于将应用程序包中的 Plist 文件内容读取到
 * NSUserDefaults 中，避免了直接操作 UserDefaults 对应的 Plist 文件可能
 * 导致的问题（如内部缓存不同步）。
 */
@interface PreferenceManager : NSObject

/**
 * @brief 从自定义 Plist 文件读取数据并将其逐个写入 NSUserDefaults。
 *
 * 此方法会查找应用程序主 Bundle 中指定名称的 Plist 文件，并将其内容（键值对）
 * 遍历写入 NSUserDefaults。如果文件不存在或读取失败，会打印错误信息。
 * * @param plistFileName Plist 文件的名称（不包含 .plist 扩展名）。
 * 例如，如果文件名为 "MySettings.plist"，则传入 "MySettings"。
 */
+ (void)loadCustomPlistIntoUserDefaults:(NSString *)plistFileName;

/**
 * @brief 从 NSUserDefaults 中读取一个特定键的值。
 *
 * 这是一个辅助方法，用于验证数据是否已成功写入 UserDefaults。
 *
 * @param key 要读取的键名。
 * @return 对应键的值，如果该键不存在，则返回 nil。
 */
+ (nullable id)getValueFromUserDefaults:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
