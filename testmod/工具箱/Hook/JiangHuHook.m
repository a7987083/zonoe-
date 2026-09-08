//聚缘阁 悬浮窗加载
//

#import "JiangHuHook.h"
#import "CaptainHook.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "tweak.h"
#import "ALApp.h"
#import "GAD.h"
#import "MTG.h"
#import "ImgTool.h"
#import "Config.h"
#import "albase.h"
#import "ALAdView.h"
#import <dlfcn.h>  // <--- 必须包含这个头文件
#import "csj.h"
#import "JDStatusBarNotification.h"
#import <objc/message.h>
@interface CSJRewardedVideoWebViewControllerVM : NSObject
- (void)sendRewardFromH5CallbackInPlayableAd:(id)arg1;
- (BOOL)isRealPlayablePage;
- (void)webCloseButtonTapped;

@end

static NSDictionary *json;
#define  BS_DSQQ 5

int TuBiao = 1;
int shuoming = 0;
static NSTimer*dsq;
//加载悬浮窗
//CHDeclareClass(UIViewController)
//CHOptimizedMethod(1, self, void, UIViewController,viewDidAppear,bool,arg1){
//    CHSuper(1, UIViewController,viewDidAppear,arg1);
//    int nngg = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NNGG"] intValue];
//    int aadd = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AADD"] intValue];
//    int adsp = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AADDssppeedd"] intValue];
//
//        if(nngg == 1){
//            [ImgTool share].NeiGou = 1;
//        }
//        if(aadd == 1){
//            [ImgTool share].ADSpeed = 1;
//        }
//    if([[NSUserDefaults standardUserDefaults] objectForKey:@"AADDssppeedd"]){
//        [ImgTool share].ADBiansu  = adsp;
//    }else{
//        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"AADDssppeedd"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
//}
//CHDeclareClass(UIViewController)
//
//CHOptimizedMethod(1, self, void, UIViewController, viewDidAppear, bool, animated) {
//    // ✅ 调用原始方法
//    CHSuper(1, UIViewController, viewDidAppear, animated);
//
//    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//
//    // 🔹 内购开关（使用 boolKey NNGGNNGG）
//    BOOL nnggOn = [ud boolForKey:@"NNGGNNGG"];
//    [ImgTool share].NeiGou = nnggOn;
//
//    // 🔹 广告开关
//    BOOL adOn = [ud boolForKey:@"AADDAADD"];
//    [ImgTool share].ADSpeed = adOn;
//
//    // 🔹 广告倍速（默认 1）
//    NSInteger adSpeed = [ud integerForKey:@"AADDssppeedd"];
//    if (adSpeed <= 0) adSpeed = 1;
//    [ImgTool share].ADBiansu = adSpeed;
//}
CHDeclareClass(PopupMenuVC)

CHOptimizedMethod(1, self, void, PopupMenuVC, viewDidAppear, bool, animated) {
    // 先调用原始方法
    CHSuper(1, PopupMenuVC, viewDidAppear, animated);

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSInteger nngg = [ud integerForKey:@"NNGG"];
    NSInteger aadd = [ud integerForKey:@"AADD"];
    NSInteger adsp = [ud integerForKey:@"AADDssppeedd"];

 
        if(nngg == 1){
            NSLog(@"NNGG == 1, enable NeiGou");
            [ImgTool share].NeiGou = 1;
            
        }

        if(aadd == 1){
            [ImgTool share].ADSpeed = 1;
        }

        if(adsp > 0){
            [ImgTool share].ADBiansu = adsp;
        } else {
            [ud setInteger:1 forKey:@"AADDssppeedd"];
            [ud synchronize];
        }
     
}

//内购破解
#pragma mark - SKPaymentTransaction
CHDeclareClass(SKPaymentTransaction)
CHOptimizedMethod(0, self, long long, SKPaymentTransaction,transactionState){
    if([ImgTool share].NeiGou == 1){
        
    return 1;
    }else{
    return CHSuper(0, SKPaymentTransaction,transactionState);
    }
}

