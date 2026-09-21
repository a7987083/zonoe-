#import "ZONRemoteDownloadService.h"

NSErrorDomain const ZONRemoteDownloadErrorDomain = @"ZONRemoteDownloadErrorDomain";

@interface ZONRemoteDownloadService ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *activeTask;
@property (nonatomic, copy) ZONRemoteDownloadProgress progressBlock;
@property (nonatomic, copy) ZONRemoteDownloadCompletion completionBlock;
@end

@implementation ZONRemoteDownloadService

+ (instancetype)sharedService
{
    static ZONRemoteDownloadService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[ZONRemoteDownloadService alloc] initPrivate];
    });
    return service;
}

- (instancetype)init
{
    return [ZONRemoteDownloadService sharedService];
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:queue];
    }
    return self;
}

- (NSError *)errorWithCode:(ZONRemoteDownloadErrorCode)code description:(NSString *)description underlying:(NSError *)underlying
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (description.length) info[NSLocalizedDescriptionKey] = description;
    if (underlying) info[NSUnderlyingErrorKey] = underlying;
    return [NSError errorWithDomain:ZONRemoteDownloadErrorDomain code:code userInfo:info];
}

- (void)finishWithArchivePath:(NSString *)archivePath error:(NSError *)error
{
    ZONRemoteDownloadCompletion completion = self.completionBlock;
    self.progressBlock = nil;
    self.completionBlock = nil;
    self.activeTask = nil;
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(archivePath, error);
    });
}

- (void)downloadArchiveFromURL:(NSURL *)url
                      progress:(ZONRemoteDownloadProgress)progress
                    completion:(ZONRemoteDownloadCompletion)completion
{
    @synchronized (self) {
        if (!url || !url.scheme.length || !url.host.length ||
            !([url.scheme.lowercaseString isEqualToString:@"http"] || [url.scheme.lowercaseString isEqualToString:@"https"])) {
            NSError *error = [self errorWithCode:ZONRemoteDownloadErrorInvalidURL
                                     description:@"下载链接无效"
                                      underlying:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
            return;
        }
        if (self.activeTask) {
            NSError *error = [self errorWithCode:ZONRemoteDownloadErrorAlreadyRunning
                                     description:@"已有下载任务正在进行"
                                      underlying:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
            return;
        }
        self.progressBlock = progress;
        self.completionBlock = completion;
        self.activeTask = [self.session downloadTaskWithURL:url];
        [self.activeTask resume];
    }
}

- (void)cancelActiveDownload
{
    @synchronized (self) {
        [self.activeTask cancel];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
 totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    ZONRemoteDownloadProgress progress = self.progressBlock;
    if (!progress) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        progress(totalBytesWritten, totalBytesExpectedToWrite);
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didFinishDownloadingToURL:(NSURL *)location
{
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)downloadTask.response;
    if ([http isKindOfClass:[NSHTTPURLResponse class]] && (http.statusCode < 200 || http.statusCode >= 300)) {
        [self finishWithArchivePath:nil
                             error:[self errorWithCode:ZONRemoteDownloadErrorInvalidResponse
                                           description:[NSString stringWithFormat:@"服务器返回错误状态：%ld", (long)http.statusCode]
                                            underlying:nil]];
        return;
    }

    NSString *suggested = downloadTask.response.suggestedFilename;
    if (!suggested.length) suggested = downloadTask.originalRequest.URL.lastPathComponent;
    if (!suggested.length) suggested = @"zonoe-download.zip";
    if (![[suggested.pathExtension lowercaseString] isEqualToString:@"zip"]) {
        [self finishWithArchivePath:nil
                             error:[self errorWithCode:ZONRemoteDownloadErrorInvalidArchive
                                           description:@"下载文件不是 ZIP"
                                            underlying:nil]];
        return;
    }

    NSString *downloadRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe-download"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *dirError = nil;
    if (![fm createDirectoryAtPath:downloadRoot withIntermediateDirectories:YES attributes:nil error:&dirError]) {
        [self finishWithArchivePath:nil
                             error:[self errorWithCode:ZONRemoteDownloadErrorSaveFailed
                                           description:@"无法创建下载临时目录"
                                            underlying:dirError]];
        return;
    }

    NSString *name = [NSString stringWithFormat:@"%@-%@.zip", NSUUID.UUID.UUIDString, suggested.stringByDeletingPathExtension];
    NSString *destination = [downloadRoot stringByAppendingPathComponent:name];
    NSError *moveError = nil;
    if (![fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:destination] error:&moveError]) {
        [self finishWithArchivePath:nil
                             error:[self errorWithCode:ZONRemoteDownloadErrorSaveFailed
                                           description:@"保存下载文件失败"
                                            underlying:moveError]];
        return;
    }

    [self finishWithArchivePath:destination error:nil];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) return;
    [self finishWithArchivePath:nil
                         error:[self errorWithCode:ZONRemoteDownloadErrorTransportFailed
                                       description:[NSString stringWithFormat:@"下载失败: %@", error.localizedDescription ?: @"未知错误"]
                                        underlying:error]];
}

@end
