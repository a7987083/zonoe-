

#import "getKeychain.h"
#import "WX_NongShiFu123.h"
#import "SSZipArchive.h"
#import "PubgLoad.h"
//#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "JHDragView.h"
#import "jianghu.h"
#import "Config.h"
#import "JHPP.h"
#import "JDStatusBarNotification.h"
#import "YYYPicker.h"

#import "PreferenceManager.h"
#import "SVProgressHUD.h"

@interface PubgLoad()<SSZipArchiveDelegate,NSURLSessionDownloadDelegate>
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
                            NSString *cachePath = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"] ;
                            NSString *imageDir = [NSString stringWithFormat:@"%@",cachePath];
                            NSLog(@"✈️删除重复文件, %@", imageDir);
                            NSFileManager *Manager = [NSFileManager defaultManager];
                            [Manager removeItemAtPath:cachePath error:nil];
                            
                            NSString *LibraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/tmp/"];
                            
                            NSDirectoryEnumerator *enumerator1 = [[NSFileManager defaultManager] enumeratorAtPath:LibraryPath];
                            
                            for (NSString *fileName in enumerator1) {
                                
                                [[NSFileManager defaultManager] removeItemAtPath:[LibraryPath stringByAppendingPathComponent:fileName] error:nil];
                            }
                            
                            NSLog(@"存档 数据");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
                                [presenter dismissAnimated:YES]; // 或者 YES，取决于你的需求
                                [presenter presentWithText:@"准备下载存档,请稍后." dismissAfterDelay:0 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
                            });
                            
                                 NSURL *url = [NSURL URLWithString:下载地址];
                                 NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                                // 2、利用NSURLSessionDownloadTask创建任务(task)
                                NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
//                                NSLog(@"验证成功=%@",task);
                       
                            
                                // 3、执行任务
                                [task resume];
                         
                         

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
/*
 1.接收到服务器返回的数据
 bytesWritten: 当前这一次写入的数据大小
 totalBytesWritten: 已经写入到本地文件的总大小
 totalBytesExpectedToWrite : 被下载文件的总大小
 */


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
 
 
        float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    if (progress < 1) {
        NSString *progressText = [NSString stringWithFormat:@"请耐心等待,下载中... %.0f%%", progress * 100];
        
        // 更新 JDStatusBarNotification 的文本和进度条
        dispatch_async(dispatch_get_main_queue(), ^{
            [[JDStatusBarNotificationPresenter sharedPresenter] updateText:progressText];
            [[JDStatusBarNotificationPresenter sharedPresenter] displayProgressBarWithPercentage:progress];
        });
        
     }
    else if (progress == 1) {
 
           [[JDStatusBarNotificationPresenter sharedPresenter] presentWithText:@"下载成功"
                    dismissAfterDelay:1 // 显示 1 秒后自动消失
                        includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
       }
    float jd = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    NSString*下载进度=[NSString stringWithFormat:@"下载中请稍后-已下载%.0f％\n请耐心等待不要关闭游戏",jd*100];
    
    
    if (jd!=1) {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.detailsLabelText =下载进度;
    hud.userInteractionEnabled = YES;
    hud.progress = jd;
    [hud hide:YES afterDelay:1];
    }
  
}


/*
 2.下载完成
 downloadTask:里面包含请求信息，以及响应信息
 location：下载后自动帮我保存的地址
 */

