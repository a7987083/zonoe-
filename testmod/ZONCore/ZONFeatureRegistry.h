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

FOUNDATION_EXPORT NSString * const ZONFeatureIdentifierKey;
FOUNDATION_EXPORT NSString * const ZONFeatureTitleKey;
FOUNDATION_EXPORT NSString * const ZONFeatureSectionKey;
FOUNDATION_EXPORT NSString * const ZONFeatureLegacyTagKey;
FOUNDATION_EXPORT NSString * const ZONFeatureKindKey;
FOUNDATION_EXPORT NSString * const ZONFeatureRiskKey;
FOUNDATION_EXPORT NSString * const ZONFeatureMigratedKey;

FOUNDATION_EXPORT NSString * const ZONSectionIdentifierKey;
FOUNDATION_EXPORT NSString * const ZONSectionTitleKey;
FOUNDATION_EXPORT NSString * const ZONSectionDetailKey;
FOUNDATION_EXPORT NSString * const ZONSectionStateKey;
FOUNDATION_EXPORT NSString * const ZONSectionRendererKey;

NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInSectionMetadata(void);
NSArray<NSDictionary<NSString *, id> *> *ZONBuiltInFeatureMetadata(void);
NSDictionary<NSString *, id> * _Nullable ZONFeatureMetadataForLegacyTag(NSInteger legacyTag);
NSArray<NSDictionary<NSString *, id> *> *ZONFeatureMetadataForSection(NSString *section);
BOOL ZONFeatureRegistryHasUniqueIdentifiersAndTags(void);
BOOL ZONSectionRegistryIsValid(void);

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureRegistry_h */
