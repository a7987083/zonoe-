#import "ZONCloudSaveService.h"

NSErrorDomain const ZONCloudSaveErrorDomain = @"ZONCloudSaveErrorDomain";

@implementation ZONCloudSaveService

+ (instancetype)sharedService
{
    static ZONCloudSaveService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[ZONCloudSaveService alloc] init];
    });
    return service;
}

- (NSError *)errorWithCode:(ZONCloudSaveErrorCode)code description:(NSString *)description underlying:(NSError *)underlying
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (description.length) userInfo[NSLocalizedDescriptionKey] = description;
    if (underlying) userInfo[NSUnderlyingErrorKey] = underlying;
    return [NSError errorWithDomain:ZONCloudSaveErrorDomain code:code userInfo:userInfo];
}

- (void)finishOnMain:(dispatch_block_t)block
{
    if (!block) return;
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)fetchMetadataForBundleIdentifier:(NSString *)bundleIdentifier
                    metadataBaseURLString:(NSString *)metadataBaseURLString
                               completion:(ZONCloudSaveMetadataCompletion)completion
{
    if (bundleIdentifier.length == 0 || metadataBaseURLString.length == 0) {
        [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidInput description:@"云存档参数无效" underlying:nil]); }];
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"%@%@.json", metadataBaseURLString, bundleIdentifier];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidInput description:@"云存档地址无效" underlying:nil]); }];
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorTransportFailed description:@"网络连接失败，请检查网络" underlying:error]); }];
            return;
        }

        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (!data.length || (http && (http.statusCode < 200 || http.statusCode >= 300))) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidResponse description:@"未获取到服务器数据" underlying:nil]); }];
            return;
        }

        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (![object isKindOfClass:[NSDictionary class]]) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidResponse description:@"服务器数据格式错误" underlying:jsonError]); }];
            return;
        }

        NSDictionary *metadata = (NSDictionary *)object;
        if ([metadata[@"code"] integerValue] == 500) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorNoArchive description:@"未查询到有云存档" underlying:nil]); }];
            return;
        }

        id functions = metadata[@"功能"];
        if (functions && ![functions isKindOfClass:[NSArray class]]) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidResponse description:@"云存档功能列表格式错误" underlying:nil]); }];
            return;
        }

        [self finishOnMain:^{ if (completion) completion(metadata, nil); }];
    }];
    [task resume];
}

- (BOOL)isEntitlementValidWithDictionary:(NSDictionary *)dictionary
{
    NSNumber *code = dictionary[@"code"];
    NSString *msg = dictionary[@"msg"];
    NSNumber *expire = dictionary[@"expire"];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return code && [code intValue] == 1 &&
           [msg isKindOfClass:[NSString class]] && [msg isEqualToString:@"ok"] &&
           expire && [expire doubleValue] > now;
}

- (void)resolveDownloadURLForBundleIdentifier:(NSString *)bundleIdentifier
                              downloadAddress:(NSString *)downloadAddress
                         archiveBaseURLString:(NSString *)archiveBaseURLString
                        entitlementURLString:(NSString *)entitlementURLString
                                   completion:(ZONCloudSaveDownloadResolutionCompletion)completion
{
    if (bundleIdentifier.length == 0 || archiveBaseURLString.length == 0 || entitlementURLString.length == 0) {
        [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidInput description:@"云存档下载参数无效" underlying:nil]); }];
        return;
    }

    NSURL *entitlementURL = [NSURL URLWithString:entitlementURLString];
    if (!entitlementURL) {
        [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidInput description:@"验证链接错误" underlying:nil]); }];
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:entitlementURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorTransportFailed description:@"无法验证购买信息，请检查网络" underlying:error]); }];
            return;
        }

        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (!data.length || (http && (http.statusCode < 200 || http.statusCode >= 300))) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidResponse description:@"购买信息数据错误" underlying:nil]); }];
            return;
        }

        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (![object isKindOfClass:[NSDictionary class]]) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidResponse description:@"购买信息解析失败" underlying:jsonError]); }];
            return;
        }

        if (![self isEntitlementValidWithDictionary:(NSDictionary *)object]) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorEntitlementDenied description:@"你没有购买\n请先购买再尝试解锁" underlying:nil]); }];
            return;
        }

        NSString *downloadURLString = nil;
        if (downloadAddress == nil) {
            downloadURLString = [NSString stringWithFormat:@"%@%@.zip", archiveBaseURLString, bundleIdentifier];
        } else if (downloadAddress.length == 0) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidDownloadURL description:@"下载地址为空" underlying:nil]); }];
            return;
        } else {
            downloadURLString = downloadAddress;
        }

        NSString *encoded = [downloadURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *downloadURL = [NSURL URLWithString:encoded ?: @""];
        if (!downloadURL) {
            [self finishOnMain:^{ if (completion) completion(nil, [self errorWithCode:ZONCloudSaveErrorInvalidDownloadURL description:@"下载链接无效" underlying:nil]); }];
            return;
        }

        [self finishOnMain:^{ if (completion) completion(downloadURL, nil); }];
    }];
    [task resume];
}

@end
