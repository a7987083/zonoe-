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

static NSString *gZONAuthV2SessionUDID = nil;
static NSString *gZONAuthV2SessionCard = nil;
static NSString *gZONAuthV2SessionToken = nil;
static NSDictionary *gZONAuthV2SessionLastVerify = nil;
static NSDictionary *gZONAuthV2SessionLastActivation = nil;
static NSDictionary *gZONAuthV2SessionLastRuntimeConfig = nil;
static NSDictionary *gZONAuthV2SessionLastBootstrap = nil;

@implementation ZONAuthV2Storage

+ (void)purgeLegacyPersistentState {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;

    for (NSString *key in @[
        ZONAuthV2LastVerifyKey,
        ZONAuthV2LastActivationKey,
        ZONAuthV2LastRuntimeConfigKey,
        ZONAuthV2LastBootstrapKey,
    ]) {
        [d removeObjectForKey:key];
    }

    for (NSString *key in @[
        @"到期时间",
        @"卡密",
        @"公告",
        @"zonoeudid",
        @"解锁码到期时间",
        @"到期弹窗",
    ]) {
        [d removeObjectForKey:key];
    }

    for (NSString *key in @[
        @"zonoe.udid.bridge.value",
        @"zonoe.udid.bridge.scheme",
        @"zonoe.udid.bridge.requestTimestamp",
        @"zonoe.udid.bridge.requestNonce",
    ]) {
        [d removeObjectForKey:key];
    }

    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2UDIDAccount service:ZONAuthV2Service error:&error];
    error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2CardAccount service:ZONAuthV2Service error:&error];
}

+ (NSString *)udid {
    @synchronized(self) { return [gZONAuthV2SessionUDID copy]; }
}

+ (void)setUDID:(NSString *)udid {
    @synchronized(self) { gZONAuthV2SessionUDID = [udid copy]; }
}

+ (NSString *)card {
    @synchronized(self) { return [gZONAuthV2SessionCard copy]; }
}

+ (void)setCard:(NSString *)card {
    @synchronized(self) { gZONAuthV2SessionCard = [card copy]; }
}

+ (NSString *)token {
    @synchronized(self) { return [gZONAuthV2SessionToken copy]; }
}

+ (void)setToken:(NSString *)token {
    @synchronized(self) { gZONAuthV2SessionToken = [token copy]; }
}

+ (void)clearCard {
    @synchronized(self) {
        gZONAuthV2SessionCard = nil;
        gZONAuthV2SessionToken = nil;
        gZONAuthV2SessionLastVerify = nil;
        gZONAuthV2SessionLastActivation = nil;
    }

    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2CardAccount service:ZONAuthV2Service error:&error];
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d removeObjectForKey:ZONAuthV2LastVerifyKey];
    [d removeObjectForKey:ZONAuthV2LastActivationKey];
}

+ (void)clearAll {
    @synchronized(self) {
        gZONAuthV2SessionUDID = nil;
        gZONAuthV2SessionCard = nil;
        gZONAuthV2SessionToken = nil;
        gZONAuthV2SessionLastVerify = nil;
        gZONAuthV2SessionLastActivation = nil;
        gZONAuthV2SessionLastRuntimeConfig = nil;
        gZONAuthV2SessionLastBootstrap = nil;
    }

    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2CardAccount service:ZONAuthV2Service error:&error];
    error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2UDIDAccount service:ZONAuthV2Service error:&error];

    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d removeObjectForKey:ZONAuthV2LastVerifyKey];
    [d removeObjectForKey:ZONAuthV2LastActivationKey];
    [d removeObjectForKey:ZONAuthV2LastRuntimeConfigKey];
    [d removeObjectForKey:ZONAuthV2LastBootstrapKey];
}

+ (NSDictionary *)lastVerify {
    @synchronized(self) { return [gZONAuthV2SessionLastVerify copy]; }
}

+ (void)setLastVerify:(NSDictionary *)value {
    @synchronized(self) { gZONAuthV2SessionLastVerify = [value copy]; }
}

+ (NSDictionary *)lastActivation {
    @synchronized(self) { return [gZONAuthV2SessionLastActivation copy]; }
}

+ (void)setLastActivation:(NSDictionary *)value {
    @synchronized(self) { gZONAuthV2SessionLastActivation = [value copy]; }
}

+ (NSDictionary *)lastRuntimeConfig {
    @synchronized(self) { return [gZONAuthV2SessionLastRuntimeConfig copy]; }
}

+ (void)setLastRuntimeConfig:(NSDictionary *)value {
    @synchronized(self) { gZONAuthV2SessionLastRuntimeConfig = [value copy]; }
}

+ (NSDictionary *)lastBootstrap {
    @synchronized(self) { return [gZONAuthV2SessionLastBootstrap copy]; }
}

+ (void)setLastBootstrap:(NSDictionary *)value {
    @synchronized(self) { gZONAuthV2SessionLastBootstrap = [value copy]; }
}

+ (NSString *)lastNoticeFingerprint {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:ZONAuthV2LastNoticeFingerprintKey];
    return [value isKindOfClass:NSString.class] ? value : nil;
}

+ (void)setLastNoticeFingerprint:(NSString *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value.length) [d setObject:value forKey:ZONAuthV2LastNoticeFingerprintKey];
    else [d removeObjectForKey:ZONAuthV2LastNoticeFingerprintKey];
}

@end
