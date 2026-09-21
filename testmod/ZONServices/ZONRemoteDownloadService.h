#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONRemoteDownloadErrorCode) {
    ZONRemoteDownloadErrorInvalidURL = 3000,
    ZONRemoteDownloadErrorAlreadyRunning = 3001,
    ZONRemoteDownloadErrorTransportFailed = 3002,
    ZONRemoteDownloadErrorInvalidResponse = 3003,
    ZONRemoteDownloadErrorSaveFailed = 3004,
    ZONRemoteDownloadErrorInvalidArchive = 3005,
};

FOUNDATION_EXPORT NSErrorDomain const ZONRemoteDownloadErrorDomain;

typedef void (^ZONRemoteDownloadProgress)(int64_t receivedBytes, int64_t expectedBytes);
typedef void (^ZONRemoteDownloadCompletion)(NSString * _Nullable archivePath, NSError * _Nullable error);

@interface ZONRemoteDownloadService : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedService;

- (void)downloadArchiveFromURL:(NSURL *)url
                      progress:(nullable ZONRemoteDownloadProgress)progress
                    completion:(ZONRemoteDownloadCompletion)completion;

- (void)cancelActiveDownload;

@end

NS_ASSUME_NONNULL_END
