#import "ZONAuthV2BindingProbe.h"
#import "ZONAuthV2Flow.h"
#import "ZONAuthV2Storage.h"
#import "ZONAuthV2API.h"
#import <objc/runtime.h>

#ifndef ZON_AUTH_BOOTSTRAP_URL
#define ZON_AUTH_BOOTSTRAP_URL "https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json"
#endif

static id ZONBindingFindValue(id obj, NSArray<NSString *> *keys) {
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = obj;
        for (NSString *key in keys) {
            id value = dict[key];
            if (value && value != NSNull.null) return value;
        }
        for (id value in dict.allValues) {
            id found = ZONBindingFindValue(value, keys);
            if (found) return found;
        }
    } else if ([obj isKindOfClass:NSArray.class]) {
        for (id value in (NSArray *)obj) {
            id found = ZONBindingFindValue(value, keys);
            if (found) return found;
        }
    }
    return nil;
}

static NSString *ZONBindingString(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return @"";
}

static ZONAuthV2BindingState ZONBindingStateFromJSON(NSDictionary *json) {
    if (![json isKindOfClass:NSDictionary.class] || !json.count) return ZONAuthV2BindingStateUnknown;

    id ok = json[@"ok"];
    id active = json[@"active"];
    if ([ok respondsToSelector:@selector(boolValue)] && [ok boolValue]) {
        if ([active respondsToSelector:@selector(boolValue)]) {
            return [active boolValue] ? ZONAuthV2BindingStateBound : ZONAuthV2BindingStateNotBound;
        }
    }

    id explicit = ZONBindingFindValue(json, @[@"same_udid", @"same_device", @"already_bound_to_this_udid",
                                               @"bound", @"is_bound", @"activated", @"is_activated"]);
    if ([explicit respondsToSelector:@selector(boolValue)]) {
        return [explicit boolValue] ? ZONAuthV2BindingStateBound : ZONAuthV2BindingStateNotBound;
    }

    NSString *code = ZONBindingString(ZONBindingFindValue(json, @[@"code", @"status"])).lowercaseString;
    if ([code isEqualToString:@"already_bound"] || [code isEqualToString:@"bound"] ||
        [code isEqualToString:@"activated"] || [code isEqualToString:@"same_udid"] ||
        [code isEqualToString:@"same_device"]) {
        return ZONAuthV2BindingStateBound;
    }
    if ([code isEqualToString:@"not_bound"] || [code isEqualToString:@"unbound"] ||
        [code isEqualToString:@"not_activated"] || [code isEqualToString:@"need_activation"]) {
        return ZONAuthV2BindingStateNotBound;
    }

    NSString *action = ZONBindingString(ZONBindingFindValue(json, @[@"action"])).lowercaseString;
    if ([action containsString:@"activate"] || [action containsString:@"bind"]) {
        return ZONAuthV2BindingStateNotBound;
    }
    return ZONAuthV2BindingStateUnknown;
}