//广告加速
CHDeclareClass(AVPlayer)
 
CHOptimizedMethod(1, self, float, AVPlayer,setRate,float,arg1){
    if([ImgTool share].ADSpeed == 1){
    arg1 =  [ImgTool share].ADBiansu;
    }
    return CHSuper(1, AVPlayer,setRate,arg1);
}
CHOptimizedMethod(1, self, float, AVPlayer,playImmediatelyAtRate,float,arg1){
    if([ImgTool share].ADSpeed == 1){
    arg1 =  [ImgTool share].ADBiansu;
    }
    return CHSuper(1, AVPlayer,playImmediatelyAtRate,arg1);
}

//
//CHDeclareClass(ALAppLovinVideoViewController)
//
//CHOptimizedMethod(0, self,void, ALAppLovinVideoViewController, showPostitial)
//{
//    
//    if([ImgTool share].ADSpeed == 1){
//        // --- 弹窗提醒成功 ---
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIAlertController *alert =
//            [UIAlertController alertControllerWithTitle:@"提示"
//                                                message:@"拦截成功"
//                                         preferredStyle:UIAlertControllerStyleAlert];
//
//            // 点击确定按钮后执行自动关闭广告
//            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定"
//                                                         style:UIAlertActionStyleDefault
//                                                       handler:^(UIAlertAction * _Nonnull action) {
//               
//            }];
//
//            [alert addAction:ok];
//
//            // 获取当前最顶层 VC（在 tweak 里必须这么写）
//            UIViewController *top =
//            [UIApplication sharedApplication].keyWindow.rootViewController;
//
//            while (top.presentedViewController) {
//                top = top.presentedViewController;
//            }
//
//            [top presentViewController:alert animated:YES completion:nil];
//        });
//        // 自动关闭广告
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
//                       dispatch_get_main_queue(), ^{
//            [self handleCloseButton];
//        });
//        // 自动关闭广告
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
//                       dispatch_get_main_queue(), ^{
//            [self handleCloseButton];
//        });
//
//    }else{
//
//        // 调回原函数
//        CHSuper(0, ALAppLovinVideoViewController, showPostitial);    }
//
//}
CHDeclareClass(ALAppLovinVideoViewController)
CHOptimizedMethod(0, self, void,
                  ALAppLovinVideoViewController,
                  showPostitial)
{
    // 1. 先正常展示广告
    CHSuper(0, ALAppLovinVideoViewController, showPostitial);

    // 2. 开启加速才自动关闭
    if ([ImgTool share].ADSpeed == 1) {

        // （可选）只弹一次调试提示
        static BOOL shown = NO;
        if (!shown) {
            shown = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:@"提示"
                                                    message:@"广告已拦截"
                                             preferredStyle:UIAlertControllerStyleAlert];

                [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil]];

                UIViewController *top =
                [UIApplication sharedApplication].keyWindow.rootViewController;

                while (top.presentedViewController) {
                    top = top.presentedViewController;
                }

                [top presentViewController:alert animated:YES completion:nil];
            });
        }

        // 3. 延迟关闭一次即可
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            
            [self handleCloseButton];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{

                [self handleCloseButton];
            });
        });
    }
}



//CHDeclareClass(ALAppLovinVideoViewController)
//CHOptimizedMethod(0,self, void , ALAppLovinVideoViewController, showPostitial){
//   
//    if([ImgTool share].NeiGou == 1){
//        sleep(5);
//        [self handleCloseButton];
//    }else{
//            if([ImgTool share].ADSpeed == 1){
//                [self handleCloseButton];
//        
//            }else{
//                return CHSuper(0, ALAppLovinVideoViewController,showPostitial);
//            }
//    }
//}

//广告奖励
CHDeclareClass(ALBaseVideoViewController)
CHOptimizedMethod(0, self, bool, ALBaseVideoViewController,isFullyWatched){

    return 1;
}
CHOptimizedMethod(0, self, void,
                  ALBaseVideoViewController,
                  showPostitial)
{
    // ✅先正常展示广告
    CHSuper(0, ALBaseVideoViewController, showPostitial);

    // ✅开启加速 → 延迟自动关闭
    if ([ImgTool share].ADSpeed == 1) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{

            [self handleCloseButton];
        });
    }
}


