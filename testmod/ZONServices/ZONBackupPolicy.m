#import "ZONBackupPolicy.h"

@implementation ZONBackupPolicy

+ (unsigned long long)largeItemThresholdBytes
{
    return 50ULL * 1024ULL * 1024ULL;
}

+ (NSSet<NSString *> *)excludedContentRelativePaths
{
    static NSSet<NSString *> *paths;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        paths = [NSSet setWithObjects:
                 @"Documents/zonoe",
                 @"Library/HeimdallrBU",
                 @"Library/Caches",
                 @"Library/UnityCache",
                 nil];
    });
    return paths;
}

+ (BOOL)shouldExcludeContentsAtRelativePath:(NSString *)relativePath
{
    if (relativePath.length == 0) return NO;
    return [[self excludedContentRelativePaths] containsObject:relativePath];
}

@end
