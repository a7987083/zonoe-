//
//  SFHFKeychainUtils.m
//
//  Originally created by Buzz Andersen on 10/20/08.
//  Modernized for zonoe while preserving the legacy API contract.
//

#import "SFHFKeychainUtils.h"
#import <Security/Security.h>

NSErrorDomain const SFHFKeychainUtilsErrorDomain = @"SFHFKeychainUtilsErrorDomain";

static const NSInteger SFHFKeychainUtilsInvalidArgumentError = -2000;
static const NSInteger SFHFKeychainUtilsInvalidStringDataError = -1999;

@implementation SFHFKeychainUtils

#pragma mark - Private helpers

+ (NSMutableDictionary *)baseQueryForAccount:(NSString *)account service:(NSString *)service
{
    return [@{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : account,
        (__bridge id)kSecAttrService : service,
    } mutableCopy];
}

+ (void)setError:(NSError * _Nullable * _Nullable)error
          status:(OSStatus)status
       operation:(NSString *)operation
{
    if (error == NULL) {
        return;
    }

    NSString *message = nil;
    CFStringRef statusMessage = SecCopyErrorMessageString(status, NULL);
    if (statusMessage != NULL) {
        message = CFBridgingRelease(statusMessage);
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = message.length > 0
        ? [NSString stringWithFormat:@"Keychain %@ failed: %@", operation, message]
        : [NSString stringWithFormat:@"Keychain %@ failed (OSStatus %d)", operation, (int)status];
    userInfo[@"operation"] = operation;
    userInfo[@"OSStatus"] = @(status);

    *error = [NSError errorWithDomain:SFHFKeychainUtilsErrorDomain
                                 code:status
                             userInfo:userInfo];
}

+ (BOOL)validateAccount:(NSString *)account
                service:(NSString *)service
                  value:(nullable NSString *)value
          requiresValue:(BOOL)requiresValue
                  error:(NSError * _Nullable * _Nullable)error
{
    BOOL valid = account.length > 0 && service.length > 0 && (!requiresValue || value != nil);
    if (valid) {
        if (error != NULL) {
            *error = nil;
        }
        return YES;
    }

    if (error != NULL) {
        *error = [NSError errorWithDomain:SFHFKeychainUtilsErrorDomain
                                     code:SFHFKeychainUtilsInvalidArgumentError
                                 userInfo:@{NSLocalizedDescriptionKey : @"Keychain account, service, or value is invalid."}];
    }
    return NO;
}

#pragma mark - Modern API

+ (nullable NSString *)stringForAccount:(NSString *)account
                                service:(NSString *)service
                                  error:(NSError * _Nullable * _Nullable)error
{
    if (![self validateAccount:account service:service value:nil requiresValue:NO error:error]) {
        return nil;
    }

    NSMutableDictionary *query = [self baseQueryForAccount:account service:service];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status == errSecItemNotFound) {
        if (error != NULL) {
            *error = nil;
        }
        return nil;
    }

    if (status != errSecSuccess) {
        [self setError:error status:status operation:@"read"];
        if (result != NULL) {
            CFRelease(result);
        }
        return nil;
    }

    NSData *data = CFBridgingRelease(result);
    if (![data isKindOfClass:[NSData class]]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:SFHFKeychainUtilsErrorDomain
                                         code:SFHFKeychainUtilsInvalidStringDataError
                                     userInfo:@{NSLocalizedDescriptionKey : @"Keychain item does not contain NSData."}];
        }
        return nil;
    }

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string == nil && error != NULL) {
        *error = [NSError errorWithDomain:SFHFKeychainUtilsErrorDomain
                                     code:SFHFKeychainUtilsInvalidStringDataError
                                 userInfo:@{NSLocalizedDescriptionKey : @"Keychain item is not valid UTF-8 string data."}];
    }
    return string;
}

+ (BOOL)setString:(NSString *)string
       forAccount:(NSString *)account
          service:(NSString *)service
            error:(NSError * _Nullable * _Nullable)error
{
    if (![self validateAccount:account service:service value:string requiresValue:YES error:error]) {
        return NO;
    }

    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:SFHFKeychainUtilsErrorDomain
                                         code:SFHFKeychainUtilsInvalidStringDataError
                                     userInfo:@{NSLocalizedDescriptionKey : @"Unable to encode value as UTF-8."}];
        }
        return NO;
    }

    NSDictionary *query = [self baseQueryForAccount:account service:service];
    NSDictionary *attributes = @{
        (__bridge id)kSecValueData : data,
        (__bridge id)kSecAttrLabel : service,
    };

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query,
                                    (__bridge CFDictionaryRef)attributes);

    if (status == errSecItemNotFound) {
        NSMutableDictionary *addQuery = [query mutableCopy];
        addQuery[(__bridge id)kSecValueData] = data;
        addQuery[(__bridge id)kSecAttrLabel] = service;
        status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    }

    if (status != errSecSuccess) {
        [self setError:error status:status operation:@"write"];
        return NO;
    }

    if (error != NULL) {
        *error = nil;
    }
    return YES;
}

+ (BOOL)removeItemForAccount:(NSString *)account
                     service:(NSString *)service
                       error:(NSError * _Nullable * _Nullable)error
{
    if (![self validateAccount:account service:service value:nil requiresValue:NO error:error]) {
        return NO;
    }

    NSDictionary *query = [self baseQueryForAccount:account service:service];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

    if (status == errSecItemNotFound) {
        if (error != NULL) {
            *error = nil;
        }
        return YES;
    }

    if (status != errSecSuccess) {
        [self setError:error status:status operation:@"delete"];
        return NO;
    }

    if (error != NULL) {
        *error = nil;
    }
    return YES;
}

#pragma mark - Legacy compatibility API

+ (nullable NSString *)getPasswordForUsername:(NSString *)username
                               andServiceName:(NSString *)serviceName
                                        error:(NSError * _Nullable * _Nullable)error
{
    return [self stringForAccount:username service:serviceName error:error];
}

+ (BOOL)storeUsername:(NSString *)username
          andPassword:(NSString *)password
       forServiceName:(NSString *)serviceName
       updateExisting:(BOOL)updateExisting
                error:(NSError * _Nullable * _Nullable)error
{
    if (![self validateAccount:username service:serviceName value:password requiresValue:YES error:error]) {
        return NO;
    }

    if (!updateExisting) {
        NSError *readError = nil;
        NSString *existingValue = [self stringForAccount:username service:serviceName error:&readError];
        if (readError != nil) {
            if (error != NULL) {
                *error = readError;
            }
            return NO;
        }
        if (existingValue != nil) {
            if (error != NULL) {
                *error = nil;
            }
            return YES;
        }
    }

    return [self setString:password forAccount:username service:serviceName error:error];
}

+ (BOOL)deleteItemForUsername:(NSString *)username
               andServiceName:(NSString *)serviceName
                        error:(NSError * _Nullable * _Nullable)error
{
    return [self removeItemForAccount:username service:serviceName error:error];
}

@end
