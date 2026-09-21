

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
#import "ZONRestoreAPI.h"
#import "ZONCloudSaveService.h"

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
    // Legacy compatibility entry. P68 keeps a single cloud-save orchestration path.
    [self checkCloudSaveStatus];
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

        [[ZONRestoreAPI sharedAPI]
         restoreArchiveAtPath:archivePath
         inboxPath:nil
         completion:^(BOOL success, NSError *restoreError) {
            [presenter dismissAnimated:YES];
            if (!success) {
                [SVProgressHUD showErrorWithStatus:restoreError.localizedDescription ?: @"恢复失败"];
                [SVProgressHUD dismissWithDelay:3.0];
                return;
            }

            // Normal success exits through ZONRestoreAPI's preserved P66 tail.
            // This is only reached when PreferenceManager returns instead of exiting.
            if (restoreError.code == ZONRestoreErrorCleanupFailed) {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
            } else {
                [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
            }
        }];
     }];
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
- (void)checkCloudSaveStatus
{
    [SVProgressHUD showWithStatus:@"正在检查云存档文件..."];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    [[ZONCloudSaveService sharedService]
     fetchMetadataForBundleIdentifier:bundleID ?: @""
     metadataBaseURLString:homeurl ?: @""
     completion:^(NSDictionary *metadata, NSError *error) {
        [SVProgressHUD dismiss];
        if (error || !metadata) {
            NSString *message = error.localizedDescription ?: @"未查询到数据";
            if (error.code == ZONCloudSaveErrorNoArchive) [SVProgressHUD showWithStatus:message];
            else [SVProgressHUD showErrorWithStatus:message];
            [SVProgressHUD dismissWithDelay:3.0];
            return;
        }
        [self presentCloudSaveAlertWithJSON:metadata];
     }];
}

- (void)presentCloudSaveAlertWithJSON:(NSDictionary *)metadata
{
    NSString *mainTitle = [metadata[@"主标题"] isKindOfClass:[NSString class]] ? metadata[@"主标题"] : @"云存档";
    NSString *subTitle = [metadata[@"副标题"] isKindOfClass:[NSString class]] ? metadata[@"副标题"] : nil;
    NSArray *functions = [metadata[@"功能"] isKindOfClass:[NSArray class]] ? metadata[@"功能"] : @[];
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:mainTitle message:subTitle preferredStyle:UIAlertControllerStyleAlert];
    for (id object in functions) {
        if (![object isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *functionDictionary = (NSDictionary *)object;
        NSString *buttonName = [functionDictionary[@"按钮名字"] isKindOfClass:[NSString class]] ? functionDictionary[@"按钮名字"] : @"云存档";
        UIAlertAction *action = [UIAlertAction actionWithTitle:buttonName style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self handleCloudFunction:functionDictionary bundleIdentifier:bundleID];
        }];
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)presentCloudEntitlementDenied
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"你没有购买\n请先购买再尝试解锁" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"购买解锁码" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址] options:@{} completionHandler:^(__unused BOOL success) { exit(0); }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[JHPP currentViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)handleCloudFunction:(NSDictionary *)functionDictionary bundleIdentifier:(NSString *)bundleIdentifier
{
    NSString *deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"] ?: @"";
    NSString *downloadAddress = [[ZONCloudSaveService sharedService] effectiveDownloadAddressForFunction:functionDictionary];
    BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

    [[ZONCloudSaveService sharedService]
     resolveDownloadURLForBundleIdentifier:bundleIdentifier
     downloadAddress:downloadAddress
     archiveBaseURLString:homezip ?: @""
     deviceIdentifier:deviceIdentifier
     entitlementBaseURLString:@"https://app.zonoeios.xyz/index/index/apiface?udid="
     bypassEntitlement:testMode
     completion:^(NSURL *downloadURL, NSError *error) {
        if (error || !downloadURL) {
            if (error.code == ZONCloudSaveErrorEntitlementDenied) [self presentCloudEntitlementDenied];
            else {
                [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"云存档验证失败"];
                [SVProgressHUD dismissWithDelay:3.0];
            }
            return;
        }
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];
        [presenter presentWithText:@"准备下载存档,请稍后." dismissAfterDelay:0 includedStyle:JDStatusBarNotificationIncludedStyleWarning];
        [self cleanupTemporaryFiles];
        [self startArchiveDownloadWithURL:downloadURL];
     }];
}

- (void)cleanupTemporaryFiles
{
    // P67 intentionally does not enumerate or clear the application's entire /tmp tree.
    NSString *stagingRoot = [[ZONRestoreAPI sharedAPI] restoreStagingRootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stagingRoot]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:stagingRoot error:&error]) {
            NSLog(@"P67 staging cleanup failed %@: %@", stagingRoot, error.localizedDescription);
        }
    }
}

@end