static NSString *ZONFormEscape(NSString *value) {
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

static BOOL ZONLicenseHTMLShowsActiveBinding(NSString *html) {
    if (!html.length) return NO;
    BOOL successClass = [html containsString:@"class=\"msg ok\""] ||
                        [html containsString:@"class='msg ok'"] ||
                        [html containsString:@"class=\"ok msg\""] ||
                        [html containsString:@"class='ok msg'"];
    BOOL activeMessage = [html containsString:@"授权有效"];
    return successClass && activeMessage;
}

@implementation ZONAuthV2BindingProbe

+ (void)queryCard:(NSString *)card
             udid:(NSString *)udid
       completion:(ZONAuthV2BindingProbeCompletion)completion {
    NSURL *bootstrapURL = [NSURL URLWithString:@ZON_AUTH_BOOTSTRAP_URL];
    if (!bootstrapURL) {
        if (completion) completion(ZONAuthV2BindingStateUnknown, nil,
                                   [NSError errorWithDomain:@"ZONAuthV2BindingProbe" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 地址无效"}]);
        return;
    }

    NSMutableURLRequest *bootstrapRequest = [NSMutableURLRequest requestWithURL:bootstrapURL
                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                timeoutInterval:10.0];
    bootstrapRequest.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:bootstrapRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(ZONAuthV2BindingStateUnknown, nil, error);
            return;
        }
        id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *root = [object isKindOfClass:NSDictionary.class] ? object : nil;
        NSDictionary *config = [root[@"config"] isKindOfClass:NSDictionary.class] ? root[@"config"] : root;
        NSArray *endpoints = [config[@"api_endpoints"] isKindOfClass:NSArray.class] ? config[@"api_endpoints"] : nil;
        NSString *base = ([endpoints.firstObject isKindOfClass:NSString.class] ? endpoints.firstObject : @"");
        if (!base.length) {
            if (completion) completion(ZONAuthV2BindingStateUnknown, nil,
                                       [NSError errorWithDomain:@"ZONAuthV2BindingProbe" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"Bootstrap 未返回业务 API 地址"}]);
            return;
        }
        if ([base hasSuffix:@"/"]) base = [base substringToIndex:base.length - 1];

        NSURL *url = [NSURL URLWithString:[base stringByAppendingString:@"/index/index/license"]];
        if (!url) {
            if (completion) completion(ZONAuthV2BindingStateUnknown, nil,
                                       [NSError errorWithDomain:@"ZONAuthV2BindingProbe" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"License 查询地址无效"}]);
            return;
        }

        NSString *form = [NSString stringWithFormat:@"code=%@&udid=%@", ZONFormEscape(card ?: @""), ZONFormEscape(udid ?: @"")];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:10.0];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"text/html, application/json;q=0.9, */*;q=0.8" forHTTPHeaderField:@"Accept"];
        request.HTTPBody = [form dataUsingEncoding:NSUTF8StringEncoding];

        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *licenseResponse, NSError *licenseError) {
            if (licenseError) {
                if (completion) completion(ZONAuthV2BindingStateUnknown, nil, licenseError);
                return;
            }

            NSHTTPURLResponse *http = (NSHTTPURLResponse *)licenseResponse;
            NSError *statusError = nil;
            if (http.statusCode < 200 || http.statusCode >= 300) {
                statusError = [NSError errorWithDomain:@"ZONAuthV2BindingProbe"
                                                  code:http.statusCode
                                              userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"License HTTP %ld", (long)http.statusCode]}];
            }

            id parsed = body.length ? [NSJSONSerialization JSONObjectWithData:body options:0 error:nil] : nil;
            if ([parsed isKindOfClass:NSDictionary.class]) {
                NSDictionary *json = (NSDictionary *)parsed;
                ZONAuthV2BindingState state = ZONBindingStateFromJSON(json);
                if (completion) completion(state, json, statusError);
                return;
            }

            NSString *html = body.length ? [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] : @"";
            ZONAuthV2BindingState state = ZONLicenseHTMLShowsActiveBinding(html)
                ? ZONAuthV2BindingStateBound
                : ZONAuthV2BindingStateNotBound;
            NSDictionary *summary = @{
                @"source": @"authorization_license_html",
                @"ok": @(state == ZONAuthV2BindingStateBound),
                @"active": @(state == ZONAuthV2BindingStateBound),
            };
            if (completion) completion(statusError ? ZONAuthV2BindingStateUnknown : state, summary, statusError);
        }] resume];
    }] resume];
}

@end

#pragma mark - P79.10 server-authoritative access model

static id ZONP7910FirstValue(id obj, NSArray<NSString *> *keys) {
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = obj;
        for (NSString *key in keys) {
            id value = dict[key];
            if (value && value != NSNull.null) return value;
        }
        for (id value in dict.allValues) {
            id found = ZONP7910FirstValue(value, keys);
            if (found) return found;
        }
    } else if ([obj isKindOfClass:NSArray.class]) {
        for (id value in (NSArray *)obj) {
            id found = ZONP7910FirstValue(value, keys);
            if (found) return found;
        }
    }
    return nil;
}

static NSString *ZONP7910String(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return @"";
}

static NSString *ZONP7910AccessLevel(NSDictionary *license) {
    if (![license isKindOfClass:NSDictionary.class]) return @"";
    NSString *level = ZONP7910String(license[@"access_level"]);
    if (!level.length) level = ZONP7910String(ZONP7910FirstValue(license, @[@"access_level"]));
    return level.lowercaseString ?: @"";
}