//ig
CHDeclareClass(_TtC13WebAdProvider28InterstitialAdViewController)
CHOptimizedMethod(0, self, void, _TtC13WebAdProvider28InterstitialAdViewController,viewDidLoad){
    // 先执行原始 viewDidLoad，保证视图正常加载
      CHSuper(0, _TtC13WebAdProvider28InterstitialAdViewController, viewDidLoad);

      // 0.5 秒后自动关闭插屏广告
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{
          [self closeButtonPressed];
      });
}


CHDeclareClass(GDTAbm3l)
CHOptimizedMethod(0, self, bool, GDTAbm3l,isVideoAd){
    if([ImgTool share].ADSpeed == 1){
   return 1;
    }
    return CHSuper(0, GDTAbm3l,isVideoAd);
}
CHOptimizedMethod(0, self, bool, GDTAbm3l,isWechatCanvasAd){
    if([ImgTool share].ADSpeed == 1){
        return 0;
    }
    return CHSuper(0, GDTAbm3l,isWechatCanvasAd);

}
CHOptimizedMethod(0, self, bool, GDTAbm3l, forbidLookReward) {
    if ([ImgTool share].ADSpeed == 1) {
        return 0; // 不禁止发奖励
    }
    return CHSuper(0, GDTAbm3l, forbidLookReward);
}

CHOptimizedMethod(0, self, bool, GDTAbm3l, GDTfunctionp08Xu8) {
    if ([ImgTool share].ADSpeed == 1) {
        return 0; // not expired
    }
    return CHSuper(0, GDTAbm3l, GDTfunctionp08Xu8);
}
CHOptimizedMethod(0, self, bool, GDTAbm3l, GDTfunctionl5pG1W) {
    if ([ImgTool share].ADSpeed == 1) {
        return 1; // canPlay / isValid
    }
    return CHSuper(0, GDTAbm3l, GDTfunctionl5pG1W);
}

////广告自动关闭
//CHDeclareClass(PAGNativeExpressRewardedVideoAdViewController)
//CHOptimizedMethod(1, self, void, PAGNativeExpressRewardedVideoAdViewController,viewDidAppear,bool,arg1){
//    CHSuper(1, PAGNativeExpressRewardedVideoAdViewController,viewDidAppear,arg1);
//    [self webCloseButtonTapped];
//}

////gad广告自动关闭
//CHDeclareClass(GADFullScreenAdViewController)
//CHOptimizedMethod(1, self, void, GADFullScreenAdViewController,viewDidAppear,bool,arg1){
//    CHSuper(1, GADFullScreenAdViewController,viewDidAppear,arg1);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC),
//                   dispatch_get_main_queue(), ^{
//        [self handleCloseButtonPressed];
//    });
//}
 
CHDeclareClass(GDTRewardPageView)

CHOptimizedMethod(1, self, long long, GDTRewardPageView,countDownTime,long long ,arg1){
    if([ImgTool share].ADSpeed == 1){
        return 0;
    }else{
    return CHSuper(1, GDTRewardPageView,countDownTime,arg1);
    }
}

CHDeclareClass(ALAdView)
CHOptimizedMethod(1,self,void, ALAdView, loadAd, id, arg1) {
    if([ImgTool share].NeiGou == 1){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            [self closeAd];
        });
    }else{
    return CHSuper(1, ALAdView,loadAd,arg1);
    }
}

CHDeclareClass(CSJRewardedVideoWebViewControllerVM);
//
//CHOptimizedMethod1(self, void,
//                   CSJRewardedVideoWebViewControllerVM,
//                   webViewDidFinishLoad,
//                   id, webView)
//{
//    CHSuper1(CSJRewardedVideoWebViewControllerVM,
//             webViewDidFinishLoad,
//             webView);
//     if ([ImgTool share].ADSpeed == 1) {

