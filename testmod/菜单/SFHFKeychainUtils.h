//
//  SFHFKeychainUtils.h
//
//  Originally created by Buzz Andersen on 10/20/08.
//  Modernized for zonoe while preserving the legacy API contract.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const SFHFKeychainUtilsErrorDomain;

@interface SFHFKeychainUtils : NSObject

#pragma mark - Modern API

/// Reads a UTF-8 string from a generic-password Keychain item.
/// Keychain identity is kSecClassGenericPassword + account + service.
+ (nullable NSString *)stringForAccount:(NSString *)account
                                service:(NSString *)service
                                  error:(NSError * _Nullable * _Nullable)error;

/// Stores or updates a UTF-8 string in a generic-password Keychain item.
+ (BOOL)setString:(NSString *)string
       forAccount:(NSString *)account
          service:(NSString *)service
            error:(NSError * _Nullable * _Nullable)error;

/// Removes a generic-password Keychain item.
/// Missing items are treated as success so reset operations are idempotent.
+ (BOOL)removeItemForAccount:(NSString *)account
                     service:(NSString *)service
                       error:(NSError * _Nullable * _Nullable)error;

#pragma mark - Legacy compatibility API

/// Compatibility wrapper. Equivalent to stringForAccount:service:error:.
+ (nullable NSString *)getPasswordForUsername:(NSString *)username
                               andServiceName:(NSString *)serviceName
                                        error:(NSError * _Nullable * _Nullable)error;

/// Compatibility wrapper preserving the historical updateExisting behavior.
+ (BOOL)storeUsername:(NSString *)username
          andPassword:(NSString *)password
       forServiceName:(NSString *)serviceName
       updateExisting:(BOOL)updateExisting
                error:(NSError * _Nullable * _Nullable)error;

/// Compatibility wrapper. Equivalent to removeItemForAccount:service:error:.
+ (BOOL)deleteItemForUsername:(NSString *)username
               andServiceName:(NSString *)serviceName
                        error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
