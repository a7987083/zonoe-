

#import "getKeychain.h"
#import "WX_NongShiFu123.h"
#import "SSZipArchive.h"
#import "PubgLoad.h"
//#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "JHDragView.h"
#import "Config.h"
#import "JHPP.h"
#import "JDStatusBarNotification.h"
#import "YYYPicker.h"

#import "PreferenceManager.h"
#import "SVProgressHUD.h"
#import "ZONRemoteDownloadService.h"
#import "ZONRestoreService.h"

@interface PubgLoad()
@property (nonatomic, strong) dispatch_source_t timer;
@end




static BOOL isFileExists(NSString * filename)
{
    NSFileManager * filemanager;
    filemanager = [[NSFileManager alloc]init];
    if (![filemanager fileExistsAtPath:filename]) {
        return NO;
    }
    return YES;
}
static NSArray *dataSource;

static NSDictionary *zhugongneng;
static NSDictionary *json;
static NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
static NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
static PubgLoad *extraInfo;
static BOOL MenDeal;

@implementation PubgLoad
//-(void)loadcaidan
//{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[PubgLoad alloc] qidong];
//    });
//}
//-(void)qidong
//{
//
//    extraInfo =  [PubgLoad new];
//    [extraInfo initTapGes];
//    [extraInfo tapIconView];
//}
//-(void)initTapGes
//{
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
//    tap.numberOfTapsRequired = 2;//点击次数
//    tap.numberOfTouchesRequired = 3;//手指数
//    [[JHPP currentViewController].view addGestureRecognizer:tap];
//    [tap addTarget:self action:@selector(tapIconView)];
//}
//
//
//-(void)tapIconView
//{
//    JHDragView *view = [[JHPP currentViewController].view viewWithTag:100];
//    if (!view) {
//        view = [[JHDragView alloc] init];
//        view.tag = 100;
//        [[JHPP currentViewController].view addSubview:view];
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cdtc)];
//        tap.numberOfTapsRequired = 1;
//        [view addGestureRecognizer:tap];
//    }
//
//    if (!MenDeal) {
//        view.hidden = NO;
//
//    } else {
//        view.hidden = YES;
//
//    }
//
//    MenDeal = !MenDeal;
//}
//-(void)cdtc
//{
//    [jianghu chushihua];
//
//}
+ (NSString *)getUTF8EncodeStringWithURLString:(NSString *)urlString
{
    if (urlString && urlString.length > 0)
    {
        NSString *encodedString = (NSString *)
        CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (CFStringRef)urlString,
                                                                  (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                                  NULL,
                                                                  kCFStringEncodingUTF8));
        return encodedString;
    }
    else
    {
        return @"";
    }
}


