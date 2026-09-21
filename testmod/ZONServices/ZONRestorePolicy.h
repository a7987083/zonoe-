#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONRestorePolicy : NSObject
+ (NSSet<NSString *> *)legacySkipItems;
+ (BOOL)isSafeArchiveEntryPath:(NSString *)entryPath destinationRoot:(NSString *)destinationRoot;
+ (BOOL)isReservedNestedArchiveEntry:(NSString *)entryPath;
@end

NS_ASSUME_NONNULL_END
