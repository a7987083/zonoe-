#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONAuthV2JSONCompletion)(NSDictionary * _Nullable json, NSError * _Nullable error);

@interface ZONAuthV2API : NSObject
+ (instancetype)sharedAPI;
- (void)fetchLicenseForUDID:(NSString *)udid completion:(ZONAuthV2JSONCompletion)completion;
- (void)activateUDID:(NSString *)udid card:(NSString *)card completion:(ZONAuthV2JSONCompletion)completion;
- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion;
@end

NS_ASSUME_NONNULL_END
