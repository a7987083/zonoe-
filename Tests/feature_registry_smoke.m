#import <Foundation/Foundation.h>
#import "../testmod/ZONCore/ZONFeatureRegistry.h"

static void require(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"feature registry smoke failed: %@", message);
        exit(1);
    }
}

static void requireSection(NSString *section, NSArray<NSNumber *> *expectedTags)
{
    NSArray<NSDictionary<NSString *, id> *> *features = ZONFeatureMetadataForSection(section);
    require(features.count == expectedTags.count,
            [NSString stringWithFormat:@"%@ count mismatch", section]);

    [expectedTags enumerateObjectsUsingBlock:^(NSNumber *tag, NSUInteger idx, BOOL *stop) {
        (void)stop;
        NSDictionary<NSString *, id> *feature = features[idx];
        require([feature[ZONFeatureLegacyTagKey] isEqualToNumber:tag],
                [NSString stringWithFormat:@"%@ order mismatch at %lu", section, (unsigned long)idx]);
    }];
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

        NSSet<NSNumber *> *expectedMigratedTags = [NSSet setWithArray:@[@1, @2, @3, @100, @101, @102, @103, @201, @202, @203]];
        __block NSUInteger migratedCount = 0;

        [expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *tag, NSString *identifier, BOOL *stop) {
            (void)stop;
            NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(tag.integerValue);
            require(feature != nil, [NSString stringWithFormat:@"missing legacy tag %@", tag]);
            require([feature[ZONFeatureIdentifierKey] isEqualToString:identifier],
                    [NSString stringWithFormat:@"legacy tag %@ mapped to wrong identifier", tag]);

            BOOL migrated = [feature[ZONFeatureMigratedKey] boolValue];
            if (migrated) migratedCount++;
            require([expectedMigratedTags containsObject:tag] == migrated,
                    [NSString stringWithFormat:@"%@ migration ownership mismatch", identifier]);
        }];

        require(migratedCount == expectedMigratedTags.count,
                @"v1_p19 must keep all ten features registry-owned");

        requireSection(@"基础功能", @[@1, @2, @3]);
        requireSection(@"数据功能", @[@100, @101, @102, @103]);
        requireSection(@"其他功能", @[@201, @202, @203]);
        require(ZONFeatureMetadataForSection(@"不存在").count == 0,
                @"unknown section must be empty");

        NSLog(@"feature registry smoke passed (%lu features, %lu migrated, section UI order verified)",
              (unsigned long)features.count,
              (unsigned long)migratedCount);
    }
    return 0;
}
