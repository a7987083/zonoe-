#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Owns the minimal runtime-directory compatibility behavior historically exposed
/// through the six-button action boundary.
@interface ZONRuntimeDirectoryService : NSObject

+ (NSString *)temporaryDirectoryPath;
+ (BOOL)ensureTemporaryDirectory;

@end

NS_ASSUME_NONNULL_END
