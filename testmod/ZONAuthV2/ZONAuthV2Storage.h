#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONAuthV2Storage : NSObject
+ (nullable NSString *)udid;
+ (void)setUDID:(NSString *)udid;
+ (nullable NSString *)card;
+ (void)setCard:(NSString *)card;
+ (void)clearCard;
+ (void)clearAll;
+ (nullable NSDictionary *)lastVerify;
+ (void)setLastVerify:(nullable NSDictionary *)value;
+ (nullable NSDictionary *)lastActivation;
+ (void)setLastActivation:(nullable NSDictionary *)value;
+ (nullable NSDictionary *)lastRuntimeConfig;
+ (void)setLastRuntimeConfig:(nullable NSDictionary *)value;
+ (nullable NSDictionary *)lastBootstrap;
+ (void)setLastBootstrap:(nullable NSDictionary *)value;
@end

NS_ASSUME_NONNULL_END
