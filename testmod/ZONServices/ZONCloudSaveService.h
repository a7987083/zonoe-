#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONCloudSaveErrorCode) {
    ZONCloudSaveErrorInvalidInput = 3000,
    ZONCloudSaveErrorTransportFailed = 3001,
    ZONCloudSaveErrorInvalidResponse = 3002,
    ZONCloudSaveErrorNoArchive = 3003,
    ZONCloudSaveErrorEntitlementDenied = 3004,
    ZONCloudSaveErrorInvalidDownloadURL = 3005,
};

FOUNDATION_EXPORT NSErrorDomain const ZONCloudSaveErrorDomain;

typedef void (^ZONCloudSaveMetadataCompletion)(NSDictionary * _Nullable metadata, NSError * _Nullable error);
typedef void (^ZONCloudSaveDownloadResolutionCompletion)(NSURL * _Nullable downloadURL, NSError * _Nullable error);

@interface ZONCloudSaveService : NSObject

+ (instancetype)sharedService;

- (void)fetchMetadataForBundleIdentifier:(NSString *)bundleIdentifier
                    metadataBaseURLString:(NSString *)metadataBaseURLString
                               completion:(ZONCloudSaveMetadataCompletion)completion;

/// Returns nil for the historical save/archive buttons which use homezip + bundleID.zip.
- (nullable NSString *)effectiveDownloadAddressForFunction:(NSDictionary *)functionDictionary;

- (void)resolveDownloadURLForBundleIdentifier:(NSString *)bundleIdentifier
                              downloadAddress:(nullable NSString *)downloadAddress
                         archiveBaseURLString:(NSString *)archiveBaseURLString
                             deviceIdentifier:(NSString *)deviceIdentifier
                    entitlementBaseURLString:(NSString *)entitlementBaseURLString
                           bypassEntitlement:(BOOL)bypassEntitlement
                                   completion:(ZONCloudSaveDownloadResolutionCompletion)completion;

@end

NS_ASSUME_NONNULL_END
