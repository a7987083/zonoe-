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

static NSString * const ZONSectionIdentifierKey = @"identifier";
static NSString * const ZONSectionTitleKey = @"title";
static NSString * const ZONSectionDetailKey = @"detail";
static NSString * const ZONSectionStateKey = @"stateKey";
static NSString * const ZONSectionRendererKey = @"renderer";

NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInSectionMetadata(void);
NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInFeatureMetadata(void);
NSDictionary<NSString *, id> * _Nullable ZONFeatureMetadataForLegacyTag(NSInteger legacyTag);
NSArray<NSDictionary<NSString *, id> *> *ZONFeatureMetadataForSection(NSString *section);
BOOL ZONFeatureRegistryHasUniqueIdentifiersAndTags(void);
BOOL ZONSectionRegistryIsValid(void);

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureRegistry_h */