static BOOL ZONP7910AccessAllowed(NSString *level) {
    return [level isEqualToString:@"global_plus"] ||
           [level isEqualToString:@"app_plus"] ||
           [level isEqualToString:@"basic"];
}

static NSUInteger ZONP7910PermissionsCount(NSDictionary *license) {
    id permissions = license[@"permissions"];
    if (!permissions) permissions = ZONP7910FirstValue(license, @[@"permissions"]);
    if ([permissions isKindOfClass:NSArray.class]) return [(NSArray *)permissions count];
    if ([permissions isKindOfClass:NSDictionary.class]) return [(NSDictionary *)permissions count];
    if ([permissions isKindOfClass:NSString.class]) return [(NSString *)permissions length] ? 1 : 0;
    return 0;
}

static NSString *ZONP7910ResponseMessage(NSDictionary *response, NSString *fallback) {
    NSString *message = ZONP7910String(response[@"message"]);
    if (!message.length) message = ZONP7910String(response[@"msg"]);
    return message.length ? message : (fallback ?: @"授权状态无效");
}

static NSString *ZONP7910StartupErrorMessage(NSError *error) {
    if ([error.domain isEqualToString:NSURLErrorDomain]) return @"网络连接失败，请检查网络后重试。";
    if ([error.domain isEqualToString:@"ZONAuthV2"] && error.code >= 500 && error.code < 600) return @"授权服务器暂时不可用，请稍后重试。";
    return error.localizedDescription.length ? error.localizedDescription : @"授权查询失败，请稍后重试。";
}

@interface ZONAuthV2Flow (P7910Private)
- (void)startFromViewController:(UIViewController *)hostViewController udid:(NSString *)udid;
- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message;
- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                            card:(NSString *)card
                         license:(NSDictionary *)license
                            host:(UIViewController *)host
                 isNewActivation:(BOOL)isNewActivation;
- (void)handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid;
- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host;
- (void)showMessage:(NSString *)message title:(NSString *)title completion:(dispatch_block_t)completion;
@end

@implementation ZONAuthV2Flow (P7910Compatibility)

- (void)zon_p7910_startFromViewController:(UIViewController *)hostViewController udid:(NSString *)udid {
    if (udid.length < 5) return;
    [ZONAuthV2Storage setUDID:udid];

    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:udid completion:^(NSDictionary *license, NSError *error) {
        if (error) {
            NSLog(@"[zonoemenu][auth-v2][P79.10_UDID_GATE] lookup_failed domain=%@ code=%ld", error.domain, (long)error.code);
            [self showMessage:ZONP7910StartupErrorMessage(error) title:@"验证失败" completion:nil];
            return;
        }

        NSDictionary *snapshot = license ?: @{};
        NSString *level = ZONP7910AccessLevel(snapshot);
        BOOL authorized = ZONP7910AccessAllowed(level);
        NSLog(@"[zonoemenu][auth-v2][P79.10_UDID_GATE] access_level=%@ authorized=%d permissions_count=%lu",
              level.length ? level : @"missing", authorized, (unsigned long)ZONP7910PermissionsCount(snapshot));

        if (authorized) {
            NSString *savedCard = [ZONAuthV2Storage card] ?: @"";
            [self fetchConfigAndVerifyUDID:udid card:savedCard license:snapshot host:nil isNewActivation:NO];
            return;
        }

        NSLog(@"[zonoemenu][auth-v2][P79.10_UDID_GATE] no_server_authorization -> card prompt level=%@", level.length ? level : @"missing");
        [ZONAuthV2Storage clearCard];
        [self presentCardPromptForUDID:udid host:hostViewController message:nil];
    }];
}