-(void)loadddd
{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //解析服务器版本
        NSError *error;
        //获取应用ID
        //获取info.plist
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
        NSLog(@"🆚BundID=\n%@\n",BundID);
        NSString *txturl = [NSString stringWithFormat:@"%@%@.json",homeurl,BundID];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:txturl]];
        json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];


        if ([json[@"code"] integerValue] == 500|| data==nil){
     
            
                 [SVProgressHUD showWithStatus:@"未查询到有云存档\n..."];
                [SVProgressHUD dismissWithDelay:3.0];
         }else{
        if (error==nil) {
 
    
            NSString *主标题 = [json objectForKey:@"主标题"];//主功能
            NSString *副标题 = [json objectForKey:@"副标题"];//主功能
//            NSString *取消 = [json objectForKey:@"取消"];//主功能
            NSArray *功能 = [json objectForKey:@"功能"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:主标题 message:副标题 preferredStyle:UIAlertControllerStyleAlert];

            for (int i =0; i< 功能.count; i++) {
                NSDictionary*功能数组=功能[i];
                //                NSLog(@"功能数组=%@",功能数组);
                NSString *按钮名字 = [功能数组 objectForKey:@"按钮名字"];
                //                NSString *解压目录 = [功能数组 objectForKey:@"解压目录"];
                NSString *urldz=[功能数组 objectForKey:@"下载地址"];
                NSString *下载地址啊 = [urldz stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                NSString *url= [NSString stringWithFormat:@"%@%@.zip",homezip,BundID];
                NSString *下载地址 = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                
                
                                UIAlertAction *okAction = [UIAlertAction actionWithTitle:按钮名字 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
     
                
                if([按钮名字 containsString:@"数据"] || [按钮名字 containsString:@"解说"] || [按钮名字 containsString:@"存档"]){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    NSString * rjyyz=[getKeychain getKeychainDataForKey:@"rjyyz"];
                    设备特征码=[getKeychain getKeychainDataForKey:@"DZUDID"];
                    // MARK: 拼接链接、转换成URL
                    NSString *checkUrlString = [NSString stringWithFormat:@"https://app.zonoeios.xyz/index/index/apiface?udid=%@",设备特征码];
                    NSURL *checkUrl = [NSURL URLWithString:checkUrlString];
                    NSLog(@"URL 返回的 strarr字符串：%@", checkUrl);
                    // MARK: 获取网络数据AppStore上app的信息
                    NSString *appInfoString = [NSString stringWithContentsOfURL:checkUrl encoding:NSUTF8StringEncoding error:nil];
                    
                    // MARK: 字符串转json转字典
                    NSData *JSONData = [appInfoString dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary* dicInfo = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
                        
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                    if (dicInfo) {
                        软件信息=dicInfo[@"msg"];
//                        NSLog(@"%@dd",软件信息);
                        if ([软件信息 containsString:@"ok"]  ) {
                            [self cleanupTemporaryFiles];
                            NSLog(@"存档 数据");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                                [presenter dismissAnimated:YES]; // 或者 YES，取决于你的需求
                                [presenter presentWithText:@"准备下载存档,请稍后." dismissAfterDelay:0 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
                            });
                            
                                 NSURL *url = [NSURL URLWithString:下载地址];
                                 [self startArchiveDownloadWithURL:url];
                         
                         

                        }else{
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"你没有购买\n请先购买再尝试解锁" preferredStyle:UIAlertControllerStyleAlert];
                            [alertController addAction:[UIAlertAction actionWithTitle:@"购买解锁码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                           
                               
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址] options:@{} completionHandler:^(BOOL success) {
                                    exit(0);
                                }];
                               

                            }]];
                       
                            [[JHPP currentViewController] presentViewController:alertController animated:YES completion:nil];
                            });
                        }
                    }
                     });
                    
                });
                }
                
                                }];
                                  [alert addAction:okAction];
             }

            [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
            }
        
        }
    });
}
#pragma mark ---获取时间
- (NSString *)getSystemDates{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_Hans_CN"];
    dateFormatter.calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    [dateFormatter setDateFormat:@"yyyy-MM-dd#HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    return dateStr;
}
-(void)openurl:(NSString*)url
{
    NSLog(@"跳转：%@",url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];

}
#pragma mark - P67 remote download orchestration

- (void)presentRemoteDownloadProgressReceived:(int64_t)received expected:(int64_t)expected
{
    JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
    if (expected > 0 && expected != NSURLSessionTransferSizeUnknown) {
        float progress = MAX(0.0f, MIN(1.0f, (float)received / (float)expected));
        if (progress < 1.0f) {
            [presenter updateText:[NSString stringWithFormat:@"请耐心等待,下载中... %.0f%%", progress * 100.0f]];
            [presenter displayProgressBarWithPercentage:progress];
        }
    } else {
        double downloadedMB = (double)received / (1024.0 * 1024.0);
        [presenter updateText:[NSString stringWithFormat:@"请耐心等待,下载中... %.1f MB", downloadedMB]];
    }
}

- (void)startArchiveDownloadWithURL:(NSURL *)url
{
    if (!url) {
        [SVProgressHUD showErrorWithStatus:@"下载链接无效"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }

    [[ZONRemoteDownloadService sharedService]
     downloadArchiveFromURL:url
     progress:^(int64_t receivedBytes, int64_t expectedBytes) {
        [self presentRemoteDownloadProgressReceived:receivedBytes expected:expectedBytes];
     }
     completion:^(NSString *archivePath, NSError *downloadError) {
        if (downloadError || archivePath.length == 0) {
            [[JDStatusBarNotificationPresenter sharedPresenter] dismissAnimated:YES];
            [SVProgressHUD showErrorWithStatus:downloadError.localizedDescription ?: @"下载失败"];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }

        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"下载成功，正在恢复存档..."
                 dismissAfterDelay:0
                   includedStyle:JDStatusBarNotificationIncludedStyleSuccess];

        [[ZONRestoreService sharedService]
         restoreArchiveAtPath:archivePath
         inboxPath:nil
         completion:^(BOOL success, NSError *restoreError) {
            [presenter dismissAnimated:YES];
            if (!success) {
                [SVProgressHUD showErrorWithStatus:restoreError.localizedDescription ?: @"恢复失败"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }
            if (restoreError.code == ZONRestoreErrorCleanupFailed) {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
            } else {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
            }
        }];
     }];
}

- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code
                                    msg:(NSString *)msg
                                 expire:(NSNumber *)expire
                               testMode:(BOOL)testMode
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return testMode || (code && [code intValue] == 1 &&
                        msg && [msg isEqualToString:@"ok"] &&
                        expire && [expire doubleValue] > now);
}

-(void)yuanchengdwon
{


        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"远程下载存档" message:@"✅支持本菜单备份的zip文件" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请填写下载地址";
            textField.secureTextEntry = NO;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.layer.masksToBounds=YES;
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 确定操作
            UITextField *textField1 = alert.textFields.firstObject;
            NSLog(@"输入框1：%@", textField1.text);
            if (textField1.text.length ==0 ) {
                NSLog(@"输入框内容为空");
                // 输入框内容为空，做出相应提示或处理
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self yuanchengdwon];
                });
            }else{
                [self xiazaidz:textField1.text];
            }

        }];
        UIAlertAction *quxiaoAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:okAction];
        [alert addAction:quxiaoAction];

    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
