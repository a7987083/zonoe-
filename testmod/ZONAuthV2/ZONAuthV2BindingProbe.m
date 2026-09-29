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

        // P79.8: use the server's canonical AuthorizationLicense::query(code, udid)
        // surface instead of the retired /authorization compatibility page.
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

#pragma mark - P79.8 compatibility layer

static id ZONP797FirstValue(id obj, NSArray<NSString *> *keys) {
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = obj;
        for (NSString *key in keys) {
            id value = dict[key];
            if (value && value != NSNull.null) return value;
        }
        for (id value in dict.allValues) {
            id found = ZONP797FirstValue(value, keys);
            if (found) return found;
        }
    } else if ([obj isKindOfClass:NSArray.class]) {
        for (id value in (NSArray *)obj) {
            id found = ZONP797FirstValue(value, keys);
            if (found) return found;
        }
    }
    return nil;
}

static NSString *ZONP797String(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return @"";
}

static BOOL ZONP797LicenseAuthorized(NSDictionary *license) {
    if (![license isKindOfClass:NSDictionary.class] || !license.count) return NO;
    double now = NSDate.date.timeIntervalSince1970;
    id authorizations = license[@"authorizations"];
    if ([authorizations isKindOfClass:NSArray.class]) {
        for (id item in (NSArray *)authorizations) {
            if (![item isKindOfClass:NSDictionary.class]) continue;
            double expire = [ZONP797String(ZONP797FirstValue(item, @[@"expire", @"expires_at", @"expire_time"])) doubleValue];
            if (expire <= 0 || expire > now) return YES;
        }
    }
    id status = ZONP797FirstValue(license, @[@"status", @"active", @"authorized", @"valid"]);
    double expire = [ZONP797String(ZONP797FirstValue(license, @[@"expire", @"expires_at", @"expire_time"])) doubleValue];
    if ([status respondsToSelector:@selector(boolValue)] && [status boolValue] && (expire <= 0 || expire > now)) return YES;
    return expire > now;
}

@interface ZONAuthV2Flow (P797Private)
- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message;
- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                            card:(NSString *)card
                         license:(NSDictionary *)license
                            host:(UIViewController *)host
                 isNewActivation:(BOOL)isNewActivation;
- (void)handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid;
- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host;
@end

@implementation ZONAuthV2Flow (P797Compatibility)

- (void)zon_p797_activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:udid completion:^(NSDictionary *license, NSError *licenseError) {
        NSDictionary *snapshot = license ?: @{};
        if (licenseError || !ZONP797LicenseAuthorized(snapshot)) {
            [self zon_p797_activateCard:card udid:udid host:host];
            return;
        }

        [ZONAuthV2BindingProbe queryCard:card udid:udid completion:^(ZONAuthV2BindingState state, NSDictionary *response, NSError *probeError) {
            NSLog(@"[zonoemenu][auth-v2][P79.8_LICENSE_PROBE] state=%ld error=%ld", (long)state, (long)probeError.code);
            if (state == ZONAuthV2BindingStateBound) {
                NSLog(@"[zonoemenu][auth-v2][P79.8_BINDING_GATE] same card + same UDID + active license confirmed; entering Verify without re-activation");
                [self fetchConfigAndVerifyUDID:udid card:card license:snapshot host:nil isNewActivation:NO];
                return;
            }

            // New/unused/mismatched/expired cards keep the canonical P79.6 activation path.
            [self zon_p797_activateCard:card udid:udid host:host];
        }];
    }];
}

- (void)zon_p797_handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid {
    NSString *code = [response[@"code"] isKindOfClass:NSString.class] ? response[@"code"] : @"";
    NSString *raw = [response[@"message"] isKindOfClass:NSString.class] ? response[@"message"] : (error.localizedDescription ?: @"");
    BOOL appMismatch = [code isEqualToString:@"app_not_authorized"] ||
                       [raw.lowercaseString containsString:@"authorization does not apply to this app"];
    if (appMismatch) {
        NSLog(@"[zonoemenu][auth-v2][P79.8_VERIFY] app_not_authorized -> clear card and return to card prompt");
        [ZONAuthV2Storage clearCard];
        [self presentCardPromptForUDID:udid host:nil message:@"当前卡密不适用于此应用，请更换有效卡密。"];
        return;
    }

    [self zon_p797_handleVerifyFailureResponse:response error:error udid:udid];
}

@end

__attribute__((constructor))
static void ZONInstallP797Compatibility(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"ZONAuthV2Flow");
        if (!cls) return;

        Method originalActivate = class_getInstanceMethod(cls, @selector(activateCard:udid:host:));
        Method replacementActivate = class_getInstanceMethod(cls, @selector(zon_p797_activateCard:udid:host:));
        if (originalActivate && replacementActivate) method_exchangeImplementations(originalActivate, replacementActivate);

        Method originalFailure = class_getInstanceMethod(cls, @selector(handleVerifyFailureResponse:error:udid:));
        Method replacementFailure = class_getInstanceMethod(cls, @selector(zon_p797_handleVerifyFailureResponse:error:udid:));
        if (originalFailure && replacementFailure) method_exchangeImplementations(originalFailure, replacementFailure);
    });
}
