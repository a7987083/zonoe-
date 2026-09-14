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
        require(features.count == 9, @"expected 9 active product features");
        require(ZONFeatureRegistryHasUniqueIdentifiersAndTags(), @"identifiers/tags must be unique");

        NSDictionary<NSNumber *, NSString *> *expected = @{
            @1:@"base.remote-download", @2:@"base.cloud-save", @3:@"base.local-files",
            @100:@"data.backup-save", @101:@"data.restore-save", @102:@"data.clear-game-data",
            @103:@"auth.clear-records", @201:@"runtime.iap-noads", @202:@"runtime.ad-speed",
        };

        __block NSUInteger migratedCount = 0;
        [expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *tag, NSString *identifier, BOOL *stop) {
            (void)stop;
            NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(tag.integerValue);
            require(feature != nil, [NSString stringWithFormat:@"missing legacy tag %@", tag]);
            require([feature[ZONFeatureIdentifierKey] isEqualToString:identifier],
                    [NSString stringWithFormat:@"legacy tag %@ mapped to wrong identifier", tag]);
            require([feature[ZONFeatureMigratedKey] boolValue],
                    [NSString stringWithFormat:@"%@ must remain registry-owned", identifier]);
            migratedCount++;
        }];
        require(migratedCount == 9, @"all nine active features must remain registry-owned");

        requireSection(@"基础功能", @[@1, @2, @3]);
        requireSection(@"数据功能", @[@100, @101, @102, @103]);
        requireSection(@"其他功能", @[@201, @202]);
        require(ZONFeatureMetadataForLegacyTag(203) == nil, @"retired legacy tag 203 must not resolve");
        require(ZONFeatureMetadataForSection(@"不存在").count == 0, @"unknown section must be empty");

        NSArray<NSDictionary<NSString *, id> *> *sections = ZONBuiltInSectionMetadata();
        require(sections.count == 3, @"expected three menu sections");
        require(ZONSectionRegistryIsValid(), @"section registry must be valid");

        NSArray<NSString *> *expectedTitles = @[@"基础功能", @"数据功能", @"其他功能"];
        NSArray<NSString *> *expectedStateKeys = @[@"fold_base", @"fold_draw", @"fold_role"];
        NSArray<NSString *> *expectedRenderers = @[@"cards", @"grid", @"runtime"];
        [sections enumerateObjectsUsingBlock:^(NSDictionary<NSString *, id> *section, NSUInteger idx, BOOL *stop) {
            (void)stop;
            require([section[ZONSectionTitleKey] isEqualToString:expectedTitles[idx]], @"section title/order mismatch");
            require([section[ZONSectionStateKey] isEqualToString:expectedStateKeys[idx]], @"section stateKey mismatch");
            require([section[ZONSectionRendererKey] isEqualToString:expectedRenderers[idx]], @"section renderer mismatch");
            require([section[ZONSectionDetailKey] length] > 0, @"section detail must be non-empty");
        }];

        NSLog(@"feature registry smoke passed (v1_p35, 9 features, 3 registry-driven sections)");
    }
    return 0;
}
