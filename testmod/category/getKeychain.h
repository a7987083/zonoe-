#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface getKeychain : NSObject
+ (void)addKeychainData:(NSString *)data forKey:(NSString *)key;
+ (nullable NSString *)getKeychainDataForKey:(NSString *)key;
+ (void)deleteKeychainDataForKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
