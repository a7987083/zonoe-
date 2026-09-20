#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONBackupPolicy : NSObject

/// Legacy-compatible threshold used to ask whether a large top-level item should be skipped.
+ (unsigned long long)largeItemThresholdBytes;

/// Paths whose directory skeleton may be present in the archive but whose contents should not be backed up.
/// Relative paths always use '/' and are rooted at the archive's Documents/Library directories.
+ (BOOL)shouldExcludeContentsAtRelativePath:(NSString *)relativePath;

+ (NSSet<NSString *> *)excludedContentRelativePaths;

@end

NS_ASSUME_NONNULL_END
