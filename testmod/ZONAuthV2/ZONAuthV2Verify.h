#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONAuthV2VerifyCompletion)(NSDictionary * _Nullable response, NSError * _Nullable error);

@interface ZONAuthV2Verify : NSObject
+ (instancetype)sharedVerifier;
- (void)verifyUDID:(NSString *)udid
     runtimeConfig:(NSDictionary *)runtimeConfig
        completion:(ZONAuthV2VerifyCompletion)completion;
@end

NS_ASSUME_NONNULL_END
