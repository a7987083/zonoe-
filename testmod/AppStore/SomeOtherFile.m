#import "SomeOtherFile.h"
#import "JHPP.h" // 导入 AppDelegate 以获取根视图控制器
#import "YYYPicker.h" // 导入 ViewController 以访问其方法

@implementation SomeOtherFile

- (void)userClickedPromoteButton {
    // 假设这是在某个按钮点击事件或游戏内触发的逻辑

    // 获取 AppDelegate 实例
//    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    // 获取当前最顶层的视图控制器
    UIViewController *topVC = [JHPP currentViewController];

    // 检查 topVC 是否是我们期望的 ViewController 类型，或者它可以处理 SKStoreProductViewController 的展示
    if ([topVC isKindOfClass:[YYYPicker class]]) {
        YYYPicker *myViewController = (YYYPicker *)topVC;
        // 调用 ViewController 中的方法来展示 App Store 产品页面
        [myViewController showAppStoreProductPage];
    } else {
        // 如果当前 topVC 不是 ViewController 类型，或者你不确定哪个VC可以展示
        // 你可能需要确保你的 topMostViewController 方法能够找到一个能 present VC 的控制器
        // 或者直接让 AppDelegate 来处理 SKStoreProductViewController 的展示逻辑
        NSLog(@"Current top view controller cannot show App Store product page directly.");

        // 另一种通用做法：直接在任意 UIViewController 上 present
        // 只要 topVC 是一个有效的 UIViewController 并且在视图层级中，它就可以 present
        SKStoreProductViewController *storeProductVC = [[SKStoreProductViewController alloc] init];
        storeProductVC.delegate = (id<SKStoreProductViewControllerDelegate>)topVC; // 假设 topVC 实现了代理
        
        NSString *bbid=[[NSUserDefaults standardUserDefaults] objectForKey:@"游戏版本ID"];

        
//        NSNumber *appID = @(1492898204); // 替换为你的目标 App ID
        NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier : bbid};
        
        [storeProductVC loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
            if (result) {
                [topVC presentViewController:storeProductVC animated:YES completion:nil];
            } else {
              
                // 在这里添加你的自定义错误处理：
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *alertTitle = @"应用无法访问";
                    NSString *alertMessage = @"此应用可能在美国区 App Store 中，您当前的 Apple ID 无法访问。";

                    // 你可以检查错误代码进行更具体的处理
                    // 例如：if (error.code == SKErrorCodeStoreProductNotAvailable)
                    // 但是，跨区访问的精确错误代码可能不尽相同或比较通用。

                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                   message:alertMessage
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
                    // 获取当前最顶层的视图控制器
                   // UIViewController *topVC = [appDelegate topMostViewController];
                    UIViewController *presentingVC = [JHPP currentViewController] ;
                    if (presentingVC) {
                        [presentingVC presentViewController:alert animated:YES completion:nil];
                    }
                });
            }
        }];
    }
}

@end
