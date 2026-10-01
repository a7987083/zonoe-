#import "ZONFeatureAccessProvider.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONCore/ZONFeatureRegistry.h"
#import "ZONRuntimeCapabilityService.h"

static BOOL ZONGlobalSoftwareSourceAuthorizationIsActive(NSDictionary *license)
{
    if (![license isKindOfClass:NSDictionary.class]) return NO;

    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSInteger code = [license[@"code"] respondsToSelector:@selector(integerValue)] ? [license[@"code"] integerValue] : 0;
    NSString *message = [license[@"msg"] isKindOfClass:NSString.class] ? license[@"msg"] : @"";
    NSTimeInterval rootExpire = [license[@"expire"] respondsToSelector:@selector(doubleValue)] ? [license[@"expire"] doubleValue] : 0;
    if (code != 1 || ![message.lowercaseString isEqualToString:@"ok"] || rootExpire <= now) return NO;

    NSArray *authorizations = [license[@"authorizations"] isKindOfClass:NSArray.class] ? license[@"authorizations"] : @[];
    for (id object in authorizations) {
        if (![object isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *authorization = object;
        NSString *type = [authorization[@"type"] isKindOfClass:NSString.class] ? authorization[@"type"] : @"";
        if (![type isEqualToString:@"全软件源"]) continue;

        NSTimeInterval expire = [authorization[@"expire"] respondsToSelector:@selector(doubleValue)] ? [authorization[@"expire"] doubleValue] : 0;
        if (expire > now) return YES;
    }
    return NO;
}

@implementation ZONFeatureAccessProvider

+ (NSDictionary<NSString *, id> *)currentVerify
{
    NSDictionary *verify = [ZONAuthV2Storage lastVerify];
    return [verify isKindOfClass:NSDictionary.class] ? verify : @{};
}

+ (NSDictionary<NSString *, id> *)effectivePermissionsForVerifyResponse:(NSDictionary<NSString *,id> *)verifyResponse
{
    NSDictionary *verify = [verifyResponse isKindOfClass:NSDictionary.class] ? verifyResponse : @{};
    NSDictionary *serverPermissions = [verify[@"permissions"] isKindOfClass:NSDictionary.class] ? verify[@"permissions"] : @{};
    NSMutableDictionary *effective = [serverPermissions mutableCopy] ?: [NSMutableDictionary dictionary];

    BOOL verifyOK = [verify[@"ok"] respondsToSelector:@selector(boolValue)] && [verify[@"ok"] boolValue];
    NSString *action = [verify[@"action"] isKindOfClass:NSString.class] ? verify[@"action"] : @"";
    BOOL explicitlyDenied = [action isEqualToString:@"block"] || [action isEqualToString:@"disable_feature"];

    // Compatibility normalization while the backend permission projection catches up:
    // /apiface remains the authoritative UDID authorization source. An active, unexpired
    // "全软件源" authorization grants the full software-source feature surface, but never
    // overrides an explicit Verify block/disable decision.
    if (verifyOK && !explicitlyDenied && ZONGlobalSoftwareSourceAuthorizationIsActive([ZONAuthV2Storage lastLicense])) {
        effective[@"normal_menu"] = @YES;
        effective[@"extra_menu"] = @YES;
        effective[@"extra_features"] = @YES;
        if (![serverPermissions[@"extra_features"] boolValue]) {
            NSLog(@"[zonoemenu][auth-v3][PERMISSION_NORMALIZE] global software-source authorization promoted extra_features=1");
        }
    }

    return effective.copy;
}

+ (NSDictionary<NSString *, id> *)currentServerPermissions
{
    return [self effectivePermissionsForVerifyResponse:[self currentVerify]];
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
