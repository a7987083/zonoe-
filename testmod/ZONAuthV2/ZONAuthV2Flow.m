#import "ZONAuthV2Flow.h"
#import "ZONAuthV2Storage.h"
#import "ZONAuthV2API.h"
#import "ZONAuthV2Verify.h"
#import "ZONPresentationCoordinator.h"
#import "../视图菜单/NSObject+UI.h"

static NSString *ZONNoticeFingerprint(NSDictionary *notice) {
    if (![notice isKindOfClass:NSDictionary.class] || !notice.count) return @"";
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:notice options:NSJSONWritingSortedKeys error:&error];
    if (data.length && !error) return [data base64EncodedStringWithOptions:0] ?: @"";
    return notice.description ?: @"";
}

static id ZONFirstValueForKeys(id obj, NSArray<NSString *> *keys) {
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = obj;
        for (NSString *key in keys) {
            id value = dict[key];
            if (value && value != NSNull.null) return value;
        }
        for (id value in dict.allValues) {
            id found = ZONFirstValueForKeys(value, keys);
            if (found) return found;
        }
    } else if ([obj isKindOfClass:NSArray.class]) {
        for (id value in (NSArray *)obj) {
            id found = ZONFirstValueForKeys(value, keys);
            if (found) return found;
        }
    }
    return nil;
}

static NSString *ZONString(id value) {
    if (!value || value == NSNull.null) return @"";
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return [value description] ?: @"";
}

static BOOL ZONLicenseIsAuthorized(NSDictionary *license) {
    if (![license isKindOfClass:NSDictionary.class] || !license.count) return NO;

    id auths = license[@"authorizations"];
    if ([auths isKindOfClass:NSArray.class] && [(NSArray *)auths count] > 0) {
        double now = NSDate.date.timeIntervalSince1970;
        for (id item in (NSArray *)auths) {
            if (![item isKindOfClass:NSDictionary.class]) continue;
            id expireObj = ZONFirstValueForKeys(item, @[@"expire", @"expires_at", @"expire_time"]);
            double expire = [ZONString(expireObj) doubleValue];
            if (expire <= 0 || expire > now) return YES;
        }
    }

    id status = ZONFirstValueForKeys(license, @[@"status", @"active", @"authorized", @"valid"]);
    id expireObj = ZONFirstValueForKeys(license, @[@"expire", @"expires_at", @"expire_time"]);
    double expire = [ZONString(expireObj) doubleValue];
    if ([status respondsToSelector:@selector(boolValue)] && [status boolValue] &&
        (expire <= 0 || expire > NSDate.date.timeIntervalSince1970)) {
        return YES;
    }
    return expire > NSDate.date.timeIntervalSince1970;
}

static id ZONLicenseProjection(id obj) {
    if ([obj isKindOfClass:NSArray.class]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id value in (NSArray *)obj) {
            [array addObject:ZONLicenseProjection(value) ?: NSNull.null];
        }
        return array.copy;
    }
    if (![obj isKindOfClass:NSDictionary.class]) return obj ?: NSNull.null;

    NSDictionary *dict = obj;
    NSArray<NSString *> *wanted = @[
        @"authorizations", @"expire", @"expires_at", @"expire_time",
        @"status", @"active", @"authorized", @"valid",
        @"scope", @"type", @"access_level", @"permissions"
    ];
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSString *key in wanted) {
        id value = dict[key];
        if (value && value != NSNull.null) out[key] = ZONLicenseProjection(value);
    }
    return out.copy;
}

static NSString *ZONLicenseFingerprint(NSDictionary *license) {
    id projection = ZONLicenseProjection(license ?: @{});
    if (![NSJSONSerialization isValidJSONObject:projection]) return [projection description] ?: @"";
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:projection options:NSJSONWritingSortedKeys error:&error];
    if (!data.length || error) return [projection description] ?: @"";
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

static NSString *ZONActivationMessage(NSDictionary *activation, NSDictionary *license, NSError *error, NSString *fallback) {
    NSString *message = @"";
    if ([activation[@"message"] isKindOfClass:NSString.class]) message = activation[@"message"];
    if (!message.length && [activation[@"msg"] isKindOfClass:NSString.class]) message = activation[@"msg"];
    if (!message.length && [license[@"message"] isKindOfClass:NSString.class]) message = license[@"message"];
    if (!message.length && [license[@"msg"] isKindOfClass:NSString.class]) message = license[@"msg"];
    if (!message.length) message = error.localizedDescription ?: fallback ?: @"授权状态未发生变化";
    return message;
}

