#import "ZONFeatureRegistry.h"

NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInSectionMetadata(void)
{
    static NSArray<NSDictionary<NSString *, id> *> *sections;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sections = @[
            @{ ZONSectionIdentifierKey:@"base", ZONSectionTitleKey:@"基础功能", ZONSectionDetailKey:@"远程下载 / 云存档", ZONSectionStateKey:@"fold_base", ZONSectionRendererKey:@"cards" },
            @{ ZONSectionIdentifierKey:@"data", ZONSectionTitleKey:@"数据功能", ZONSectionDetailKey:@"备份存档 /恢复存档 / 清理配置和授权", ZONSectionStateKey:@"fold_draw", ZONSectionRendererKey:@"grid" },
            @{ ZONSectionIdentifierKey:@"runtime", ZONSectionTitleKey:@"其他功能", ZONSectionDetailKey:@"1 / 2 / 3", ZONSectionStateKey:@"fold_role", ZONSectionRendererKey:@"runtime" },
        ];
    });
    return sections;
}

NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInFeatureMetadata(void)
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

NSDictionary<NSString *, id> * _Nullable ZONFeatureMetadataForLegacyTag(NSInteger legacyTag)
{
    for (NSDictionary<NSString *, id> *feature in ZONBuiltInFeatureMetadata()) {
        if ([feature[ZONFeatureLegacyTagKey] integerValue] == legacyTag) return feature;
    }
    return nil;
}

NSArray<NSDictionary<NSString *, id> *> *ZONFeatureMetadataForSection(NSString *section)
{
    if (section.length == 0) return @[];

    NSMutableArray<NSDictionary<NSString *, id> *> *matches = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *feature in ZONBuiltInFeatureMetadata()) {
        if ([feature[ZONFeatureSectionKey] isEqualToString:section]) {
            [matches addObject:feature];
        }
    }
    return [matches copy];
}

BOOL ZONFeatureRegistryHasUniqueIdentifiersAndTags(void)
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

BOOL ZONSectionRegistryIsValid(void)
{
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    NSMutableSet<NSString *> *titles = [NSMutableSet set];
    for (NSDictionary<NSString *, id> *section in ZONBuiltInSectionMetadata()) {
        NSString *identifier = section[ZONSectionIdentifierKey];
        NSString *title = section[ZONSectionTitleKey];
        NSString *stateKey = section[ZONSectionStateKey];
        NSString *renderer = section[ZONSectionRendererKey];
        if (identifier.length == 0 || title.length == 0 || stateKey.length == 0 || renderer.length == 0) return NO;
        if ([identifiers containsObject:identifier] || [titles containsObject:title]) return NO;
        if (ZONFeatureMetadataForSection(title).count == 0) return NO;
        [identifiers addObject:identifier];
        [titles addObject:title];
    }
    return YES;
}
