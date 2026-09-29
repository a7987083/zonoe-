#import "ZONAuthorizationResetService.h"
#import "../category/getKeychain.h"
#import "../菜单/ZONKeychain.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import <Security/Security.h>

static BOOL ZONDeleteAllVisibleGenericPasswordsForService(NSString *service, NSError **error)
{
    if (!service.length) return YES;
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
    };
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess || status == errSecItemNotFound) return YES;

    if (error) {
        NSString *message = nil;
        if (@available(iOS 11.3, *)) {
            message = CFBridgingRelease(SecCopyErrorMessageString(status, NULL));
        }
        *error = [NSError errorWithDomain:@"com.zonoe.authorization-reset"
                                     code:status
                                 userInfo:@{NSLocalizedDescriptionKey: message ?: @"Keychain 授权记录清理失败",
                                            @"service": service}];
    }
    return NO;
}

@implementation ZONAuthorizationResetService

+ (BOOL)clearAuthorizationData:(NSError **)error
{
    if (error) *error = nil;

    // P79.8b: first remove all obsolete AuthV2/legacy authorization persistence.
    // The cleanup list intentionally excludes menu/runtime preference keys.
    [ZONAuthV2Storage purgeLegacyPersistentState];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *userDefaultsKeys = @[
        @"zonoeudid",
        @"卡密",
        @"已选择开启秒过广告",
        @"到期时间",
    ];
    for (NSString *key in userDefaultsKeys) {
        [defaults removeObjectForKey:key];
    }

    NSArray<NSString *> *legacyKeychainKeys = @[
        @"SJUSERID",
        @"ShiSanGeDZKM",
        @"rjyyz",
        @"DZUDID",
    ];
    for (NSString *key in legacyKeychainKeys) {
        [getKeychain removeKeychainDataForKey:key];
    }

    NSArray<NSString *> *bridgeKeys = @[
        @"zonoe.udid.bridge.value",
        @"zonoe.udid.bridge.scheme",
        @"zonoe.udid.bridge.requestTimestamp",
        @"zonoe.udid.bridge.requestNonce",
    ];
    for (NSString *key in bridgeKeys) {
        [defaults removeObjectForKey:key];
    }

    [ZONAuthV2Storage clearAll];

    // Delete the whole authorization service surface visible to this process,
    // not only one account. This also clears records in any shared Keychain
    // access group that the current host App is actually entitled to access.
    NSMutableArray<NSString *> *services = [NSMutableArray arrayWithArray:legacyKeychainKeys];
    [services addObject:@"com.zonoe.auth.v2"];
    [services addObject:@"com.china.TestKeyChain"];

    NSError *bulkDeleteError = nil;
    for (NSString *service in services) {
        if (!ZONDeleteAllVisibleGenericPasswordsForService(service, &bulkDeleteError)) {
            NSLog(@"[zonoemenu][authorization-reset] bulk Keychain delete failed service=%@ error=%@", service, bulkDeleteError);
            if (error) *error = bulkDeleteError;
            return NO;
        }
    }

    NSError *keychainError = nil;
    BOOL keychainOK = [ZONKeychain removeItemForAccount:@"UDID"
                                                service:@"com.china.TestKeyChain"
                                                  error:&keychainError];

    [defaults synchronize];

    if (!keychainOK) {
        if (error) *error = keychainError;
        return NO;
    }

    return YES;
}

@end
