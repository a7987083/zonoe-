#import "ZONAuthV2Flow.h"
#import "ZONAuthV2Storage.h"
#import "ZONAuthV2API.h"
#import "ZONAuthV2Verify.h"
#import "../视图菜单/NSObject+UI.h"

static NSString *ZONNoticeFingerprint(NSDictionary *notice) {
    if (![notice isKindOfClass:NSDictionary.class] || !notice.count) return @"";
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:notice options:NSJSONWritingSortedKeys error:&error];
    if (data.length && !error) return [data base64EncodedStringWithOptions:0] ?: @"";
    return notice.description ?: @"";
}

static UIViewController *ZONTopPresenter(UIViewController *host) {
    UIViewController *presenter = host;
    while (presenter.presentedViewController && !presenter.presentedViewController.isBeingDismissed) {
        presenter = presenter.presentedViewController;
    }
    return presenter;
}

@implementation ZONAuthV2Flow

+ (instancetype)sharedFlow {
    static ZONAuthV2Flow *flow;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ flow = [ZONAuthV2Flow new]; });
    return flow;
}

- (void)startFromViewController:(UIViewController *)hostViewController udid:(NSString *)udid {
    if (udid.length < 5 || !hostViewController) return;
    [ZONAuthV2Storage setUDID:udid];

    NSString *savedCard = [ZONAuthV2Storage card];
    if (savedCard.length > 0) {
        [self verifySavedCard:savedCard udid:udid host:hostViewController];
        return;
    }
    [self presentCardPromptForUDID:udid host:hostViewController message:nil];
}

- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ZONTopPresenter(host);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"卡密激活"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"请输入卡密";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"激活" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSString *card = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (card.length == 0) {
                [weakSelf presentCardPromptForUDID:udid host:host message:@"请输入卡密"];
                return;
            }
            [weakSelf activateCard:card udid:udid host:host];
        }]];
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    ZONAuthV2API *api = [ZONAuthV2API sharedAPI];

    [api fetchLicenseForUDID:udid completion:^(NSDictionary *before, NSError *beforeError) {
        if (beforeError && beforeError.code > 0 && beforeError.code < 500) {
            before = before ?: @{};
        } else if (beforeError) {
            [self presentCardPromptForUDID:udid host:host message:beforeError.localizedDescription ?: @"网络错误"];
            return;
        }

        [api activateUDID:udid card:card completion:^(NSDictionary *activation, NSError *activationError) {
            if (activationError) {
                [self presentCardPromptForUDID:udid host:host message:activationError.localizedDescription ?: @"激活失败"];
                return;
            }
            [ZONAuthV2Storage setLastActivation:activation];

            [api fetchLicenseForUDID:udid completion:^(NSDictionary *after, NSError *afterError) {
                if (afterError || !after) {
                    NSString *message = [after[@"message"] isKindOfClass:NSString.class] ? after[@"message"] : (afterError.localizedDescription ?: @"授权状态读取失败");
                    [self presentCardPromptForUDID:udid host:host message:message];
                    return;
                }
                [self fetchConfigAndVerifyUDID:udid card:card host:host isNewActivation:YES];
            }];
        }];
    }];
}

- (void)verifySavedCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    [[ZONAuthV2API sharedAPI] fetchLicenseForUDID:udid completion:^(NSDictionary *license, NSError *error) {
        if (error) {
            [self showMessage:error.localizedDescription ?: @"网络连接失败" title:@"验证失败" host:host completion:nil];
            return;
        }
        [self fetchConfigAndVerifyUDID:udid card:card host:host isNewActivation:NO];
    }];
}

- (void)fetchConfigAndVerifyUDID:(NSString *)udid card:(NSString *)card host:(UIViewController *)host isNewActivation:(BOOL)isNewActivation {
    [[ZONAuthV2API sharedAPI] fetchRuntimeConfigWithCompletion:^(NSDictionary *config, NSError *configError) {
        NSDictionary *effectiveConfig = config;
        if (config && !configError) {
            [ZONAuthV2Storage setLastRuntimeConfig:config];
        } else {
            effectiveConfig = [ZONAuthV2Storage lastRuntimeConfig];
        }
        if (!effectiveConfig) {
            [self handleVerifyFailureResponse:config error:configError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-30 userInfo:@{NSLocalizedDescriptionKey:@"Runtime Config 不可用"}] udid:udid host:host];
            return;
        }

        [[ZONAuthV2Verify sharedVerifier] verifyUDID:udid runtimeConfig:effectiveConfig completion:^(NSDictionary *response, NSError *verifyError) {
            if (verifyError && !response) {
                [self handleVerifyFailureResponse:nil error:verifyError udid:udid host:host];
                return;
            }

            BOOL ok = [response[@"ok"] respondsToSelector:@selector(boolValue)] && [response[@"ok"] boolValue];
            NSString *code = [response[@"code"] isKindOfClass:NSString.class] ? response[@"code"] : @"";
            NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";
            BOOL allowedCode = [@[@"ok", @"ok_testing", @"ok_deprecated"] containsObject:code];

            if (ok && allowedCode && ![action isEqualToString:@"block"]) {
                [ZONAuthV2Storage setLastVerify:response];
                [ZONAuthV2Storage setCard:card];
                [self handleVerifySuccess:response host:host isNewActivation:isNewActivation];
                return;
            }

            [self handleVerifyFailureResponse:response error:verifyError udid:udid host:host];
        }];
    }];
}