static NSString *ZONUserMessage(NSString *code, NSString *raw) {
    NSString *lower = raw.lowercaseString ?: @"";
    if ([lower containsString:@"authorization does not apply to this app"]) {
        return @"当前卡密不适用于此应用，请更换有效卡密。";
    }
    if ([code isEqualToString:@"license_invalid"]) {
        if ([lower containsString:@"expired"] || [lower containsString:@"expire"]) return @"卡密已到期，请重新输入有效卡密。";
        return @"卡密无效、已失效或不适用于当前应用，请重新输入有效卡密。";
    }
    if ([code isEqualToString:@"license_expired"] || [code isEqualToString:@"authorization_expired"]) {
        return @"卡密已到期，请重新输入有效卡密。";
    }
    if (!raw.length) return @"授权验证失败，请稍后重试。";

    // Do not expose opaque English protocol/backend messages directly to end users.
    NSCharacterSet *letters = NSCharacterSet.letterCharacterSet;
    NSUInteger letterCount = 0, nonASCII = 0;
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ([letters characterIsMember:c]) letterCount++;
        if (c > 127) nonASCII++;
    }
    if (letterCount > 6 && nonASCII == 0) return @"授权状态异常，请检查卡密是否有效并重试。";
    return raw;
}

static BOOL ZONLicenseHTTPErrorInvalidatesSavedCard(NSError *error) {
    if (![error.domain isEqualToString:@"ZONAuthV2"]) return NO;
    NSInteger status = error.code;
    if (status < 400 || status >= 500) return NO;
    // Request timeout / Too Early / rate limiting are transient and must not destroy a valid saved card.
    return status != 408 && status != 425 && status != 429;
}

static NSString *ZONSavedCardTransientErrorMessage(NSError *error) {
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        return @"网络连接失败，请检查网络后重试。";
    }
    if ([error.domain isEqualToString:@"ZONAuthV2"] && error.code >= 500 && error.code < 600) {
        return @"授权服务器暂时不可用，请稍后重试。";
    }
    return ZONUserMessage(@"", error.localizedDescription ?: @"授权验证失败，请稍后重试。");
}

@implementation ZONAuthV2Flow

+ (instancetype)sharedFlow {
    static ZONAuthV2Flow *flow;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ flow = [ZONAuthV2Flow new]; });
    return flow;
}

- (void)startFromViewController:(UIViewController *)hostViewController udid:(NSString *)udid {
    if (udid.length < 5) return;
    [ZONAuthV2Storage setUDID:udid];

    NSString *savedCard = [ZONAuthV2Storage card];
    if (savedCard.length > 0) {
        [self verifySavedCard:savedCard udid:udid host:hostViewController];
        return;
    }
    [self presentCardPromptForUDID:udid host:hostViewController message:nil];
}

- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message {
    NSString *displayMessage = message.length ? message : @"请输入有效卡密";
    [[ZONPresentationCoordinator sharedCoordinator] enqueueWithKey:@"auth.cardPrompt" builder:^UIViewController *(dispatch_block_t finish) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"卡密激活"
                                                                       message:displayMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"请输入卡密";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
            finish();
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"激活" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSString *card = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            finish();
            if (card.length == 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf presentCardPromptForUDID:udid host:nil message:@"请输入卡密"];
                });
                return;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf activateCard:card udid:udid host:nil];
            });
        }]];
        return alert;
    }];
}

- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    ZONAuthV2API *api = [ZONAuthV2API sharedAPI];

    [api fetchLicenseForUDID:udid completion:^(NSDictionary *before, NSError *beforeError) {
        if (beforeError && !(beforeError.code > 0 && beforeError.code < 500)) {
            NSLog(@"[zonoemenu][auth-v2][BEFORE_LICENSE] failure domain=%@ code=%ld", beforeError.domain, (long)beforeError.code);
            [self presentCardPromptForUDID:udid host:nil message:ZONSavedCardTransientErrorMessage(beforeError)];
            return;
        }

        NSDictionary *beforeLicense = before ?: @{};
        BOOL beforeAuthorized = !beforeError && ZONLicenseIsAuthorized(beforeLicense);
        NSString *beforeFingerprint = beforeError ? @"" : ZONLicenseFingerprint(beforeLicense);
        NSLog(@"[zonoemenu][auth-v2][BEFORE_LICENSE] authorized=%d http_error=%ld", beforeAuthorized, (long)beforeError.code);

        [api activateUDID:udid card:card completion:^(NSDictionary *activation, NSError *activationError) {
            NSDictionary *activationResponse = activation ?: @{};
            if (activationError) {
                NSString *raw = ZONActivationMessage(activationResponse, nil, activationError, @"激活失败");
                NSLog(@"[zonoemenu][auth-v2][APPSTORE] rejected status=%ld raw_message=%@", (long)activationError.code, raw);
                [self presentCardPromptForUDID:udid host:nil message:ZONUserMessage(@"", raw)];
                return;
            }

            [ZONAuthV2Storage setLastActivation:activationResponse];
            NSLog(@"[zonoemenu][auth-v2][APPSTORE] transport_ok=1 message=%@", ZONActivationMessage(activationResponse, nil, nil, @""));

            [api fetchLicenseForUDID:udid completion:^(NSDictionary *after, NSError *afterError) {
                NSDictionary *afterLicense = after ?: @{};
                if (afterError || !after) {
                    NSString *raw = ZONActivationMessage(activationResponse, afterLicense, afterError, @"授权状态读取失败");
                    NSLog(@"[zonoemenu][auth-v2][AFTER_LICENSE] failure domain=%@ code=%ld raw_message=%@", afterError.domain, (long)afterError.code, raw);
                    [self presentCardPromptForUDID:udid host:nil message:ZONUserMessage(@"", raw)];
                    return;
                }

                BOOL afterAuthorized = ZONLicenseIsAuthorized(afterLicense);
                NSString *afterFingerprint = ZONLicenseFingerprint(afterLicense);
                BOOL stateChanged = !beforeAuthorized ? afterAuthorized : ![beforeFingerprint isEqualToString:afterFingerprint];
                NSLog(@"[zonoemenu][auth-v2][AFTER_LICENSE] authorized=%d state_changed=%d", afterAuthorized, stateChanged);

                if (!afterAuthorized || !stateChanged) {
                    NSString *raw = ZONActivationMessage(activationResponse, afterLicense, nil, @"授权状态未发生变化");
                    NSLog(@"[zonoemenu][auth-v2][ACTIVATION_GATE] rejected authorized=%d state_changed=%d raw_message=%@", afterAuthorized, stateChanged, raw);
                    [self presentCardPromptForUDID:udid host:nil message:ZONUserMessage(@"", raw)];
                    return;
                }

                NSLog(@"[zonoemenu][auth-v2][ACTIVATION_GATE] passed; entering runtime-config + verify");
                [self fetchConfigAndVerifyUDID:udid card:card license:afterLicense host:nil isNewActivation:YES];
            }];
        }];
    }];
}

- (void)verifySavedCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:udid completion:^(NSDictionary *license, NSError *error) {
        NSDictionary *licenseResponse = license ?: @{};
        if (error) {
            NSString *raw = ZONActivationMessage(nil, licenseResponse, error, @"授权验证失败");
            if (ZONLicenseHTTPErrorInvalidatesSavedCard(error)) {
                NSLog(@"[zonoemenu][auth-v2] saved-card /apiface rejected status=%ld raw_message=%@; clearing card only", (long)error.code, raw);
                [ZONAuthV2Storage clearCard];
                [self presentCardPromptForUDID:udid host:nil message:ZONUserMessage(@"license_invalid", raw)];
                return;
            }

            NSLog(@"[zonoemenu][auth-v2] saved-card /apiface transient failure domain=%@ code=%ld; preserving card", error.domain, (long)error.code);
            [self showMessage:ZONSavedCardTransientErrorMessage(error) title:@"验证失败" completion:nil];
            return;
        }

        if (!ZONLicenseIsAuthorized(licenseResponse)) {
            NSString *raw = ZONActivationMessage(nil, licenseResponse, nil, @"授权状态无效");
            NSLog(@"[zonoemenu][auth-v2] saved-card /apiface returned HTTP success but license is not authorized; clearing card only raw_message=%@", raw);
            [ZONAuthV2Storage clearCard];
            [self presentCardPromptForUDID:udid host:nil message:ZONUserMessage(@"license_invalid", raw)];
            return;
        }

        NSLog(@"[zonoemenu][auth-v2] saved-card license authorized; entering runtime-config + verify");
        [self fetchConfigAndVerifyUDID:udid card:card license:licenseResponse host:nil isNewActivation:NO];
    }];
}

- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                            card:(NSString *)card
                         license:(NSDictionary *)license
                            host:(UIViewController *)host
                 isNewActivation:(BOOL)isNewActivation {
    [[ZONAuthV2API sharedAPI] fetchRuntimeConfigWithCompletion:^(NSDictionary *config, NSError *configError) {
        NSDictionary *effectiveConfig = config;
        if (config && !configError) {
            [ZONAuthV2Storage setLastRuntimeConfig:config];
        } else {
            effectiveConfig = [ZONAuthV2Storage lastRuntimeConfig];
        }
        if (!effectiveConfig) {
            [self handleVerifyFailureResponse:config error:configError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-30 userInfo:@{NSLocalizedDescriptionKey:@"Runtime Config 不可用"}] udid:udid];
            return;
        }

        NSLog(@"[zonoemenu][auth-v2][VERIFY_CONFIG] ready dylib_key=%@", ZONString(ZONFirstValueForKeys(effectiveConfig, @[@"dylib_key"])));
        [[ZONAuthV2Verify sharedVerifier] verifyUDID:udid runtimeConfig:effectiveConfig completion:^(NSDictionary *response, NSError *verifyError) {
            if (verifyError && !response) {
                [self handleVerifyFailureResponse:nil error:verifyError udid:udid];
                return;
            }

            BOOL ok = [response[@"ok"] respondsToSelector:@selector(boolValue)] && [response[@"ok"] boolValue];
            NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";
            NSLog(@"[zonoemenu][auth-v2][VERIFY] ok=%d code=%@ action=%@", ok, ZONString(response[@"code"]), action);

            if (ok && ![action isEqualToString:@"block"]) {
                [ZONAuthV2Storage setLastVerify:response];
                [ZONAuthV2Storage setCard:card];
                [self handleVerifySuccess:response license:license ?: @{} isNewActivation:isNewActivation];
                return;
            }

            [self handleVerifyFailureResponse:response error:verifyError udid:udid];
        }];
    }];
}

- (void)handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid {
    NSString *code = [response[@"code"] isKindOfClass:NSString.class] ? response[@"code"] : @"";
    NSString *raw = [response[@"message"] isKindOfClass:NSString.class] ? response[@"message"] : (error.localizedDescription ?: @"验证失败");
    NSString *message = ZONUserMessage(code, raw);
    NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";
    NSLog(@"[zonoemenu][auth-v2] verify failure code=%@ action=%@ raw_message=%@", code, action, raw);

    if ([code isEqualToString:@"license_invalid"] || [code isEqualToString:@"license_expired"] || [code isEqualToString:@"authorization_expired"]) {
        [ZONAuthV2Storage clearCard];
        [self presentCardPromptForUDID:udid host:nil message:message];
        return;
    }

    if ([action isEqualToString:@"block"] || [action isEqualToString:@"disable_feature"] || [action isEqualToString:@"show_message"] || message.length) {
        [self showMessage:message title:@"验证提示" completion:nil];
    }
}

- (void)handleVerifySuccess:(NSDictionary *)response license:(NSDictionary *)license isNewActivation:(BOOL)isNewActivation {
    void (^continueFlow)(void) = ^{
        [self presentNoticeIfNeeded:response completion:^{
            [self presentUpdateIfNeeded:response completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject 显示图标];
                });
            }];
        }];
    };

    if (!isNewActivation) {
        continueFlow();
        return;
    }

    NSString *level = [response[@"access_level"] isKindOfClass:NSString.class] ? response[@"access_level"] : @"";
    id expireValue = ZONFirstValueForKeys(license, @[@"expire", @"expires_at", @"expire_time"]);
    if (!expireValue) expireValue = ZONFirstValueForKeys(response, @[@"expire", @"expires_at", @"expire_time"]);
    NSString *expire = [self formattedExpire:expireValue];
    NSString *message = [NSString stringWithFormat:@"当前等级：%@\n到期时间：%@", level.length ? level : @"-", expire.length ? expire : @"-"];
    [self showMessage:message title:@"激活成功" completion:continueFlow];
}

- (NSString *)formattedExpire:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        NSString *s = value;
        double ts = s.doubleValue;
        if (ts <= 0) return s;
        value = @(ts);
    }
    if ([value isKindOfClass:NSNumber.class]) {
        NSTimeInterval ts = [(NSNumber *)value doubleValue];
        if (ts <= 0) return @"";
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]] ?: @"";
    }
    return @"";
}

