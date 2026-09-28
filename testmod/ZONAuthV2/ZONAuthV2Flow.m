#import "ZONAuthV2Flow.h"
#import "ZONAuthV2Storage.h"
#import "ZONAuthV2API.h"

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
        [host presentViewController:alert animated:YES completion:nil];
    });
}

- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    ZONAuthV2API *api = [ZONAuthV2API sharedAPI];
    [api fetchLicenseForUDID:udid completion:^(NSDictionary *before, NSError *beforeError) {
        if (beforeError) {
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
                    [self presentCardPromptForUDID:udid host:host message:afterError.localizedDescription ?: @"授权状态读取失败"];
                    return;
                }
                [api fetchRuntimeConfigWithCompletion:^(NSDictionary *runtimeConfig, NSError *configError) {
                    if (configError || !runtimeConfig) {
                        [self presentCardPromptForUDID:udid host:host message:configError.localizedDescription ?: @"Verify 配置读取失败"];
                        return;
                    }
                    /*
                     Phase 1 intentionally stops before POST /index/dylib_verify/verify until
                     the exact Protocol v2 canonical/HMAC implementation is imported from the
                     validated auth source. Do not infer success from activation response text/code.
                    */
                    NSString *message = @"Verify v2 协议实现尚未接入，未保存卡密";
                    [self presentCardPromptForUDID:udid host:host message:message];
                }];
            }];
        }];
    }];
}

- (void)verifySavedCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host {
    // Never treat locally cached card state as authorization. Until Verify v2 is connected,
    // return to the prompt without deleting the card on a network/implementation gap.
    [self presentCardPromptForUDID:udid host:host message:@"正在迁移到 Verify v2，当前不会使用旧 Bsphp 判断授权"];
}

@end
