#!/usr/bin/env python3
from pathlib import Path

p = Path('testmod/ZONCore/ZONFeatureDispatcher.m')
s = p.read_text(encoding='utf-8')

old = '''void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"清除游戏数据"
                                        message:@"此操作会清除本地游戏数据，且不可恢复。\\n确定要继续吗？"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:nil];

    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleDestructive
                           handler:^(__unused UIAlertAction *action) {
        [SVProgressHUD showWithStatus:@"处理中..."];
        ZONClearGameDataPreservingTmp();
    }];

    [alert addAction:cancel];
    [alert addAction:confirm];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"清除授权记录"
                                        message:@"此操作会删除授权信息，删除后需要重新授权。\\n确定继续吗？"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:nil];

    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleDestructive
                           handler:^(__unused UIAlertAction *action) {
        [[WX_NongShiFu123 alloc] deletekm];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];

    [alert addAction:cancel];
    [alert addAction:confirm];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

static void ZONPersistRuntimeToggle(NSUserDefaults *defaults,
                                    NSString *integerKey,
                                    NSString *booleanKey,
                                    BOOL on)
{
    [defaults setInteger:on forKey:integerKey];
    [defaults setBool:on forKey:booleanKey];
    [defaults synchronize];
}
'''

new = '''typedef void (^ZONDestructiveConfirmationHandler)(void);
typedef void (^ZONRuntimeToggleSideEffect)(BOOL on);

static void ZONPresentDestructiveConfirmation(UIViewController *hostViewController,
                                              NSString *title,
                                              NSString *message,
                                              ZONDestructiveConfirmationHandler handler)
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(__unused UIAlertAction *action) {
        if (handler) handler();
    }]];
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    ZONPresentDestructiveConfirmation(hostViewController,
                                      @"清除游戏数据",
                                      @"此操作会清除本地游戏数据，且不可恢复。\\n确定要继续吗？",
                                      ^{
        [SVProgressHUD showWithStatus:@"处理中..."];
        ZONClearGameDataPreservingTmp();
    });
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    ZONPresentDestructiveConfirmation(hostViewController,
                                      @"清除授权记录",
                                      @"此操作会删除授权信息，删除后需要重新授权。\\n确定继续吗？",
                                      ^{
        [[WX_NongShiFu123 alloc] deletekm];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    });
}

static void ZONApplyRuntimeToggle(NSUserDefaults *defaults,
                                  NSString *integerKey,
                                  NSString *booleanKey,
                                  BOOL on,
                                  ZONRuntimeToggleSideEffect sideEffect)
{
    [defaults setInteger:on forKey:integerKey];
    [defaults setBool:on forKey:booleanKey];
    [defaults synchronize];
    if (sideEffect) sideEffect(on);
}
'''

if old not in s:
    raise SystemExit('expected destructive/toggle helper block not found')
s = s.replace(old, new, 1)

old_toggle = '''            @"runtime.iap-noads": ^BOOL(BOOL on) {
                ZONPersistRuntimeToggle(NSUserDefaults.standardUserDefaults, @"NNGG", @"NNGGNNGG", on);
                [ImgTool share].NeiGou = on;
                return YES;
            },
            @"runtime.ad-speed": ^BOOL(BOOL on) {
                ZONPersistRuntimeToggle(NSUserDefaults.standardUserDefaults, @"AADD", @"AADDAADD", on);
                [ImgTool share].ADSpeed = on;
                return YES;
            },
'''
new_toggle = '''            @"runtime.iap-noads": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"NNGG", @"NNGGNNGG", on,
                                      ^(BOOL enabled) { [ImgTool share].NeiGou = enabled; });
                return YES;
            },
            @"runtime.ad-speed": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"AADD", @"AADDAADD", on,
                                      ^(BOOL enabled) { [ImgTool share].ADSpeed = enabled; });
                return YES;
            },
'''
if old_toggle not in s:
    raise SystemExit('expected toggle routes not found')
s = s.replace(old_toggle, new_toggle, 1)

p.write_text(s, encoding='utf-8')
print('P51E_DISPATCHER_REFACTOR=APPLIED')
