#import "ZONAuthV2API.h"
#import "ZONAuthV2Storage.h"

#ifndef ZON_AUTH_BOOTSTRAP_URL
#define ZON_AUTH_BOOTSTRAP_URL "https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json"
#endif
#ifndef ZON_AUTH_BOOTSTRAP_DYLIB_KEY
#define ZON_AUTH_BOOTSTRAP_DYLIB_KEY "zonoe.main"
#endif

static NSString *ZONAuthBootstrapURLString(void) { return @ZON_AUTH_BOOTSTRAP_URL; }
static NSString *ZONAuthBootstrapDylibKey(void) { return @ZON_AUTH_BOOTSTRAP_DYLIB_KEY; }

static id ZONConfigValue(NSDictionary *config, NSString *key) {
    id value = config[key];
    if (value && value != NSNull.null) return value;
    for (NSString *containerKey in @[@"data", @"config", @"runtime", @"result"]) {
        NSDictionary *nested = [config[containerKey] isKindOfClass:NSDictionary.class] ? config[containerKey] : nil;
        value = nested[key];
        if (value && value != NSNull.null) return value;
    }
    return nil;
}

static NSString *ZONConfigString(NSDictionary *config, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = ZONConfigValue(config, key);
        if ([value isKindOfClass:NSString.class] && [(NSString *)value length]) return value;
    }
    return @"";
}

static NSArray<NSString *> *ZONConfigStringArray(NSDictionary *config, NSString *key) {
    id value = ZONConfigValue(config, key);
    if (![value isKindOfClass:NSArray.class]) return @[];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (id item in (NSArray *)value) {
        if ([item isKindOfClass:NSString.class] && [(NSString *)item length]) [result addObject:item];
    }
    return result;
}

static NSString *ZONJoinURL(NSString *base, NSString *path) {
    if (!base.length || !path.length) return @"";
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) return path;
    NSString *normalizedBase = base;
    if ([normalizedBase hasSuffix:@"/"]) normalizedBase = [normalizedBase substringToIndex:normalizedBase.length - 1];
    NSString *normalizedPath = [path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path];
    return [normalizedBase stringByAppendingString:normalizedPath];
}

@interface ZONAuthV2API ()
@property (nonatomic, strong, nullable) NSDictionary *sessionBootstrap;
@end

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

- (BOOL)isUsableBootstrap:(NSDictionary *)json {
    NSDictionary *config = [json[@"config"] isKindOfClass:NSDictionary.class] ? json[@"config"] : json;
    id ok = config[@"ok"];
    if (ok && [ok respondsToSelector:@selector(boolValue)] && ![ok boolValue]) return NO;
    NSArray<NSString *> *endpoints = ZONConfigStringArray(config, @"api_endpoints");
    if (!endpoints.count) return NO;
    id expires = config[@"expires_at"];
    if ([expires respondsToSelector:@selector(doubleValue)]) {
        NSTimeInterval expiry = [expires doubleValue];
        if (expiry > 0 && expiry < NSDate.date.timeIntervalSince1970) return NO;
    }
    return YES;
}

- (NSDictionary *)normalizedBootstrap:(NSDictionary *)json {
    NSDictionary *config = [json[@"config"] isKindOfClass:NSDictionary.class] ? json[@"config"] : json;
    return config ?: @{};
}

- (void)fetchBootstrapWithCompletion:(ZONAuthV2JSONCompletion)completion {
    if ([self isUsableBootstrap:self.sessionBootstrap]) {
        if (completion) completion(self.sessionBootstrap, nil);
        return;
    }

    NSURL *url = [NSURL URLWithString:ZONAuthBootstrapURLString()];
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-10 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 地址无效"}]);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
    request.HTTPMethod = @"GET";

    [self completeJSONRequest:request completion:^(NSDictionary *json, NSError *error) {
        NSDictionary *normalized = json ? [self normalizedBootstrap:json] : nil;
        if (!error && [self isUsableBootstrap:normalized]) {
            self.sessionBootstrap = normalized;
            [ZONAuthV2Storage setLastBootstrap:normalized];
            if (completion) completion(normalized, nil);
            return;
        }

        NSDictionary *lastKnownGood = [ZONAuthV2Storage lastBootstrap];
        if ([self isUsableBootstrap:lastKnownGood]) {
            self.sessionBootstrap = lastKnownGood;
            if (completion) completion(lastKnownGood, nil);
            return;
        }

        NSError *finalError = error ?: [NSError errorWithDomain:@"ZONAuthV2" code:-11 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 配置不可用"}];
        if (completion) completion(json, finalError);
    }];
}

- (NSString *)apiBaseFromBootstrap:(NSDictionary *)bootstrap {
    return ZONConfigStringArray(bootstrap, @"api_endpoints").firstObject ?: @"";
}

- (void)GETAbsoluteURL:(NSString *)urlString query:(NSDictionary<NSString *, NSString *> *)query completion:(ZONAuthV2JSONCompletion)completion {
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    if (!components) {
        if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-12 userInfo:@{NSLocalizedDescriptionKey:@"API 地址无效"}]);
        return;
    }
    NSMutableArray<NSURLQueryItem *> *items = components.queryItems.mutableCopy ?: [NSMutableArray array];
    [query enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [items addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];
    components.queryItems = items;
    NSURL *url = components.URL;
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-13 userInfo:@{NSLocalizedDescriptionKey:@"API 地址无效"}]);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
    request.HTTPMethod = @"GET";
    [self completeJSONRequest:request completion:completion];
}

