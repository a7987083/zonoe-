#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONAuthorizationResetService : NSObject

/// Clears the complete authorization state used by the P62 runtime.
/// Missing items are treated as success.
+ (BOOL)clearAuthorizationData:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
