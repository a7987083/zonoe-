#import <Foundation/Foundation.h>

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
