#import "ZONAuthorizationResetService.h"
#import "../category/getKeychain.h"
#import "../菜单/ZONKeychain.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import <Security/Security.h>

static NSString * const ZONAuthorizationResetErrorDomain = @"com.zonoe.authorization-reset";
static NSInteger const ZONAuthorizationResetProtectedPreferencesChanged = -1001;

static NSArray<NSString *> *ZONAuthorizationResetProtectedPreferenceKeys(void)
{
    // These keys belong to menu/runtime state, not authorization. P79.8f snapshots
    // them so a future authorization cleanup change cannot silently cross that boundary.
    return @[
        @"fold_base",
        @"fold_draw",
        @"fold_role",
        @"NNGG",
        @"NNGGNNGG",
        @"AADD",
        @"AADDAADD",
        @"AADDssppeedd",
    ];
}

static NSDictionary<NSString *, id> *ZONAuthorizationResetPreferenceSnapshot(NSUserDefaults *defaults)
{
    NSMutableDictionary<NSString *, id> *snapshot = [NSMutableDictionary dictionary];
    for (NSString *key in ZONAuthorizationResetProtectedPreferenceKeys()) {
        id value = [defaults objectForKey:key];
        snapshot[key] = value ?: NSNull.null;
    }
    return snapshot.copy;
}

static BOOL ZONAuthorizationResetPreferenceSnapshotMatches(NSUserDefaults *defaults,
                                                            NSDictionary<NSString *, id> *snapshot)
{
    for (NSString *key in ZONAuthorizationResetProtectedPreferenceKeys()) {
        id before = snapshot[key] ?: NSNull.null;
        id after = [defaults objectForKey:key] ?: NSNull.null;
        if (![before isEqual:after]) return NO;
    }
    return YES;
}

static void ZONAuthorizationResetRestorePreferenceSnapshot(NSUserDefaults *defaults,
                                                            NSDictionary<NSString *, id> *snapshot)
{
    for (NSString *key in ZONAuthorizationResetProtectedPreferenceKeys()) {
        id value = snapshot[key];
        if (!value || value == NSNull.null) {
            [defaults removeObjectForKey:key];
        } else {
            [defaults setObject:value forKey:key];
        }
    }
}

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
        *error = [NSError errorWithDomain:ZONAuthorizationResetErrorDomain
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

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary<NSString *, id> *protectedPreferenceSnapshot =
        ZONAuthorizationResetPreferenceSnapshot(defaults);

    // P79.8b: first remove all obsolete AuthV2/legacy authorization persistence.
    // The cleanup list intentionally excludes menu/runtime preference keys.
    [ZONAuthV2Storage purgeLegacyPersistentState];

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

    if (!ZONAuthorizationResetPreferenceSnapshotMatches(defaults, protectedPreferenceSnapshot)) {
        // Fail closed and restore the menu/runtime snapshot. Authorization cleanup
        // must never silently mutate unrelated product preferences.
        ZONAuthorizationResetRestorePreferenceSnapshot(defaults, protectedPreferenceSnapshot);
        [defaults synchronize];
        NSLog(@"[zonoemenu][P79.8F_P0_RESET] protected menu/runtime preferences changed during authorization reset; restored snapshot");
        if (error) {
            *error = [NSError errorWithDomain:ZONAuthorizationResetErrorDomain
                                         code:ZONAuthorizationResetProtectedPreferencesChanged
                                     userInfo:@{NSLocalizedDescriptionKey: @"授权清理越过了菜单设置边界，已恢复菜单设置"}];
        }
        return NO;
    }

    NSLog(@"[zonoemenu][P79.8F_P0_RESET] authorization reset completed; protected menu/runtime preferences unchanged");
    return YES;
}

@end
