#import "ZONAuthV2API.h"

#ifndef ZON_AUTH_BOOTSTRAP_BASE_URL
#define ZON_AUTH_BOOTSTRAP_BASE_URL "https://app.zonoeios.xyz"
#endif
#ifndef ZON_AUTH_BOOTSTRAP_DYLIB_KEY
#define ZON_AUTH_BOOTSTRAP_DYLIB_KEY "zonoe.main"
#endif

static NSString *ZONAuthBootstrapBaseURL(void) { return @ZON_AUTH_BOOTSTRAP_BASE_URL; }
static NSString *ZONAuthBootstrapDylibKey(void) { return @ZON_AUTH_BOOTSTRAP_DYLIB_KEY; }

static id ZONRuntimeValue(NSDictionary *config, NSString *key) {
    id value = config[key];
    if (value && value != NSNull.null) return value;
    for (NSString *containerKey in @[@"data", @"config", @"runtime", @"result"]) {
        NSDictionary *nested = [config[containerKey] isKindOfClass:NSDictionary.class] ? config[containerKey] : nil;
        value = nested[key];
        if (value && value != NSNull.null) return value;
    }
    return nil;
}

static NSString *ZONRuntimeString(NSDictionary *config, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = ZONRuntimeValue(config, key);
        if ([value isKindOfClass:NSString.class] && [(NSString *)value length]) return value;
    }
    return @"";
}

@implementation ZONAuthV2API

+ (instancetype)sharedAPI {
    static ZONAuthV2API *api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ api = [ZONAuthV2API new]; });
    return api;
}

- (void)completeJSONRequest:(NSURLRequest *)request completion:(ZONAuthV2JSONCompletion)completion {
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { if (completion) completion(nil, error); return; }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSError *jsonError = nil;
        id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError] : nil;
        NSDictionary *json = [object isKindOfClass:NSDictionary.class] ? object : nil;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            NSString *message = [json[@"message"] isKindOfClass:NSString.class] ? json[@"message"] : [NSString stringWithFormat:@"服务器返回 HTTP %ld", (long)http.statusCode];
            if (completion) completion(json, [NSError errorWithDomain:@"ZONAuthV2" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey:message}]);
            return;
        }
        if (!json) {
            if (completion) completion(nil, jsonError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"服务器返回格式错误"}]);
            return;
        }
        if (completion) completion(json, nil);
    }] resume];
}

- (void)GETPath:(NSString *)path query:(NSDictionary<NSString *, NSString *> *)query completion:(ZONAuthV2JSONCompletion)completion {
    NSURLComponents *components = [NSURLComponents componentsWithString:[ZONAuthBootstrapBaseURL() stringByAppendingString:path]];
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
    [self completeJSONRequest:request completion:completion];
}

- (void)fetchLicenseForUDID:(NSString *)udid completion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/index/index/apiface" query:@{@"udid": udid ?: @""} completion:completion];
}

- (void)activateUDID:(NSString *)udid card:(NSString *)card completion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/appstore" query:@{@"udid": udid ?: @"", @"code": card ?: @""} completion:completion];
}

- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion {
    [self GETPath:@"/index/dylib_verify/config" query:@{@"dylib_key": ZONAuthBootstrapDylibKey()} completion:completion];
}

- (void)postVerifyBody:(NSDictionary *)body runtimeConfig:(NSDictionary *)runtimeConfig completion:(ZONAuthV2JSONCompletion)completion {
    NSString *verifyPath = ZONRuntimeString(runtimeConfig, @[@"verify_path", @"verifyPath"]);
    if (!verifyPath.length) verifyPath = @"/index/dylib_verify/verify";

    NSString *endpoint = ZONRuntimeString(runtimeConfig, @[@"endpoint_url", @"endpointURL", @"endpoint", @"base_url", @"baseURL", @"api_endpoint"]);
    NSString *urlString = nil;
    if ([verifyPath hasPrefix:@"http://"] || [verifyPath hasPrefix:@"https://"]) {
        urlString = verifyPath;
    } else {
        NSString *base = endpoint.length ? endpoint : ZONAuthBootstrapBaseURL();
        if ([base hasSuffix:@"/"] && [verifyPath hasPrefix:@"/"]) base = [base substringToIndex:base.length - 1];
        else if (![base hasSuffix:@"/"] && ![verifyPath hasPrefix:@"/"]) base = [base stringByAppendingString:@"/"];
        urlString = [base stringByAppendingString:verifyPath];
    }

    NSURL *url = [NSURL URLWithString:urlString ?: @""];
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"Verify 地址无效"}]);
        return;
    }
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (!data) { if (completion) completion(nil, jsonError); return; }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPBody = data;
    [self completeJSONRequest:request completion:completion];
}

@end
