#ifndef ZONFeatureRegistry_h
#define ZONFeatureRegistry_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONFeatureKind) {
    ZONFeatureKindAction = 0,
    ZONFeatureKindToggle = 1,
    ZONFeatureKindSlider = 2,
    ZONFeatureKindPlaceholder = 3,
};

typedef NS_ENUM(NSInteger, ZONFeatureRisk) {
    ZONFeatureRiskLow = 0,
    ZONFeatureRiskMedium = 1,
    ZONFeatureRiskHigh = 2,
};

static NSString * const ZONFeatureIdentifierKey = @"identifier";
static NSString * const ZONFeatureTitleKey = @"title";
static NSString * const ZONFeatureSectionKey = @"section";
static NSString * const ZONFeatureLegacyTagKey = @"legacyTag";
static NSString * const ZONFeatureKindKey = @"kind";
static NSString * const ZONFeatureRiskKey = @"risk";
static NSString * const ZONFeatureMigratedKey = @"migrated";

/// Built-in feature metadata used by the staged menu migration.
///
/// Compatibility rule:
/// - `migrated == YES` means PopupMenuVC may route that feature through
///   ZONFeatureDispatcher first.
/// - unmigrated features remain on their existing legacy tag handlers.
/// - the caller keeps a legacy fallback while a migrated feature is being
///   validated on device.
static inline NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInFeatureMetadata(void)
{
    static NSArray<NSDictionary<NSString *, id> *> *features;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        features = @[
            @{ ZONFeatureIdentifierKey:@"base.remote-download", ZONFeatureTitleKey:@"远程下载", ZONFeatureSectionKey:@"基础功能", ZONFeatureLegacyTagKey:@1, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"base.cloud-save", ZONFeatureTitleKey:@"VIP云存档", ZONFeatureSectionKey:@"基础功能", ZONFeatureLegacyTagKey:@2, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskHigh), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"base.local-files", ZONFeatureTitleKey:@"浏览本地文件", ZONFeatureSectionKey:@"基础功能", ZONFeatureLegacyTagKey:@3, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },

            @{ ZONFeatureIdentifierKey:@"data.backup-save", ZONFeatureTitleKey:@"备份存档", ZONFeatureSectionKey:@"数据功能", ZONFeatureLegacyTagKey:@100, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"data.restore-save", ZONFeatureTitleKey:@"恢复存档", ZONFeatureSectionKey:@"数据功能", ZONFeatureLegacyTagKey:@101, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"data.clear-game-data", ZONFeatureTitleKey:@"清除游戏数据", ZONFeatureSectionKey:@"数据功能", ZONFeatureLegacyTagKey:@102, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskHigh), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"auth.clear-records", ZONFeatureTitleKey:@"清除授权记录", ZONFeatureSectionKey:@"数据功能", ZONFeatureLegacyTagKey:@103, ZONFeatureKindKey:@(ZONFeatureKindAction), ZONFeatureRiskKey:@(ZONFeatureRiskHigh), ZONFeatureMigratedKey:@YES },

            @{ ZONFeatureIdentifierKey:@"runtime.iap-noads", ZONFeatureTitleKey:@"内购破解+ iGameGod去广告", ZONFeatureSectionKey:@"其他功能", ZONFeatureLegacyTagKey:@201, ZONFeatureKindKey:@(ZONFeatureKindToggle), ZONFeatureRiskKey:@(ZONFeatureRiskMedium), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"runtime.ad-speed", ZONFeatureTitleKey:@"广告加速", ZONFeatureSectionKey:@"其他功能", ZONFeatureLegacyTagKey:@202, ZONFeatureKindKey:@(ZONFeatureKindToggle), ZONFeatureRiskKey:@(ZONFeatureRiskMedium), ZONFeatureMigratedKey:@YES },
            @{ ZONFeatureIdentifierKey:@"runtime.placeholder-203", ZONFeatureTitleKey:@"暂无", ZONFeatureSectionKey:@"其他功能", ZONFeatureLegacyTagKey:@203, ZONFeatureKindKey:@(ZONFeatureKindPlaceholder), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },
        ];
    });
    return features;
}

static inline NSDictionary<NSString *, id> * _Nullable ZONFeatureMetadataForLegacyTag(NSInteger legacyTag)
{
    for (NSDictionary<NSString *, id> *feature in ZONBuiltInFeatureMetadata()) {
        if ([feature[ZONFeatureLegacyTagKey] integerValue] == legacyTag) return feature;
    }
    return nil;
}

static inline BOOL ZONFeatureRegistryHasUniqueIdentifiersAndTags(void)
{
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    NSMutableSet<NSNumber *> *tags = [NSMutableSet set];

    for (NSDictionary<NSString *, id> *feature in ZONBuiltInFeatureMetadata()) {
        NSString *identifier = feature[ZONFeatureIdentifierKey];
        NSNumber *tag = feature[ZONFeatureLegacyTagKey];
        if (identifier.length == 0 || !tag) return NO;
        if ([identifiers containsObject:identifier] || [tags containsObject:tag]) return NO;
        [identifiers addObject:identifier];
        [tags addObject:tag];
    }
    return YES;
}

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureRegistry_h */
