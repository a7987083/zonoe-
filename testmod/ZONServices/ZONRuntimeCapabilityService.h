#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ZONRuntimeCapabilityPassiveSatella;
FOUNDATION_EXPORT NSString * const ZONRuntimeCapabilityZonoePatch;

/// Central boundary for runtime capabilities supplied by already-loaded images.
/// The service does not own injection/loading; availability is derived from the
/// current process image set and capability-specific compatibility checks.
@interface ZONRuntimeCapabilityService : NSObject

+ (BOOL)isCapabilityAvailable:(NSString *)identifier;
+ (BOOL)activateCapability:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
