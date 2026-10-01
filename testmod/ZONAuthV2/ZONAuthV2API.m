#import "ZONAuthV2API.h"
#import "ZONAuthV2Storage.h"

#ifndef ZON_AUTH_BOOTSTRAP_URL
#define ZON_AUTH_BOOTSTRAP_URL "https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json"
#endif

static NSString *ZONAuthBootstrapURLString(void) { return @ZON_AUTH_BOOTSTRAP_URL; }

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
    NSString *normalizedBase = [base hasSuffix:@"/"] ? [base substringToIndex:base.length - 1] : base;
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
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
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
    if (!ZONConfigStringArray(config, @"api_endpoints").count) return NO;
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
            if (completion) completion(normalized, nil);
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
        NSString *urlString = ZONJoinURL([self apiBaseFromBootstrap:bootstrap], path);
        if (!urlString.length) {
            if (completion) completion(nil, [NSError errorWithDomain:@"ZONAuthV2" code:-14 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 未返回业务 API 地址"}]);
            return;
        }
        [self GETAbsoluteURL:urlString query:query completion:completion];
    }];
}

- (void)fetchLicenseForUDID:(NSString *)udid completion:(ZONAuthV2JSONCompletion)completion {
    [self GETBusinessPath:@"/index/index/apiface" query:@{@"udid": udid ?: @""} completion:^(NSDictionary *json, NSError *error) {
        if (!error && [json isKindOfClass:NSDictionary.class]) {
            [ZONAuthV2Storage setLastLicense:json];
            NSString *authProof = [json[@"auth_proof"] isKindOfClass:NSString.class] ? json[@"auth_proof"] : @"";
            [ZONAuthV2Storage setAuthProof:(authProof.length ? authProof : nil)];
            NSLog(@"[zonoemenu][auth-v3][AUTH_PROOF] apiface proof=%@", authProof.length ? @"present" : @"absent");
        } else if (error) {
            [ZONAuthV2Storage setLastLicense:nil];
            [ZONAuthV2Storage setAuthProof:nil];
        }
        if (completion) completion(json, error);
    }];
}

- (void)activateUDID:(NSString *)udid card:(NSString *)card completion:(ZONAuthV2JSONCompletion)completion {
    [self GETBusinessPath:@"/appstore" query:@{@"udid": udid ?: @"", @"code": card ?: @""} completion:completion];
}

- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion {
    // Secretless v3 hard cutover: the bootstrap document itself is the signed
    // runtime config. Do not perform a second /index/dylib_verify/config fetch.
    [self fetchBootstrapWithCompletion:^(NSDictionary *bootstrap, NSError *bootstrapError) {
        if (bootstrapError || !bootstrap) {
            if (completion) completion(nil, bootstrapError);
            return;
        }
        NSLog(@"[zonoemenu][auth-v2][RUNTIME_CONFIG] using signed bootstrap directly version=%@ alg=%@ key_id=%@",
              bootstrap[@"config_version"] ?: @"",
              bootstrap[@"signature_alg"] ?: @"",
              bootstrap[@"key_id"] ?: @"");
        if (completion) completion(bootstrap, nil);
    }];
}

@end
