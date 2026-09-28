#import "ZONAuthV2Storage.h"
#import "../菜单/ZONKeychain.h"

static NSString * const ZONAuthV2Service = @"com.zonoe.auth.v2";
static NSString * const ZONAuthV2UDIDAccount = @"udid";
static NSString * const ZONAuthV2CardAccount = @"card";
static NSString * const ZONAuthV2LastVerifyKey = @"zonoe.auth.v2.lastVerify";
static NSString * const ZONAuthV2LastActivationKey = @"zonoe.auth.v2.lastActivation";

@implementation ZONAuthV2Storage

+ (NSString *)stringForAccount:(NSString *)account {
    NSError *error = nil;
    NSData *data = [ZONKeychain dataForAccount:account service:ZONAuthV2Service error:&error];
    if (!data.length) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (void)setString:(NSString *)value account:(NSString *)account {
    if (!value.length) return;
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    [ZONKeychain setData:data account:account service:ZONAuthV2Service error:&error];
}

+ (NSString *)udid { return [self stringForAccount:ZONAuthV2UDIDAccount]; }
+ (void)setUDID:(NSString *)udid { [self setString:udid account:ZONAuthV2UDIDAccount]; }
+ (NSString *)card { return [self stringForAccount:ZONAuthV2CardAccount]; }
+ (void)setCard:(NSString *)card { [self setString:card account:ZONAuthV2CardAccount]; }

+ (void)clearCard {
    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2CardAccount service:ZONAuthV2Service error:&error];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZONAuthV2LastVerifyKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZONAuthV2LastActivationKey];
}

+ (void)clearAll {
    [self clearCard];
    NSError *error = nil;
    [ZONKeychain removeItemForAccount:ZONAuthV2UDIDAccount service:ZONAuthV2Service error:&error];
}

+ (NSDictionary *)lastVerify { return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ZONAuthV2LastVerifyKey]; }
+ (void)setLastVerify:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastVerifyKey]; else [d removeObjectForKey:ZONAuthV2LastVerifyKey];
}
+ (NSDictionary *)lastActivation { return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ZONAuthV2LastActivationKey]; }
+ (void)setLastActivation:(NSDictionary *)value {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (value) [d setObject:value forKey:ZONAuthV2LastActivationKey]; else [d removeObjectForKey:ZONAuthV2LastActivationKey];
}

@end
