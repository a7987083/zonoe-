#import "ZONAuthV2Storage.h"
#import "../菜单/ZONKeychain.h"

static NSString * const ZONAuthV2Service = @"com.zonoe.auth.v2";
static NSString * const ZONAuthV2UDIDAccount = @"udid";
static NSString * const ZONAuthV2CardAccount = @"card";
static NSString * const ZONAuthV2LastVerifyKey = @"zonoe.auth.v2.lastVerify";
static NSString * const ZONAuthV2LastActivationKey = @"zonoe.auth.v2.lastActivation";
static NSString * const ZONAuthV2LastRuntimeConfigKey = @"zonoe.auth.v2.lastRuntimeConfig";
static NSString * const ZONAuthV2LastBootstrapKey = @"zonoe.auth.v2.lastBootstrap";
static NSString * const ZONAuthV2LastNoticeFingerprintKey = @"zonoe.auth.v2.lastNoticeFingerprint";

@implementation ZONAuthV2Storage

+ (NSString *)stringForAccount:(NSString *)account {
    NSError *error = nil;
    return [ZONKeychain stringForAccount:account service:ZONAuthV2Service error:&error];
}

+ (void)setString:(NSString *)value account:(NSString *)account {
    if (!value.length) return;
    NSError *error = nil;
    [ZONKeychain setString:value forAccount:account service:ZONAuthV2Service error:&error];
}

+ (NSString *)udid { return [self stringForAccount:ZONAuthV2UDIDAccount]; }
+ (void)setUDID:(NSString *)udid { [self setString:udid account:ZONAuthV2UDIDAccount]; }
+ (NSString *)card { return [self stringForAccount:ZONAuthV2CardAccount]; }
+ (void)setCard:(NSString *)card { [self setString:card account:ZONAuthV2CardAccount]; }

+ (void)clearCard {
    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2CardAccount service:ZONAuthV2Service error:&error];
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d removeObjectForKey:ZONAuthV2LastVerifyKey];
    [d removeObjectForKey:ZONAuthV2LastActivationKey];
}

+ (void)clearAll {
    [self clearCard];
    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2UDIDAccount service:ZONAuthV2Service error:&error];
}

+ (NSDictionary *)lastVerify { return [NSUserDefaults.standardUserDefaults dictionaryForKey:ZONAuthV2LastVerifyKey]; }
+ (void)setLastVerify:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastVerifyKey]; else [d removeObjectForKey:ZONAuthV2LastVerifyKey];
}
+ (NSDictionary *)lastActivation { return [NSUserDefaults.standardUserDefaults dictionaryForKey:ZONAuthV2LastActivationKey]; }
+ (void)setLastActivation:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastActivationKey]; else [d removeObjectForKey:ZONAuthV2LastActivationKey];
}
+ (NSDictionary *)lastRuntimeConfig { return [NSUserDefaults.standardUserDefaults dictionaryForKey:ZONAuthV2LastRuntimeConfigKey]; }
+ (void)setLastRuntimeConfig:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastRuntimeConfigKey]; else [d removeObjectForKey:ZONAuthV2LastRuntimeConfigKey];
}
+ (NSDictionary *)lastBootstrap { return [NSUserDefaults.standardUserDefaults dictionaryForKey:ZONAuthV2LastBootstrapKey]; }
+ (void)setLastBootstrap:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastBootstrapKey]; else [d removeObjectForKey:ZONAuthV2LastBootstrapKey];
}
+ (NSString *)lastNoticeFingerprint {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:ZONAuthV2LastNoticeFingerprintKey];
    return [value isKindOfClass:NSString.class] ? value : nil;
}
+ (void)setLastNoticeFingerprint:(NSString *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value.length) [d setObject:value forKey:ZONAuthV2LastNoticeFingerprintKey]; else [d removeObjectForKey:ZONAuthV2LastNoticeFingerprintKey];
}

@end