- (void)presentNoticeIfNeeded:(NSDictionary *)response completion:(dispatch_block_t)completion {
    NSDictionary *notice = [response[@"notice"] isKindOfClass:NSDictionary.class] ? response[@"notice"] : nil;
    if (!notice) { if (completion) completion(); return; }

    NSString *fingerprint = ZONNoticeFingerprint(notice);
    NSString *lastFingerprint = [ZONAuthV2Storage lastNoticeFingerprint];
    if (fingerprint.length && [fingerprint isEqualToString:lastFingerprint]) {
        if (completion) completion();
        return;
    }

    NSString *title = [notice[@"title"] isKindOfClass:NSString.class] ? notice[@"title"] : @"公告";
    NSString *message = nil;
    for (NSString *key in @[@"message", @"content", @"text"]) {
        if ([notice[key] isKindOfClass:NSString.class] && [notice[key] length]) { message = notice[key]; break; }
    }
    NSArray *buttons = [notice[@"buttons"] isKindOfClass:NSArray.class] ? notice[@"buttons"] : @[];
    NSString *queueKey = fingerprint.length ? [@"notice." stringByAppendingString:fingerprint] : @"notice.current";

    [[ZONPresentationCoordinator sharedCoordinator] enqueueWithKey:queueKey builder:^UIViewController *(dispatch_block_t finish) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        NSUInteger validButtonCount = 0;
        for (id object in buttons) {
            if (![object isKindOfClass:NSDictionary.class]) continue;
            validButtonCount++;
            NSDictionary *button = object;
            NSString *buttonTitle = [button[@"title"] isKindOfClass:NSString.class] && [button[@"title"] length] ? button[@"title"] : @"确定";
            [alert addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                NSString *action = [button[@"action"] isKindOfClass:NSString.class] ? button[@"action"] : @"";
                NSString *url = [button[@"url"] isKindOfClass:NSString.class] ? button[@"url"] : @"";
                if ([action isEqualToString:@"open_url"] && url.length) {
                    NSURL *target = [NSURL URLWithString:url];
                    if (target) [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:nil];
                }
                finish();
                if (completion) completion();
            }]];
        }
        if (validButtonCount == 0) {
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                finish();
                if (completion) completion();
            }]];
        }
        if (fingerprint.length) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (alert.presentingViewController) [ZONAuthV2Storage setLastNoticeFingerprint:fingerprint];
            });
        }
        return alert;
    }];
}

- (void)presentUpdateIfNeeded:(NSDictionary *)response completion:(dispatch_block_t)completion {
    NSDictionary *update = [response[@"app_update"] isKindOfClass:NSDictionary.class] ? response[@"app_update"] : nil;
    if (!update) { if (completion) completion(); return; }
    BOOL available = [update[@"available"] respondsToSelector:@selector(boolValue)] && [update[@"available"] boolValue];
    BOOL enabled = !update[@"enabled"] || ![update[@"enabled"] respondsToSelector:@selector(boolValue)] || [update[@"enabled"] boolValue];
    BOOL show = !update[@"show"] || ![update[@"show"] respondsToSelector:@selector(boolValue)] || [update[@"show"] boolValue];
    if (!available || !enabled || !show) { if (completion) completion(); return; }

    NSString *title = [update[@"title"] isKindOfClass:NSString.class] ? update[@"title"] : @"发现更新";
    NSString *message = nil;
    for (NSString *key in @[@"message", @"content", @"text"]) {
        if ([update[key] isKindOfClass:NSString.class] && [update[key] length]) { message = update[key]; break; }
    }
    NSString *url = [update[@"url"] isKindOfClass:NSString.class] ? update[@"url"] : @"";
    BOOL force = [update[@"force"] respondsToSelector:@selector(boolValue)] && [update[@"force"] boolValue];

    [[ZONPresentationCoordinator sharedCoordinator] enqueueWithKey:@"auth.appUpdate" builder:^UIViewController *(dispatch_block_t finish) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message ?: @"" preferredStyle:UIAlertControllerStyleAlert];
        if (url.length) {
            [alert addAction:[UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                NSURL *target = [NSURL URLWithString:url];
                if (target) [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:nil];
                if (!force) {
                    finish();
                    if (completion) completion();
                }
            }]];
        }
        if (!force) {
            [alert addAction:[UIAlertAction actionWithTitle:@"稍后" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) {
                finish();
                if (completion) completion();
            }]];
        }
        return alert;
    }];
}

- (void)showMessage:(NSString *)message title:(NSString *)title completion:(dispatch_block_t)completion {
    NSString *key = [NSString stringWithFormat:@"auth.message.%lu", (unsigned long)[[NSString stringWithFormat:@"%@|%@", title ?: @"", message ?: @""] hash]];
    [[ZONPresentationCoordinator sharedCoordinator] enqueueWithKey:key builder:^UIViewController *(dispatch_block_t finish) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            finish();
            if (completion) completion();
        }]];
        return alert;
    }];
}

@end
