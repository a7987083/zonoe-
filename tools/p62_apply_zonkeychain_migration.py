from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
wx = ROOT / 'testmod/Bsphp/WX_NongShiFu123.mm'
pbx = ROOT / 'testmod.xcodeproj/project.pbxproj'
menu = ROOT / 'testmod/菜单'

wx_text = wx.read_text(encoding='utf-8')

replacements = [
    ('#import "SFHFKeychainUtils.h"', '#import "ZONKeychain.h"'),
    ('[SFHFKeychainUtils getPasswordForUsername:@"UDID" andServiceName:@"com.china.TestKeyChain" error:&error]',
     '[ZONKeychain stringForAccount:@"UDID" service:@"com.china.TestKeyChain" error:&error]'),
    ('[SFHFKeychainUtils storeUsername:@"UDID" andPassword:UDID\n                                       forServiceName:@"com.china.TestKeyChain" updateExisting:YES error:&error]',
     '[ZONKeychain setString:UDID\n                    forAccount:@"UDID"\n                       service:@"com.china.TestKeyChain"\n                         error:&error]'),
    ('[SFHFKeychainUtils deleteItemForUsername:@"UDID"\n                                               andServiceName:@"com.china.TestKeyChain"\n                                                        error:&error]',
     '[ZONKeychain removeItemForAccount:@"UDID"\n                                      service:@"com.china.TestKeyChain"\n                                        error:&error]'),
    ('// 删除 SFHFKeychainUtils 中的 UDID', '// 删除独立 ZONKeychain 中的旧 UDID identity'),
]

expected_counts = [1, 2, 1, 1, 1]
for (old, new), expected in zip(replacements, expected_counts):
    found = wx_text.count(old)
    if found != expected:
        raise SystemExit(f'WX replacement mismatch: expected {expected}, found {found}: {old[:80]!r}')
    wx_text = wx_text.replace(old, new)

wx.write_text(wx_text, encoding='utf-8')

header = r'''#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const ZONKeychainErrorDomain;

@interface ZONKeychain : NSObject

+ (nullable NSData *)dataForAccount:(NSString *)account
                            service:(NSString *)service
                              error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)setData:(NSData *)data
     forAccount:(NSString *)account
        service:(NSString *)service
          error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSString *)stringForAccount:(NSString *)account
                                service:(NSString *)service
                                  error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)setString:(NSString *)string
       forAccount:(NSString *)account
          service:(NSString *)service
            error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)removeItemForAccount:(NSString *)account
                     service:(NSString *)service
                       error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
'''

impl = r'''#import "ZONKeychain.h"
#import <Security/Security.h>

NSErrorDomain const ZONKeychainErrorDomain = @"com.zonoe.keychain";

@implementation ZONKeychain

+ (NSMutableDictionary *)baseQueryForAccount:(NSString *)account service:(NSString *)service
{
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecAttrService: service,
    } mutableCopy];
}

+ (BOOL)validateAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    if (account == nil || service == nil) {
        if (error) {
            *error = [NSError errorWithDomain:ZONKeychainErrorDomain
                                         code:errSecParam
                                     userInfo:@{NSLocalizedDescriptionKey: @"Keychain account/service must not be nil"}];
        }
        return NO;
    }
    if (error) *error = nil;
    return YES;
}

+ (NSError *)errorForStatus:(OSStatus)status operation:(NSString *)operation
{
    NSString *message = nil;
    if (@available(iOS 11.3, *)) {
        message = CFBridgingRelease(SecCopyErrorMessageString(status, NULL));
    }
    if (message.length == 0) {
        message = [NSString stringWithFormat:@"Keychain %@ failed (%d)", operation, (int)status];
    }
    return [NSError errorWithDomain:ZONKeychainErrorDomain
                               code:status
                           userInfo:@{NSLocalizedDescriptionKey: message,
                                      @"operation": operation}];
}

+ (NSData *)dataForAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    if (![self validateAccount:account service:service error:error]) return nil;

    NSMutableDictionary *query = [self baseQueryForAccount:account service:service];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) return nil;
    if (status != errSecSuccess) {
        if (error) *error = [self errorForStatus:status operation:@"read"];
        if (result) CFRelease(result);
        return nil;
    }

    return CFBridgingRelease(result);
}

+ (BOOL)setData:(NSData *)data forAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    if (![self validateAccount:account service:service error:error] || data == nil) {
        if (data == nil && error) {
            *error = [NSError errorWithDomain:ZONKeychainErrorDomain
                                         code:errSecParam
                                     userInfo:@{NSLocalizedDescriptionKey: @"Keychain data must not be nil"}];
        }
        return NO;
    }

    NSDictionary *query = [self baseQueryForAccount:account service:service];
    NSDictionary *update = @{(__bridge id)kSecValueData: data};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query,
                                    (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *add = [query mutableCopy];
        add[(__bridge id)kSecAttrLabel] = service;
        add[(__bridge id)kSecValueData] = data;
        status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    }

    if (status != errSecSuccess) {
        if (error) *error = [self errorForStatus:status operation:@"write"];
        return NO;
    }
    return YES;
}

+ (NSString *)stringForAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    NSData *data = [self dataForAccount:account service:service error:error];
    if (!data) return nil;

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string && error) {
        *error = [NSError errorWithDomain:ZONKeychainErrorDomain
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"Keychain value is not valid UTF-8"}];
    }
    return string;
}

+ (BOOL)setString:(NSString *)string forAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    if (string == nil) {
        if (error) {
            *error = [NSError errorWithDomain:ZONKeychainErrorDomain
                                         code:errSecParam
                                     userInfo:@{NSLocalizedDescriptionKey: @"Keychain string must not be nil"}];
        }
        return NO;
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forAccount:account service:service error:error];
}

+ (BOOL)removeItemForAccount:(NSString *)account service:(NSString *)service error:(NSError **)error
{
    if (![self validateAccount:account service:service error:error]) return NO;

    NSDictionary *query = [self baseQueryForAccount:account service:service];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecItemNotFound) {
        if (error) *error = nil;
        return YES;
    }
    if (status != errSecSuccess) {
        if (error) *error = [self errorForStatus:status operation:@"delete"];
        return NO;
    }
    return YES;
}

@end
'''

(menu / 'ZONKeychain.h').write_text(header, encoding='utf-8')
(menu / 'ZONKeychain.m').write_text(impl, encoding='utf-8')

for old_name in ('SFHFKeychainUtils.h', 'SFHFKeychainUtils.m'):
    old = menu / old_name
    if old.exists():
        old.unlink()

pbx_text = pbx.read_text(encoding='utf-8')
for old_name, new_name in (
    ('SFHFKeychainUtils.h', 'ZONKeychain.h'),
    ('SFHFKeychainUtils.m', 'ZONKeychain.m'),
):
    count = pbx_text.count(old_name)
    if count < 3:
        raise SystemExit(f'PBX expected multiple references to {old_name}, found {count}')
    pbx_text = pbx_text.replace(old_name, new_name)
pbx.write_text(pbx_text, encoding='utf-8')

# Final invariants.
if 'SFHFKeychainUtils' in wx.read_text(encoding='utf-8'):
    raise SystemExit('WX still references SFHFKeychainUtils')
if 'SFHFKeychainUtils' in pbx.read_text(encoding='utf-8'):
    raise SystemExit('PBX still references SFHFKeychainUtils')
if (menu / 'SFHFKeychainUtils.h').exists() or (menu / 'SFHFKeychainUtils.m').exists():
    raise SystemExit('legacy SFHF files still exist')

print('P62 ZONKeychain migration applied successfully')
