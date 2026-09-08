
//static __attribute__((constructor)) void _logosLocalInit(void) {
//    NSLog(@"load1111111111");
//    [[WX_NongShiFu123 alloc] BSPHP];
//    WX_NongShiFu123 *alert = [WX_NongShiFu123 alertControllerWithTitle:nil message:软件公告 preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        if (completion) {
//            completion();
//        }
//    }];
//    [alert addAction:cancelAction];
//    UIViewController * rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
//    [rootViewController presentViewController:alert animated:YES completion:nil];
//}
#import "WX_NongShiFu123.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "daochucd.h"

#import <UIKit/UIKit.h>
#import "JDStatusBarNotification.h"
#import "NSObject+UI.h"
#import <dlfcn.h>
 
@implementation NSObject (mian)

#pragma mark - 强制加载 AppLovin SDK（如果存在）

 
// 核心通用加载逻辑
+ (void)loadDynamicFrameworkNamed:(NSString *)frameworkName {
    NSString *frameworkPath = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 1. 优先尝试 PrivateFrameworks 路径
    NSString *privatePath = [[NSBundle mainBundle] privateFrameworksPath];
    if (privatePath) {
        frameworkPath = [privatePath stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@.framework/%@", frameworkName, frameworkName]];
    }

    // 2. 兜底尝试标准 Frameworks 路径
    if (!frameworkPath || ![fileManager fileExistsAtPath:frameworkPath]) {
        frameworkPath = [[[NSBundle mainBundle] bundlePath]
                         stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"Frameworks/%@.framework/%@", frameworkName, frameworkName]];
    }

    // 3. 最终检查文件是否存在
    if (![fileManager fileExistsAtPath:frameworkPath]) {
        NSLog(@"[%@] SDK not found at path: %@", frameworkName, frameworkPath);
        return;
    }

    // 4. 执行 dlopen
    void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"[%@] dlopen failed: %s", frameworkName, dlerror());
        return;
    }

    // 5. 执行后续初始化逻辑
    // 注意：请确保 [NSObject sdkload] 内部有重入保护，防止多次调用崩溃
    if ([NSObject respondsToSelector:@selector(sdkload)]) {
        [NSObject sdkload];
    }
    
    NSLog(@"[%@] SDK loaded successfully from: %@", frameworkName, frameworkPath);
}

// --- 对外暴露的接口 ---

+ (void)tryLoadAppLovinSDK {
    [self loadDynamicFrameworkNamed:@"AppLovinSDK"];
}

+ (void)UnityFramework {
    [self loadDynamicFrameworkNamed:@"UnityFramework"];
}
+(void)load
{
    // ① 尝试加载 AppLovin SDK（最早时机）
       [self tryLoadAppLovinSDK];
    [self UnityFramework];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{

//        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
//        [presenter presentWithText:@"🎉加载插件中...." dismissAfterDelay:0 includedStyle:JDStatusBarNotificationIncludedStyleLight];
//         [NSObject previewFile];
        

//                [[daochucd alloc] backupasd];

//        [[WX_NongShiFu123 alloc] loada];
//        [self showProgressNotificationAndAnimate];
                [NSObject 显示图标];
         

 
     });


}



- (void)showProgressNotificationAndAnimate {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
 
                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                 [presenter presentWithText:@"🎉加载插件中...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];

        });
}

- (void)sdkload{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
//        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
//
//            [presenter addStyleNamed:@"downloadProgressStyle" prepare:^JDStatusBarNotificationStyle * _Nonnull(JDStatusBarNotificationStyle * _Nonnull style) {
//                style.textStyle.font = [UIFont systemFontOfSize:13.0]; //
//                style.textStyle.textColor = [UIColor whiteColor]; //
//                style.backgroundStyle.backgroundColor = [UIColor darkGrayColor]; //
//                style.progressBarStyle.barColor = [UIColor greenColor]; //
//                style.progressBarStyle.position = JDStatusBarNotificationProgressBarPositionTop; //
//                style.progressBarStyle.barHeight = 3.0; //
//                style.canSwipeToDismiss = NO; // 禁止滑动关闭
//                style.canTapToHold = NO; // 禁止点击保持
//                style.animationType = JDStatusBarNotificationAnimationTypeMove;
////                style.hidesStatusBar = NO;
//                return style;
//            }];
//                [presenter presentWithText:@"加载插件中..." customStyle:@"downloadProgressStyle" completion:^(JDStatusBarNotificationPresenter * _Nonnull presenter) {
//                    NSLog(@"下载通知已显示");
//                }];
//
     
                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                 [presenter presentWithText:@"🎉检测完成...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];

        });
}



@end

