#import "ZONAuthV2BindingProbe.h"

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
        NSURL *url = [NSURL URLWithString:[base stringByAppendingString:@"/authorization"]];
        if (!url) {
            if (completion) completion(ZONAuthV2BindingStateUnknown, nil,
                                       [NSError errorWithDomain:@"ZONAuthV2BindingProbe" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"Authorization 地址无效"}]);
            return;
        }

        NSString *form = [NSString stringWithFormat:@"code=%@&udid=%@", ZONFormEscape(card ?: @""), ZONFormEscape(udid ?: @"")];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:10.0];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json, text/html;q=0.9, */*;q=0.8" forHTTPHeaderField:@"Accept"];
        request.HTTPBody = [form dataUsingEncoding:NSUTF8StringEncoding];

        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *authorizationResponse, NSError *authorizationError) {
            if (authorizationError) {
                if (completion) completion(ZONAuthV2BindingStateUnknown, nil, authorizationError);
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)authorizationResponse;
            id parsed = body.length ? [NSJSONSerialization JSONObjectWithData:body options:0 error:nil] : nil;
            NSDictionary *json = [parsed isKindOfClass:NSDictionary.class] ? parsed : nil;
            ZONAuthV2BindingState state = ZONBindingStateFromJSON(json ?: @{});
            NSError *statusError = nil;
            if (http.statusCode < 200 || http.statusCode >= 300) {
                NSString *message = [json[@"message"] isKindOfClass:NSString.class] ? json[@"message"] : [NSString stringWithFormat:@"Authorization HTTP %ld", (long)http.statusCode];
                statusError = [NSError errorWithDomain:@"ZONAuthV2BindingProbe" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey:message}];
            }
            if (completion) completion(state, json, statusError);
        }] resume];
    }] resume];
}

@end