static NSString*savePath;
static NSString *fullPath;
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];


    NSError*error;
    NSString *cachePath = [NSHomeDirectory() stringByAppendingString:@"/tmp/"] ;

        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        //无限金币输出 创建
        savePath = [cachePath stringByAppendingPathComponent:downloadTask.response.suggestedFilename];

        NSURL*saveUrl = [NSURL fileURLWithPath:savePath];
        // 通过文件管理 复制文件
    [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&error];
    // 1. 必须是 zip 文件
       if (![[savePath pathExtension].lowercaseString isEqualToString:@"zip"]) {
           NSLog(@"❌ 不是 zip 文件: %@", savePath);
           return;
       }

       // 2. 后台执行解压，避免卡 UI
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

           NSFileManager *manager = [NSFileManager defaultManager];

           // 3. 解压目标目录
           NSString *destDir =
               [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe/"];

           NSLog(@"📌 解压目标目录: %@", destDir);

           // 4. 如果目标目录已存在 → 清空（避免重复文件）
           if ([manager fileExistsAtPath:destDir]) {
               NSLog(@"⚠️ 发现旧目录，先删除: %@", destDir);
               [manager removeItemAtPath:destDir error:nil];
           }

           // 5. 创建目录
           NSError *dirError = nil;
           [manager createDirectoryAtPath:destDir
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&dirError];

           if (dirError) {
               NSLog(@"❌ 创建目录失败: %@", dirError.localizedDescription);
               return;
           }

           // 6. 开始解压
           NSLog(@"📦 开始解压 zip: %@", savePath);

           BOOL success =
               [SSZipArchive unzipFileAtPath:savePath
                              toDestination:destDir];

           // 7. 解压结果处理
           if (success) {

               NSLog(@"✅ 解压成功!");

               // 删除 zip 文件（释放空间）
               [manager removeItemAtPath:savePath error:nil];

               // UI 提示必须回主线程
               dispatch_async(dispatch_get_main_queue(), ^{

                   JDStatusBarNotificationPresenter *presenter =
                       [JDStatusBarNotificationPresenter sharedPresenter];

                   [presenter presentWithText:@"正在加载存档，请稍等..."
                            dismissAfterDelay:5
                              includedStyle:JDStatusBarNotificationIncludedStyleLight];

                   // 存档移动处理（你的逻辑）
                   [[YYYPicker alloc] yidongwenjian];

               });

           } else {

               NSLog(@"❌ 解压失败: %@", savePath);

               // 解压失败也删除 zip（防止重复）
               [manager removeItemAtPath:savePath error:nil];

               dispatch_async(dispatch_get_main_queue(), ^{

                   JDStatusBarNotificationPresenter *presenter =
                       [JDStatusBarNotificationPresenter sharedPresenter];

                   [presenter presentWithText:@"存档解压失败，请检查文件是否损坏"
                            dismissAfterDelay:5
                              includedStyle:JDStatusBarNotificationIncludedStyleLight];
               });
           }
       });

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
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        // 2、利用NSURLSessionDownloadTask创建任务(task)
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
        // 3、执行任务
        [task resume];
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
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

        if (testMode || (code && [code intValue] == 1 &&
                         msg && [msg isEqualToString:@"ok"] &&
                         expire && [expire doubleValue] > now)) {
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
            NSURLSession *session =
            [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                          delegate:self
                                     delegateQueue:[NSOperationQueue mainQueue]];
            
            NSURLSessionDownloadTask *task =
            [session downloadTaskWithURL:downloadURL];
            
            [task resume];
        }
    });
}

- (void)cleanupTemporaryFiles {
    NSString *cachePath = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *removeError;

    if ([manager fileExistsAtPath:cachePath]) {
        if (![manager removeItemAtPath:cachePath error:&removeError]) {
            NSLog(@"移除缓存目录 %@ 错误：%@", cachePath, removeError);
        } else {
            NSLog(@"✈️成功移除缓存目录：%@", cachePath);
        }
    }

    // 考虑是否真的需要清除 /tmp/ 中的所有内容
    // 如果不需要，请移除此部分。如果需要，请添加错误检查。
    NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/tmp/"];
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:libraryPath];
    for (NSString *fileName in enumerator) {
        NSError *fileRemoveError;
        if (![manager removeItemAtPath:[libraryPath stringByAppendingPathComponent:fileName] error:&fileRemoveError]) {
            NSLog(@"移除文件 %@ 错误：%@", fileName, fileRemoveError);
        }
    }
}
//
//#pragma mark - NSURLSessionDownloadDelegate
//
//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [SVProgressHUD showSuccessWithStatus:@"下载完成"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        // TODO: 将下载的文件从 'location' 移动到其永久目标位置
//        // 'location' URL 指向一个临时文件。您必须在此方法返回之前移动它。
//        // 示例：
//        // NSError *moveError;
//        // NSString *destinationPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/your_archive.zip"];
//        // if ([[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:destinationPath] error:&moveError]) {
//        //     NSLog(@"已将下载的文件移动到：%@", destinationPath);
//        //     // TODO: 解压文件
//        // } else {
//        //     NSLog(@"移动下载文件错误：%@", moveError);
//        // }
//    });
//}
//
//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
//        // 使用进度更新 SVProgressHUD
//        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"下载中 %.0f%%", progress * 100]];
//    });
//}
//
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (error) {
//            NSLog(@"下载完成时出错：%@", error);
//            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"下载失败: %@", error.localizedDescription]];
//            [SVProgressHUD dismissWithDelay:3.0];
//        } else {
//            // 成功在 didFinishDownloadingToURL 中处理
//        }
//    });
//}

@end

