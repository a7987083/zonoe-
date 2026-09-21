#import "ZONRestorePolicy.h"

@implementation ZONRestorePolicy

+ (NSSet<NSString *> *)legacySkipItems
{
    static NSSet<NSString *> *items;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = [NSSet setWithObjects:@"__MACOSX", @".DS_Store", @"Preferences", nil];
    });
    return items;
}

+ (BOOL)isSafeArchiveEntryPath:(NSString *)entryPath destinationRoot:(NSString *)destinationRoot
{
    if (entryPath.length == 0 || destinationRoot.length == 0) return NO;
    if ([entryPath hasPrefix:@"/"] || [entryPath hasPrefix:@"\\"]) return NO;

    NSString *normalizedEntry = [entryPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    for (NSString *component in [normalizedEntry pathComponents]) {
        if ([component isEqualToString:@".."] || [component isEqualToString:@"~"]) return NO;
    }

    NSString *root = [[destinationRoot stringByStandardizingPath] stringByAppendingString:@"/"];
    NSString *candidate = [[[destinationRoot stringByAppendingPathComponent:normalizedEntry] stringByStandardizingPath] stringByAppendingString:[normalizedEntry hasSuffix:@"/"] ? @"/" : @""];
    return [candidate hasPrefix:root] || [[candidate stringByStandardizingPath] isEqualToString:[destinationRoot stringByStandardizingPath]];
}

+ (BOOL)isReservedNestedArchiveEntry:(NSString *)entryPath
{
    return [[[entryPath pathExtension] lowercaseString] isEqualToString:@"zip"];
}

@end