//    });

    }

-(void)xiazaidz:(NSString*)远程下载地址
{
    dispatch_async(dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
//        [presenter dismissAnimated:YES]; // 或者 YES，取决于你的需求
        [presenter presentWithText:@"准备下载存档,请稍后." dismissAfterDelay:10 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
    });
         NSURL *url = [NSURL URLWithString:远程下载地址];
        [self startArchiveDownloadWithURL:url];
 }




// 此方法可以在视图出现时或应用启动时调用
- (void)checkCloudSaveStatus {
    // 显示加载指示器
    [SVProgressHUD showWithStatus:@"正在检查云存档文件..."];
//    NSString *rjyyz=[getKeychain getKeychainDataForKey:@"rjyyz"];
//    NSLog(@"rjyyz信息：%@", rjyyz);
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
//    NSLog(@"🆚BundleID=\n%@\n", bundleID);

    NSString *jsonURLString = [NSString stringWithFormat:@"%@%@.json", homeurl, bundleID];
    NSURL *url = [NSURL URLWithString:jsonURLString];

    if (!url) {
        NSLog(@"错误：无效的 JSON URL: %@", jsonURLString);
        [SVProgressHUD showErrorWithStatus:@"URL错误"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }
    
  

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss]; // 隐藏加载指示器

            if (error) {
                NSLog(@"获取 JSON 错误：%@", error);
                [SVProgressHUD showErrorWithStatus:@"网络连接失败，请检查网络"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            if (!data) {
                NSLog(@"错误：未从服务器接收到数据。");
                [SVProgressHUD showErrorWithStatus:@"未获取到服务器数据"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            NSError *jsonError;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];

            if (jsonError) {
                NSLog(@"解析 JSON 错误：%@", jsonError);
                [SVProgressHUD showErrorWithStatus:@"未查询到数据"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                NSLog(@"错误：JSON 不是字典类型。");
                [SVProgressHUD showErrorWithStatus:@"服务器数据格式错误"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            NSDictionary *json = (NSDictionary *)jsonObject;

            if ([json[@"code"] integerValue] == 500) {
                [SVProgressHUD showWithStatus:@"未查询到有云存档\n..."];
                [SVProgressHUD dismissWithDelay:3.0];
            } else {
                [self presentCloudSaveAlertWithJSON:json];
            }
        });
    }];
    [dataTask resume];
}

- (void)presentCloudSaveAlertWithJSON:(NSDictionary *)json {
    NSString *mainTitle = [json objectForKey:@"主标题"];
    NSString *subTitle = [json objectForKey:@"副标题"];
    NSArray *functions = [json objectForKey:@"功能"];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:mainTitle message:subTitle preferredStyle:UIAlertControllerStyleAlert];

    for (NSDictionary *functionDict in functions) {

        NSString *buttonName = functionDict[@"按钮名字"];
        NSString *downloadAddress = functionDict[@"下载地址"];

        // ✅ 防止 Block 捕获 bug
        NSString *safeName = [buttonName copy];
        NSString *safeURL  = [downloadAddress copy];

        UIAlertAction *action =
        [UIAlertAction actionWithTitle:safeName
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {

            // ✅ 存档类按钮 → 默认 homezip + bundleID.zip
            if ([safeName containsString:@"数据"] ||
                [safeName containsString:@"解说"] ||
                [safeName containsString:@"存档"]) {

//                NSLog(@"📌 存档按钮：走默认 bundleID.zip");

                // ⚠️ 传 nil 表示使用默认方式
                [self handleDownloadActionForBundleID:BundID
                                     downloadAddress:nil];

            } else {

                // ✅ 其他按钮 → 走 JSON 的 downloadAddress
//                NSLog(@"📌 普通按钮：走 JSON 地址 %@", safeURL);

                [self handleDownloadActionForBundleID:BundID
                                     downloadAddress:safeURL];
            }
        }];

        [alert addAction:action];
    }


    // 如果需要，添加取消动作
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
}

 - (void)handleDownloadActionForBundleID:(NSString *)bundleID downloadAddress:(NSString *)downloadAddress {
    // 在后台线程执行购买检查
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *deviceUDID = [getKeychain getKeychainDataForKey:@"DZUDID"];
//        NSLog(@"rjyyz信息：%@", rjyyz);
        NSString *checkUrlString = [NSString stringWithFormat:@"https://app.zonoeios.xyz/index/index/apiface?udid=%@", deviceUDID];
        NSURL *checkUrl = [NSURL URLWithString:checkUrlString];

        if (!checkUrl) {
//            NSLog(@"错误：无效的检查 URL: %@", checkUrlString);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"验证链接错误"];
                [SVProgressHUD dismissWithDelay:2.0];
            });
            return;
        }

        NSError *appInfoError;
        NSString *appInfoString = [NSString stringWithContentsOfURL:checkUrl encoding:NSUTF8StringEncoding error:&appInfoError];

        if (appInfoError) {
//            NSLog(@"获取应用信息错误：%@", appInfoError);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"无法验证购买信息，请检查网络"];
                [SVProgressHUD dismissWithDelay:3.0];
            });
            return;
        }

        NSData *jsonData = [appInfoString dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData) {
//            NSLog(@"错误：无法将应用信息字符串转换为数据。");
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"购买信息数据错误"];
                [SVProgressHUD dismissWithDelay:3.0];
            });
            return;
        }

        NSError *dicInfoError;
        NSDictionary *dicInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&dicInfoError];

        if (dicInfoError) {
//            NSLog(@"解析购买检查 JSON 错误：%@", dicInfoError);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"购买信息解析失败"];
                [SVProgressHUD dismissWithDelay:3.0];
            });
            return;
        }

 
