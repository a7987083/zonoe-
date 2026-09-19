#import "ZONAuthorizationResetService.h"
#import "../category/getKeychain.h"
#import "../菜单/ZONKeychain.h"

@implementation ZONAuthorizationResetService

+ (BOOL)clearAuthorizationData:(NSError **)error
{
    if (error) *error = nil;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    // Preserve the exact P62 deletekm UserDefaults clear set.
    NSArray<NSString *> *userDefaultsKeys = @[
        @"zonoeudid",
        @"卡密",
        @"已选择开启秒过广告",
        @"到期时间",
    ];
    for (NSString *key in userDefaultsKeys) {
        [defaults removeObjectForKey:key];
    }

    // Preserve the exact P62 deletekm getKeychain clear set.
    NSArray<NSString *> *legacyKeychainKeys = @[
        @"SJUSERID",
        @"ShiSanGeDZKM",
        @"rjyyz",
    ];
    for (NSString *key in legacyKeychainKeys) {
        [getKeychain removeKeychainDataForKey:key];
    }

    // P62 coordinator reset extension: clear the machine-code cache as part
    // of the same atomic reset API instead of relying on runtime swizzling.
    [getKeychain removeKeychainDataForKey:@"DZUDID"];

    NSArray<NSString *> *bridgeKeys = @[
        @"zonoe.udid.bridge.value",
        @"zonoe.udid.bridge.scheme",
        @"zonoe.udid.bridge.requestTimestamp",
        @"zonoe.udid.bridge.requestNonce",
    ];
    for (NSString *key in bridgeKeys) {
        [defaults removeObjectForKey:key];
    }

    NSError *keychainError = nil;
    BOOL keychainOK = [ZONKeychain removeItemForAccount:@"UDID"
                                                service:@"com.china.TestKeyChain"
                                                  error:&keychainError];

    // The old coordinator called synchronize after its bridge-cache cleanup.
    // Keep that effective P62 behavior here.
    [defaults synchronize];

    if (!keychainOK) {
        if (error) *error = keychainError;
        return NO;
    }

    return YES;
}

@end
