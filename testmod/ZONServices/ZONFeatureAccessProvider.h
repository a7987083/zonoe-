#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Single access boundary for feature visibility and execution decisions.
/// Server permission schema and local runtime capability checks must stay here,
/// so renderers/dispatchers do not independently parse authorization state.
@interface ZONFeatureAccessProvider : NSObject

+ (NSDictionary<NSString *, id> *)currentServerPermissions;
+ (NSString *)currentAccessLevel;
+ (BOOL)isFeatureVisible:(NSDictionary<NSString *, id> *)feature;
+ (BOOL)isFeatureActionAllowed:(NSDictionary<NSString *, id> *)feature;

@end

NS_ASSUME_NONNULL_END
