#import "ZONFeatureAccessProvider.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONCore/ZONFeatureRegistry.h"
#import "ZONRuntimeCapabilityService.h"

@implementation ZONFeatureAccessProvider

+ (NSDictionary<NSString *, id> *)currentVerify
{
    NSDictionary *verify = [ZONAuthV2Storage lastVerify];
    return [verify isKindOfClass:NSDictionary.class] ? verify : @{};
}

+ (NSDictionary<NSString *, id> *)currentServerPermissions
{
    NSDictionary *verify = [self currentVerify];
    NSDictionary *permissions = [verify[@"permissions"] isKindOfClass:NSDictionary.class] ? verify[@"permissions"] : nil;
    return permissions ?: @{};
}

+ (NSString *)currentAccessLevel
{
    NSDictionary *verify = [self currentVerify];
    NSString *accessLevel = [verify[@"access_level"] isKindOfClass:NSString.class] ? verify[@"access_level"] : nil;
    return accessLevel ?: @"";
}

+ (BOOL)runtimeCapabilitySatisfiedForFeature:(NSDictionary<NSString *, id> *)feature
{
    NSString *requiredCapability = [feature[ZONFeatureRequiredRuntimeCapabilityKey] isKindOfClass:NSString.class]
        ? feature[ZONFeatureRequiredRuntimeCapabilityKey]
        : @"";
    if (requiredCapability.length == 0) return YES;
    return [ZONRuntimeCapabilityService isCapabilityAvailable:requiredCapability];
}

+ (BOOL)isFeatureVisible:(NSDictionary<NSString *, id> *)feature
{
    if (![feature isKindOfClass:NSDictionary.class]) return NO;
    if (!ZONFeatureIsVisibleWithPermissions(feature, [self currentServerPermissions])) return NO;
    return [self runtimeCapabilitySatisfiedForFeature:feature];
}

+ (BOOL)isFeatureActionAllowed:(NSDictionary<NSString *, id> *)feature
{
    if (![feature isKindOfClass:NSDictionary.class]) return NO;
    if (!ZONFeatureIsActionAllowedWithPermissions(feature, [self currentServerPermissions])) return NO;
    return [self runtimeCapabilitySatisfiedForFeature:feature];
}

@end