//        NSLog(@"软件信息：%@", softwareInfo);
//        if(kmm.length>34 || [kmm containsString:@"mg"] || [rjyyz containsString:@"未查到解锁记录"] )

//        if (checkUrlString != nil ) {
        
        NSNumber *code = dicInfo[@"code"];
        NSString *msg = dicInfo[@"msg"];
        NSNumber *expire = dicInfo[@"expire"];
        BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

        if ([self isCloudEntitlementValidWithCode:code
                                              msg:msg
                                           expire:expire
                                         testMode:testMode]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                [presenter dismissAnimated:YES]; // 或者 YES，取决于你的需求
                [presenter presentWithText:@"准备下载存档,请稍后." dismissAfterDelay:0 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
            });
            
            // 下载前清理临时文件
            [self cleanupTemporaryFiles];
            
            // ✅ 最关键：选择下载地址（反向逻辑）
            // ==================================================
            NSString *downloadURLString = nil;
            
            // =======================================================
            // ✅ 情况1：downloadAddress == nil → 存档按钮 → 默认下载
            // =======================================================
            if (downloadAddress == nil) {
                
                downloadURLString =
                [NSString stringWithFormat:@"%@%@.zip", homezip, bundleID];
                
                //                NSLog(@"✅ 存档按钮：使用默认 bundleID.zip");
                
                // =======================================================
                // ✅ 情况2：downloadAddress 是空字符串 → 禁止下载
                // =======================================================
            } else if (downloadAddress.length == 0) {
                
                //                NSLog(@"❌ JSON 下载地址为空，禁止下载");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                    
                    [presenter dismissAnimated:YES]; // 或者 YES，取决于你的需求
                    [presenter presentWithText:@"下载地址为空." dismissAfterDelay:2 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
                });
                
                return;
                
                // =======================================================
                // ✅ 情况3：downloadAddress 有值 → 普通按钮下载 JSON 地址
                // =======================================================
            } else {
                
                downloadURLString = downloadAddress;
                
                //                NSLog(@"✅ 普通按钮：使用 JSON 地址 %@", downloadURLString);
            }
            
            
            // ==================================================
            // ✅ 创建 URL
            // ==================================================
            NSURL *downloadURL =
            [NSURL URLWithString:[downloadURLString
                                  stringByAddingPercentEncodingWithAllowedCharacters:
                                      [NSCharacterSet URLQueryAllowedCharacterSet]]];
            
            if (!downloadURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"下载链接无效"];
                    [SVProgressHUD dismissWithDelay:2.0];
                });
                return;
            }
            
            // ==================================================
            // ✅ 开始下载
            // ==================================================
            [self startArchiveDownloadWithURL:downloadURL];
        }
    });
}

- (void)cleanupTemporaryFiles
{
    // P67 intentionally does not enumerate or clear the application's entire /tmp tree.
    // ZONRestoreService owns /tmp/zonoe and removes the selected downloaded archive after restore.
    NSString *stagingRoot = [[ZONRestoreService sharedService] restoreStagingRootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stagingRoot]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:stagingRoot error:&error]) {
            NSLog(@"P67 staging cleanup failed %@: %@", stagingRoot, error.localizedDescription);
        }
    }
}

@end

