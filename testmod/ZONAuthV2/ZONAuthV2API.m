#import "ZONAuthV2API.h"

static NSString * const ZONAuthV2BaseURL = @"https://app.zonoeios.xyz";
static NSString * const ZONAuthV2DylibKey = @"zonoe.main";

@implementation ZONAuthV2API

+ (instancetype)sharedAPI {
    static ZONAuthV2API *api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ api = [ZONAuthV2API new]; });
    return api;
}

- (void)GETPath:(NSString *)path query:(NSDictionary<NSString *, NSString *> *)query completion:(ZONAuthV2JSONCompletion)completion {
    NSURLComponents *components = [NSURLComponents componentsWithString:[ZONAuthV2BaseURL stringByAppendingString:path]];
    NSMutableArray *items = [NSMutableArray array];
    [query enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [items addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];
    components.queryItems = items;
    NSURL *url = components.URL;
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"验证地址无效"}]);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
    request.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { if (completion) completion(nil, error); return; }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"服务器返回 HTTP %ld", (long)http.statusCode]}]);
            return;
        }
        NSError *jsonError = nil;
        id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError] : nil;
        if (![object isKindOfClass:[NSDictionary class]]) {
            if (completion) completion(nil, jsonError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"服务器返回格式错误"}]);
            return;
        }
        if (completion) completion((NSDictionary *)object, nil);
    }] resume];
}

- (void)fetchLicenseForUDID:(NSString *)udid completion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/index/index/apiface" query:@{@"udid": udid ?: @""} completion:completion];
}

- (void)activateUDID:(NSString *)udid card:(NSString *)card completion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/appstore" query:@{@"udid": udid ?: @"", @"code": card ?: @""} completion:completion];
}

- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/index/dylib_verify/config" query:@{@"dylib_key": ZONAuthV2DylibKey} completion:completion];
}

@end