- (void)zon_p7910_activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    ZONAuthV2API *api = [ZONAuthV2API sharedAPI];

    [api fetchLicenseForUDID:udid completion:^(NSDictionary *before, NSError *beforeError) {
        if (beforeError) {
            NSLog(@"[zonoemenu][auth-v2][P79.10_ACTIVATE] before lookup failed domain=%@ code=%ld", beforeError.domain, (long)beforeError.code);
            [self presentCardPromptForUDID:udid host:nil message:ZONP7910StartupErrorMessage(beforeError)];
            return;
        }

        NSDictionary *beforeSnapshot = before ?: @{};
        NSString *beforeLevel = ZONP7910AccessLevel(beforeSnapshot);
        if (ZONP7910AccessAllowed(beforeLevel)) {
            NSLog(@"[zonoemenu][auth-v2][P79.10_ACTIVATE] UDID already authorized level=%@; skip /appstore", beforeLevel);
            [self fetchConfigAndVerifyUDID:udid card:card license:beforeSnapshot host:nil isNewActivation:NO];
            return;
        }

        [api activateUDID:udid card:card completion:^(NSDictionary *activation, NSError *activationError) {
            NSDictionary *activationResponse = activation ?: @{};
            if (activationError) {
                NSLog(@"[zonoemenu][auth-v2][P79.10_ACTIVATE] /appstore rejected status=%ld", (long)activationError.code);
                [self presentCardPromptForUDID:udid host:nil message:ZONP7910ResponseMessage(activationResponse, activationError.localizedDescription ?: @"激活失败")];
                return;
            }

            [ZONAuthV2Storage setLastActivation:activationResponse];
            [api fetchLicenseForUDID:udid completion:^(NSDictionary *after, NSError *afterError) {
                if (afterError) {
                    NSLog(@"[zonoemenu][auth-v2][P79.10_ACTIVATE] after lookup failed domain=%@ code=%ld", afterError.domain, (long)afterError.code);
                    [self presentCardPromptForUDID:udid host:nil message:ZONP7910StartupErrorMessage(afterError)];
                    return;
                }

                NSDictionary *afterSnapshot = after ?: @{};
                NSString *afterLevel = ZONP7910AccessLevel(afterSnapshot);
                BOOL authorized = ZONP7910AccessAllowed(afterLevel);
                NSLog(@"[zonoemenu][auth-v2][P79.10_ACTIVATE] after access_level=%@ authorized=%d permissions_count=%lu",
                      afterLevel.length ? afterLevel : @"missing", authorized, (unsigned long)ZONP7910PermissionsCount(afterSnapshot));

                if (!authorized) {
                    [self presentCardPromptForUDID:udid host:nil message:ZONP7910ResponseMessage(afterSnapshot, @"未返回有效授权，请检查卡密后重试。")];
                    return;
                }

                [self fetchConfigAndVerifyUDID:udid card:card license:afterSnapshot host:nil isNewActivation:YES];
            }];
        }];
    }];
}

- (void)zon_p7910_handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid {
    NSString *code = [response[@"code"] isKindOfClass:NSString.class] ? response[@"code"] : @"";
    NSString *raw = [response[@"message"] isKindOfClass:NSString.class] ? response[@"message"] : (error.localizedDescription ?: @"");
    BOOL appMismatch = [code isEqualToString:@"app_not_authorized"] ||
                       [raw.lowercaseString containsString:@"authorization does not apply to this app"];
    if (appMismatch) {
        NSLog(@"[zonoemenu][auth-v2][P79.10_VERIFY] app_not_authorized -> clear card and return to card prompt");
        [ZONAuthV2Storage clearCard];
        [self presentCardPromptForUDID:udid host:nil message:@"当前卡密不适用于此应用，请更换有效卡密。"];
        return;
    }

    [self zon_p7910_handleVerifyFailureResponse:response error:error udid:udid];
}

@end

__attribute__((constructor))
static void ZONInstallP7910Compatibility(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"ZONAuthV2Flow");
        if (!cls) return;

        Method originalStart = class_getInstanceMethod(cls, @selector(startFromViewController:udid:));
        Method replacementStart = class_getInstanceMethod(cls, @selector(zon_p7910_startFromViewController:udid:));
        if (originalStart && replacementStart) method_exchangeImplementations(originalStart, replacementStart);

        Method originalActivate = class_getInstanceMethod(cls, @selector(activateCard:udid:host:));
        Method replacementActivate = class_getInstanceMethod(cls, @selector(zon_p7910_activateCard:udid:host:));
        if (originalActivate && replacementActivate) method_exchangeImplementations(originalActivate, replacementActivate);

        Method originalFailure = class_getInstanceMethod(cls, @selector(handleVerifyFailureResponse:error:udid:));
        Method replacementFailure = class_getInstanceMethod(cls, @selector(zon_p7910_handleVerifyFailureResponse:error:udid:));
        if (originalFailure && replacementFailure) method_exchangeImplementations(originalFailure, replacementFailure);
    });
}