- (void)GETBusinessPath:(NSString *)path query:(NSDictionary<NSString *, NSString *> *)query completion:(ZONAuthV2JSONCompletion)completion {
    [self fetchBootstrapWithCompletion:^(NSDictionary *bootstrap, NSError *bootstrapError) {
        if (bootstrapError || !bootstrap) {
            if (completion) completion(nil, bootstrapError);
            return;
        }
        NSString *base = [self apiBaseFromBootstrap:bootstrap];
        NSString *urlString = ZONJoinURL(base, path);
        if (!urlString.length) {
            if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-14 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 未返回业务 API 地址"}]);
            return;
        }
        [self GETAbsoluteURL:urlString query:query completion:completion];
    }];
}

- (void)fetchLicenseForUDID:(NSString *)udid completion:(ZONAuthV2JSONCompletion)completion {
    [self GETBusinessPath:@"/index/index/apiface" query:@{@"udid": udid ?: @""} completion:completion];
}

- (void)activateUDID:(NSString *)udid card:(NSString *)card completion:(ZONAuthV2JSONCompletion)completion {
    [self GETBusinessPath:@"/appstore" query:@{@"udid": udid ?: @"", @"code": card ?: @""} completion:completion];
}

- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion {
    [self fetchBootstrapWithCompletion:^(NSDictionary *bootstrap, NSError *bootstrapError) {
        if (bootstrapError || !bootstrap) {
            if (completion) completion(nil, bootstrapError);
            return;
        }

        NSString *runtimeURL = @"";
        for (NSString *candidate in ZONConfigStringArray(bootstrap, @"bootstrap_urls")) {
            if ([candidate containsString:@"/index/dylib_verify/config"]) {
                runtimeURL = candidate;
                break;
            }
        }
        if (!runtimeURL.length) {
            runtimeURL = ZONJoinURL([self apiBaseFromBootstrap:bootstrap], @"/index/dylib_verify/config");
        }
        if (!runtimeURL.length) {
            if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-15 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 未返回 Runtime Config 地址"}]);
            return;
        }
        [self GETAbsoluteURL:runtimeURL query:@{@"dylib_key": ZONAuthBootstrapDylibKey()} completion:completion];
    }];
}

- (NSString *)verifyURLForRuntimeConfig:(NSDictionary *)runtimeConfig bootstrap:(NSDictionary *)bootstrap {
    NSString *verifyPath = ZONConfigString(runtimeConfig, @[@"verify_path", @"verifyPath"]);
    if (!verifyPath.length) verifyPath = ZONConfigString(bootstrap, @[@"verify_path", @"verifyPath"]);

    NSString *base = ZONConfigStringArray(runtimeConfig, @"api_endpoints").firstObject;
    if (!base.length) base = ZONConfigString(runtimeConfig, @[@"endpoint_url", @"endpointURL", @"endpoint", @"base_url", @"baseURL", @"api_endpoint"]);
    if (!base.length) base = [self apiBaseFromBootstrap:bootstrap];

    if ([verifyPath hasPrefix:@"http://"] || [verifyPath hasPrefix:@"https://"]) return verifyPath;
    return ZONJoinURL(base, verifyPath);
}

- (void)postVerifyBody:(NSDictionary *)body runtimeConfig:(NSDictionary *)runtimeConfig completion:(ZONAuthV2JSONCompletion)completion {
    [self fetchBootstrapWithCompletion:^(NSDictionary *bootstrap, NSError *bootstrapError) {
        if (bootstrapError || !bootstrap) {
            if (completion) completion(nil, bootstrapError);
            return;
        }

        NSString *urlString = [self verifyURLForRuntimeConfig:runtimeConfig ?: @{} bootstrap:bootstrap];
        NSURL *url = [NSURL URLWithString:urlString ?: @""];
        if (!url) {
            if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-16 userInfo:@{NSLocalizedDescriptionKey:@"Verify 地址无效"}]);
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
    }];
}

@end