- (void)handleVerifyFailureResponse:(NSDictionary *)response error:(NSError *)error udid:(NSString *)udid host:(UIViewController *)host {
    NSString *code = [response[@"code"] isKindOfClass:NSString.class] ? response[@"code"] : @"";
    NSString *message = [response[@"message"] isKindOfClass:NSString.class] ? response[@"message"] : (error.localizedDescription ?: @"验证失败");
    NSString *action = [response[@"action"] isKindOfClass:NSString.class] ? response[@"action"] : @"";

    if ([code isEqualToString:@"license_invalid"]) {
        [ZONAuthV2Storage clearCard];
        [self presentCardPromptForUDID:udid host:host message:message];
        return;
    }

    if ([action isEqualToString:@"block"] || [action isEqualToString:@"disable_feature"] || [action isEqualToString:@"show_message"] || message.length) {
        [self showMessage:message title:@"验证提示" host:host completion:nil];
    }
}

- (void)handleVerifySuccess:(NSDictionary *)response host:(UIViewController *)host isNewActivation:(BOOL)isNewActivation {
    void (^continueFlow)(void) = ^{
        [self presentNoticeIfNeeded:response host:host completion:^{
            [self presentUpdateIfNeeded:response host:host completion:^{
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
    id expireValue = response[@"expire"];
    if (!expireValue) {
        NSDictionary *identity = [response[@"license"] isKindOfClass:NSDictionary.class] ? response[@"license"] : nil;
        expireValue = identity[@"expire"];
    }
    NSString *expire = [self formattedExpire:expireValue];
    NSMutableArray *lines = [NSMutableArray array];
    if (level.length) [lines addObject:[NSString stringWithFormat:@"当前等级：%@", level]];
    if (expire.length) [lines addObject:[NSString stringWithFormat:@"到期时间：%@", expire]];
    NSString *message = lines.count ? [lines componentsJoinedByString:@"\n"] : @"验证成功";
    [self showMessage:message title:@"激活成功" host:host completion:continueFlow];
}

- (NSString *)formattedExpire:(id)value {
    if ([value isKindOfClass:NSString.class]) return value;
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

- (void)presentNoticeIfNeeded:(NSDictionary *)response host:(UIViewController *)host completion:(dispatch_block_t)completion {
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

    dispatch_async(dispatch_get_main_queue(), ^{
        __block BOOL finished = NO;
        void (^finishOnce)(void) = ^{
            if (finished) return;
            finished = YES;
            if (completion) completion();
        };

        UIViewController *presenter = ZONTopPresenter(host);
        if (!presenter || !presenter.viewIfLoaded.window) {
            finishOnce();
            return;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        __block NSUInteger validButtonCount = 0;
        for (id object in buttons) {
            if (![object isKindOfClass:NSDictionary.class]) continue;
            NSDictionary *button = object;
            validButtonCount++;
            NSString *buttonTitle = [button[@"title"] isKindOfClass:NSString.class] && [button[@"title"] length] ? button[@"title"] : @"确定";
            [alert addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                NSString *action = [button[@"action"] isKindOfClass:NSString.class] ? button[@"action"] : @"";
                NSString *url = [button[@"url"] isKindOfClass:NSString.class] ? button[@"url"] : @"";
                if ([action isEqualToString:@"open_url"] && url.length) {
                    NSURL *target = [NSURL URLWithString:url];
                    if (target) [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:nil];
                }
                finishOnce();
            }]];
        }

        if (validButtonCount == 0) {
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                finishOnce();
            }]];
        }

        [presenter presentViewController:alert animated:YES completion:^{
            if (fingerprint.length) [ZONAuthV2Storage setLastNoticeFingerprint:fingerprint];
        }];

        // UIKit may refuse presentation during a transition. Notice UI must never
        // become an authorization gate or prevent the floating menu from appearing.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!alert.presentingViewController) finishOnce();
        });
    });
}

- (void)presentUpdateIfNeeded:(NSDictionary *)response host:(UIViewController *)host completion:(dispatch_block_t)completion {
    NSDictionary *update = [response[@"app_update"] isKindOfClass:NSDictionary.class] ? response[@"app_update"] : nil;
    if (!update) { if (completion) completion(); return; }
    BOOL available = [update[@"available"] respondsToSelector:@selector(boolValue)] && [update[@"available"] boolValue];
    BOOL enabled = !update[@"enabled"] || ![update[@"enabled"] respondsToSelector:@selector(boolValue)] || [update[@"enabled"] boolValue];
    BOOL show = !update[@"show"] || ![update[@"show"] respondsToSelector:@selector(boolValue)] || [update[@"show"] boolValue];
    if (!available || !enabled || !show) { if (completion) completion(); return; }

    NSString *title = [update[@"title"] isKindOfClass:NSString.class] ? update[@"title"] : @"发现更新";
    NSString *message = [update[@"message"] isKindOfClass:NSString.class] ? update[@"message"] : @"";
    NSString *url = [update[@"url"] isKindOfClass:NSString.class] ? update[@"url"] : @"";
    BOOL force = [update[@"force"] respondsToSelector:@selector(boolValue)] && [update[@"force"] boolValue];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ZONTopPresenter(host);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        if (url.length) {
            [alert addAction:[UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                NSURL *target = [NSURL URLWithString:url];
                if (target) [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:nil];
                if (!force && completion) completion();
            }]];
        }
        if (!force) [alert addAction:[UIAlertAction actionWithTitle:@"稍后" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) { if (completion) completion(); }]];
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showMessage:(NSString *)message title:(NSString *)title host:(UIViewController *)host completion:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ZONTopPresenter(host);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) { if (completion) completion(); }]];
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

@end