//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
//                       (int64_t)(1.0 * NSEC_PER_SEC)),
//                       dispatch_get_main_queue(), ^{
//            [self sendRewardFromH5CallbackInPlayableAd:nil];
//           
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
//         
//                [self webCloseButtonTapped];
//                    
//
//                });
////            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
////                           (int64_t)(1.0 * NSEC_PER_SEC)),
////                           dispatch_get_main_queue(), ^{
////            
////                [self webCloseButtonTapped];
////
////            });
//        });
//    }
//       
// 
//}

CHOptimizedMethod1(self, void,
                   CSJRewardedVideoWebViewControllerVM,
                   webViewDidFinishLoad,
                   id, webView)
{
    CHSuper1(CSJRewardedVideoWebViewControllerVM,
             webViewDidFinishLoad,
             webView);

    if ([ImgTool share].ADSpeed == 1) {

        static BOOL alertShowing = NO;
        if (alertShowing) {
            return;
        }

        alertShowing = YES;

        dispatch_async(dispatch_get_main_queue(), ^{

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:@"检测到 webViewDidFinishLoad，点击 OK 后执行命令"
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {

                alertShowing = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(1.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [self webCloseButtonTapped];
                   
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
                 
 

                        });
  
                });
                // =========================
                // 这里写你点击 OK 后要执行的命令
                // =========================

                NSLog(@"[Tweak] 点击 OK，开始执行其他命令");

                // 示例 1：调用当前对象的方法
                /*
                id obj = (id)self;
                SEL sel = @selector(你的方法名);
                if ([obj respondsToSelector:sel]) {
                    [obj performSelector:sel];
                }
                */

                // 示例 2：修改你的开关
                /*
                [ImgTool share].ADSpeed = 0;
                */

                // 示例 3：延迟执行
                /*
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    NSLog(@"延迟 1 秒执行");
                });
                */
            }];

            [alert addAction:okAction];

            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;

            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }

            if (rootVC) {
                [rootVC presentViewController:alert animated:YES completion:nil];
            } else {
                alertShowing = NO;
            }
        });
    }
}
 
CHDeclareClass(GDTBizFeedVideoPlayerView);

CHOptimizedMethod0(self, CGFloat, GDTBizFeedVideoPlayerView, videoPlayTime)
{
    CGFloat value = CHSuper0(GDTBizFeedVideoPlayerView, videoPlayTime);

    if (value > 0) {
        SEL sel = @selector(GDTfunctionj38KkI);

        id obj = (id)self;

        if ([obj respondsToSelector:sel]) {
            [obj performSelector:sel];
        }
    }

    return value;
}

CHDeclareClass(GDTRewardPageView);

CHOptimizedMethod0(self, NSInteger, GDTRewardPageView, countDownTime)
{
    NSInteger value = CHSuper0(GDTRewardPageView, countDownTime);

    if (value > 1) {
        return 0;
    }

    return value;
}

CHDeclareClass(SKPaymentQueue)

// ✅ 正确写法：宏名字带数字，括号内直接写参数
CHOptimizedClassMethod0(self, BOOL, SKPaymentQueue, canMakePayments) {
    // 强制返回 YES，绕过越狱检测或家长控制导致的内购禁止
    return YES;
}


CHDeclareClass(BaiduMobAdAnimationView);

CHOptimizedMethod0(self, CGFloat, BaiduMobAdAnimationView, animationProgress)
{
    CGFloat value = CHSuper0(BaiduMobAdAnimationView, animationProgress);

    if (value > 0 && value < 1) {
        return 1.0;
    }

    return value;
}

CHOptimizedMethod1(self, void, BaiduMobAdAnimationView, setAnimationProgress, CGFloat, progress)
{
    if (progress > 0 && progress < 1) {
        progress = 1.0;
    }

    CHSuper1(BaiduMobAdAnimationView, setAnimationProgress, progress);
}

