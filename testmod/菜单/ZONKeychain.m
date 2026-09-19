#import "ZONKeychain.h"
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
