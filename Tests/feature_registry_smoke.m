#import <Foundation/Foundation.h>
#import "../testmod/ZONCore/ZONFeatureRegistry.h"

static void require(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"feature registry smoke failed: %@", message);
        exit(1);
    }
}

int main(void)
{
    @autoreleasepool {
        NSArray<NSDictionary<NSString *, id> *> *features = ZONBuiltInFeatureMetadata();
        require(features.count == 10, @"expected 10 legacy-visible features");
        require(ZONFeatureRegistryHasUniqueIdentifiersAndTags(), @"identifiers/tags must be unique");

        NSDictionary<NSNumber *, NSString *> *expected = @{
            @1:@"base.remote-download",
            @2:@"base.cloud-save",
            @3:@"base.local-files",
            @100:@"data.backup-save",
            @101:@"data.restore-save",
            @102:@"data.clear-game-data",
            @103:@"auth.clear-records",
            @201:@"runtime.iap-noads",
            @202:@"runtime.ad-speed",
            @203:@"runtime.placeholder-203",
        };

        [expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *tag, NSString *identifier, BOOL *stop) {
            (void)stop;
            NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(tag.integerValue);
            require(feature != nil, [NSString stringWithFormat:@"missing legacy tag %@", tag]);
            require([feature[ZONFeatureIdentifierKey] isEqualToString:identifier],
                    [NSString stringWithFormat:@"legacy tag %@ mapped to wrong identifier", tag]);
            require(![feature[ZONFeatureMigratedKey] boolValue],
                    [NSString stringWithFormat:@"%@ must remain passive in phase 1", identifier]);
        }];

        NSLog(@"feature registry smoke passed (%lu features)", (unsigned long)features.count);
    }
    return 0;
}