CHOptimizedMethod0(self, CGFloat, BaiduMobAdAnimationView, animationSpeed)
{
    return 99.0;
}

CHOptimizedMethod0(self, CGFloat, BaiduMobAdAnimationView, animationDuration)
{
    return 0.1;
}

CHDeclareClass(BaiduMobAdNativeProfessionalControlComponent);

CHOptimizedMethod0(self, CGFloat,
                   BaiduMobAdNativeProfessionalControlComponent,
                   videoCurrentTime)
{
    CGFloat value = CHSuper0(BaiduMobAdNativeProfessionalControlComponent,
                             videoCurrentTime);

    if (value > 0) {
        return 999.0;
    }

    return value;
}

 
CHConstructor {

    // 建议先手动加载框架，确保类能被找到
    dlopen("/System/Library/Frameworks/StoreKit.framework/StoreKit", RTLD_LAZY);
    
    CHLoadLateClass(SKPaymentQueue);
    
    // ✅ 正确写法：注册宏
    CHClassHook0(SKPaymentQueue, canMakePayments);
    
    CHLoadLateClass(CSJRewardedVideoWebViewControllerVM);
        CHHook1(CSJRewardedVideoWebViewControllerVM, webViewDidFinishLoad);
    
    
    
    
    CHLoadLateClass(PopupMenuVC);
    CHClassHook(1, PopupMenuVC, viewDidAppear);
//    CHLoadLateClass(UIViewController);
//    CHClassHook(1, UIViewController,viewDidAppear);
    CHLoadLateClass(SKPaymentTransaction);
    CHClassHook(0, SKPaymentTransaction, transactionState);
    CHLoadLateClass(AVPlayer);
    //CHClassHook(0, AVPlayer,status);
    CHClassHook(1, AVPlayer,setRate);
    CHClassHook(1, AVPlayer,playImmediatelyAtRate);
    

//    CHLoadLateClass(GADFullScreenAdViewController);
//    CHClassHook(1, GADFullScreenAdViewController,viewDidAppear);
    
    CHLoadLateClass(_TtC13WebAdProvider28InterstitialAdViewController);
    CHClassHook(0, _TtC13WebAdProvider28InterstitialAdViewController,viewDidLoad);
    
    CHLoadLateClass(ALAppLovinVideoViewController);
    CHHook(0,ALAppLovinVideoViewController,showPostitial);
    
    CHLoadLateClass(ALBaseVideoViewController);
    CHClassHook(0,ALBaseVideoViewController,isFullyWatched);
    CHClassHook(0,ALBaseVideoViewController,showPostitial);
    
    CHLoadLateClass(GDTRewardPageView);
    CHClassHook(1, GDTRewardPageView,countDownTime);

    CHLoadLateClass(ALAdView);
       CHHook(1,ALAdView, loadAd);
    CHLoadLateClass(GDTAbm3l);
    CHHook(0, GDTAbm3l, isVideoAd);
    CHHook(0, GDTAbm3l, isWechatCanvasAd);
    CHHook(0, GDTAbm3l, forbidLookReward);
    CHHook(0, GDTAbm3l, GDTfunctionp08Xu8);
    CHHook(0, GDTAbm3l, GDTfunctionl5pG1W);
    
    CHLoadLateClass(GDTBizFeedVideoPlayerView);
       CHHook0(GDTBizFeedVideoPlayerView, videoPlayTime);
    CHLoadLateClass(GDTRewardPageView);
      CHHook0(GDTRewardPageView, countDownTime);
    
    CHLoadLateClass(BaiduMobAdAnimationView);

    CHHook0(BaiduMobAdAnimationView, animationProgress);
    CHHook1(BaiduMobAdAnimationView, setAnimationProgress);
    CHHook0(BaiduMobAdAnimationView, animationSpeed);
    CHHook0(BaiduMobAdAnimationView, animationDuration);
    
    CHLoadLateClass(BaiduMobAdNativeProfessionalControlComponent);
        CHHook0(BaiduMobAdNativeProfessionalControlComponent, videoCurrentTime);
    
}

