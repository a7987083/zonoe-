#import "fuzhu.h"
 #import "YYYPicker.h"
 #import "SSZipArchive.h"
 
#import "daochucd.h"
#import "SomeOtherFile.h"
#import "JHPP.h"

static NSTimer*timer;
@implementation NSObject (Menuz)



//比较是否存在文件
static BOOL isFileExists(NSString * filename)
{
    NSFileManager * filemanager;
    filemanager = [[NSFileManager alloc]init];
    if (![filemanager fileExistsAtPath:filename]) {
        return NO;
    }
    return YES;
}


 
   
 

-(void)checkbanben
{
    // 获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    NSString *fwqbbh;
    NSString *yymc;
    NSString *xzdz;
    NSString *gxrq;
    NSString *bbid;
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *CFBundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//    NSString *url= [NSString stringWithFormat:@"nsk-sign://web?url=https://zoyun.com/d/ipa/quguanggao/%@.ipa",CFBundleDisplayName];
//    NSString *下载地址 = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    // 返回是否有新版本
    BOOL update = [self checkAppStoreVersionWithAppId:BundID];
    
    // 添加自己的代码，可以弹出一个框UIAlertController，这里不实现了，不是要点。
    if (update) {
        
        bbid=[[NSUserDefaults standardUserDefaults] objectForKey:@"游戏版本ID"];
        gxrq=[[NSUserDefaults standardUserDefaults] objectForKey:@"最新版本日期"];
        fwqbbh=[[NSUserDefaults standardUserDefaults] objectForKey:@"服务器版本号"];
        yymc=[[NSUserDefaults standardUserDefaults] objectForKey:@"应用名称"];
        xzdz=[[NSUserDefaults standardUserDefaults] objectForKey:@"下载地址"];
        
//        NSString *bbidk = [NSString stringWithFormat:@"nsk-sign://web?rul=https://apps.apple.com/hk/app/id%@", bbid];

        NSString *jianchabanben = [NSString stringWithFormat:@"当前版本%@\n App Store版本是%@\n", appVersion,fwqbbh];
        NSString *yymcxx = [NSString stringWithFormat:@"%@\n新版本(国际)\n(发布时间:\n%@)", yymc,gxrq];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            
//            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:yymcxx message:jianchabanben preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *oneAction = [UIAlertAction actionWithTitle:@"外部App Store查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
//                
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:xzdz] options:@{} completionHandler:NULL];
//                
//            }];
//            UIAlertAction *eneAction = [UIAlertAction actionWithTitle:@"内部App Store查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
//
//                [[SomeOtherFile alloc] userClickedPromoteButton];
//
//            }];
//       
//            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"忽略" style:UIAlertActionStyleCancel handler:nil];
//            //把提示框按钮添加到提示控制器上
//            [alertController addAction:oneAction];
//             [alertController addAction:eneAction];
//            [alertController addAction:cancelAction];
//            //让提示框可以显示
//            [[JHPP currentViewController] presentViewController:alertController animated:YES completion:nil];
//
////            UIViewController * currentwindow = [[[UIApplication sharedApplication] keyWindow] rootViewController];
////            [currentwindow presentViewController:alertController animated:YES completion:nil];
//            // 下载地址可以是trackViewUrl，也可以是itms-apps://itunes.apple.com/app/id444934666
//            //        NSString *string = [NSString stringWithFormat:@"https://docs.qq.com/doc/DWmlqZ2NmVHBrSERP"];
//            //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
//        });
    }
}
/**
 检查版本更新
 
 @param BundID app的id
 
 @return 返回是否有更新。YES:有; NO:无。
 */
- (BOOL)checkAppStoreVersionWithAppId:(NSString *)BundID
{
    // MARK: 拼接链接、转换成URL
    NSString *checkUrlString = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?bundleId=%@", BundID];
    NSURL *checkUrl = [NSURL URLWithString:checkUrlString];
    
    // MARK: 获取网络数据AppStore上app的信息
    NSString *appInfoString = [NSString stringWithContentsOfURL:checkUrl encoding:NSUTF8StringEncoding error:nil];
    
    // MARK: 字符串转json转字典
    NSError *error = nil;
    NSData *JSONData = [appInfoString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *appInfo = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableLeaves error:&error];
    
    if (!error && appInfo) {
        // 返回没错误，那就开始获取app信息啦，很多内容，要解剖这数据 results->array[0]->version
//        NSLog(@"%@", appInfo);
        NSArray *resultsAry = appInfo[@"results"];
        NSDictionary *resultsDic = resultsAry.firstObject;
        
        // 版本号
        NSString *version = resultsDic[@"version"];
        [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"服务器版本号"];
        
        // 应用名称
        NSString *trackCensoredName = resultsDic[@"trackName"];
        [[NSUserDefaults standardUserDefaults] setObject:trackCensoredName forKey:@"应用名称"];
        
        // 下载地址
        NSString *trackViewUrl = resultsDic[@"trackViewUrl"];
        [[NSUserDefaults standardUserDefaults] setObject:trackViewUrl forKey:@"下载地址"];
        // 版本更新日期
        NSString *currentVersionReleaseDate = resultsDic[@"currentVersionReleaseDate"];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersionReleaseDate forKey:@"最新版本日期"];
        // 版本id
        NSString *trackId = resultsDic[@"trackId"];
        [[NSUserDefaults standardUserDefaults] setObject:trackId forKey:@"游戏版本ID"];
        
        // FIXME: 比较版本号
        return [self compareVersion:version];;
    }else{
        // 返回错误，则相当于无更新吧，看你怎么想咯
        
        return NO;
    }
}

/**
 比较版本大小
 
 @param serverVersion 服务器版本
 
 @return 返回是否有更新。YES:有; NO:无。
 */
- (BOOL)compareVersion:(NSString *)serverVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    // MARK: 拼接链接、转换成URL
    NSString *checkUrlString = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?bundleId=%@", BundID];
    NSURL *checkUrl = [NSURL URLWithString:checkUrlString];
    
    // MARK: 获取网络数据AppStore上app的信息
    NSString *appInfoString = [NSString stringWithContentsOfURL:checkUrl encoding:NSUTF8StringEncoding error:nil];
    
    // MARK: 字符串转json转字典
    NSData *JSONData = [appInfoString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    
    // MARK: 比较当前版本和新版本号大小
    /*
     typedef enum _NSComparisonResult {
     NSOrderedAscending = -1,    // < 升序
     NSOrderedSame,              // = 等于
     NSOrderedDescending         // > 降序
     } NSComparisonResult;
     */
    
    // MARK: 比较方法
    if ([appVersion compare:serverVersion options:NSNumericSearch] == NSOrderedAscending) {
        NSLog(@"发现新版本 %@", serverVersion);
        [[NSUserDefaults standardUserDefaults] setObject:serverVersion forKey:@"服务器版本号"];
        return YES;
    }else{
        NSLog(@"没有新版本再查一次");
        NSDictionary* dicInfo = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
        
        if ([dicInfo[@"resultCount"] integerValue] == 0){
            [NSObject checkbanbencn];
        }
        return NO;
    }
}

-(void)checkbanbencn
{
    // 获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    NSString *fwqbbh;
    NSString *yymc;
    NSString *xzdz;
    NSString *gxrq;
    NSString *bbid;

    // 这个是哪个app的id，你们会知道的
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *CFBundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//    NSString *url= [NSString stringWithFormat:@"nsk-sign://web?url=https://zonoecom/d/ipa/quguanggao/%@.ipa",CFBundleDisplayName];
//    NSString *下载地址 = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    //    static NSString *appId = bundleIdhq;
    
    // 返回是否有新版本
    BOOL update = [self checkAppStoreVersionWithAppIdcn:BundID];
    // 添加自己的代码，可以弹出一个框UIAlertController，这里不实现了，不是要点。
    if (update) {
        bbid=[[NSUserDefaults standardUserDefaults] objectForKey:@"游戏版本ID"];
        gxrq=[[NSUserDefaults standardUserDefaults] objectForKey:@"最新版本日期"];
        fwqbbh=[[NSUserDefaults standardUserDefaults] objectForKey:@"服务器版本号"];
        yymc=[[NSUserDefaults standardUserDefaults] objectForKey:@"应用名称"];
        xzdz=[[NSUserDefaults standardUserDefaults] objectForKey:@"下载地址"];
        
//        NSString *bbidk = [NSString stringWithFormat:@"nsk-sign://web?rul=https://apps.apple.com/hk/app/id%@", bbid];

        
        NSString *jianchabanben = [NSString stringWithFormat:@"当前版本%@\n App Store版本是%@\n", appVersion,fwqbbh];
        NSString *yymcxx = [NSString stringWithFormat:@"%@\n新版本(国内)\n(发布时间:\n%@)", yymc,gxrq];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            
//            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:yymcxx message:jianchabanben preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *oneAction = [UIAlertAction actionWithTitle:@"外部App Store查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
//                
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:xzdz] options:@{} completionHandler:NULL];
//                
//            }];
//            UIAlertAction *eneAction = [UIAlertAction actionWithTitle:@"内部App Store查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
//
//                [[SomeOtherFile alloc] userClickedPromoteButton];
//
//            }];
// 
////            UIAlertAction *zxgx = [UIAlertAction actionWithTitle:@"在线更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
////                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:下载地址] options:@{} completionHandler:NULL];
////            }];
//        
//            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"忽略" style:UIAlertActionStyleCancel handler:nil];
//            //把提示框按钮添加到提示控制器上
//            [alertController addAction:oneAction];
//            [alertController addAction:eneAction];
// //            [alertController addAction:zxgx];
//            [alertController addAction:cancelAction];
//            //让提示框可以显示
//            
//            [[JHPP currentViewController] presentViewController:alertController animated:YES completion:nil];
//
////            UIViewController * currentwindow = [[[UIApplication sharedApplication] keyWindow] rootViewController];
////            [currentwindow presentViewController:alertController animated:YES completion:nil];
//            
//            // 下载地址可以是trackViewUrl，也可以是itms-apps://itunes.apple.com/app/id444934666
//            //        NSString *string = [NSString stringWithFormat:@"https://docs.qq.com/doc/DWmlqZ2NmVHBrSERP"];
//            //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
//        });
    }
}
/**
 检查版本更新
 
 @param BundID app的id
 
 @return 返回是否有更新。YES:有; NO:无。
 */
- (BOOL)checkAppStoreVersionWithAppIdcn:(NSString *)BundID
{
    // MARK: 拼接链接、转换成URL
    NSString *checkUrlString = [NSString stringWithFormat:@"https://itunes.apple.com/cn/lookup?bundleId=%@", BundID];
    NSURL *checkUrl = [NSURL URLWithString:checkUrlString];
    
    // MARK: 获取网络数据AppStore上app的信息
    NSString *appInfoString = [NSString stringWithContentsOfURL:checkUrl encoding:NSUTF8StringEncoding error:nil];
    
    // MARK: 字符串转json转字典
    NSError *error = nil;
    NSData *JSONData = [appInfoString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *appInfo = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableLeaves error:&error];
    
    if (!error && appInfo) {
        // 返回没错误，那就开始获取app信息啦，很多内容，要解剖这数据 results->array[0]->version
        NSLog(@"%@", appInfo);
        NSArray *resultsAry = appInfo[@"results"];
        NSDictionary *resultsDic = resultsAry.firstObject;
        
        // 版本号
        NSString *version = resultsDic[@"version"];
        [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"服务器版本号"];

        NSString *resultCount = resultsDic[@"resultCount"];
        NSLog(@"%@", resultCount);
        // 应用名称
        NSString *trackCensoredName = resultsDic[@"trackName"];
        [[NSUserDefaults standardUserDefaults] setObject:trackCensoredName forKey:@"应用名称"];
        
        // 下载地址
        NSString *trackViewUrl = resultsDic[@"trackViewUrl"];
        [[NSUserDefaults standardUserDefaults] setObject:trackViewUrl forKey:@"下载地址"];
        
        // 版本更新日期
        NSString *currentVersionReleaseDate = resultsDic[@"currentVersionReleaseDate"];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersionReleaseDate forKey:@"最新版本日期"];
        
        // 版本id
        NSString *trackId = resultsDic[@"trackId"];
        [[NSUserDefaults standardUserDefaults] setObject:trackId forKey:@"游戏版本ID"];
        // FIXME: 比较版本号
        return [self compareVersioncn:version];;
    }else{
        // 返回错误，则相当于无更新吧，看你怎么想咯
        
        return NO;
    }
}

- (BOOL)compareVersioncn:(NSString *)serverVersion
{
    // 获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    
    // MARK: 比较当前版本和新版本号大小
    /*
     typedef enum _NSComparisonResult {
     NSOrderedAscending = -1,    // < 升序
     NSOrderedSame,              // = 等于
     NSOrderedDescending         // > 降序
     } NSComparisonResult;
     */
    
    // MARK: 比较方法
    if ([appVersion compare:serverVersion options:NSNumericSearch] == NSOrderedAscending) {
        NSLog(@"发现新版本 %@", serverVersion);
        [[NSUserDefaults standardUserDefaults] setObject:serverVersion forKey:@"服务器版本号"];
        return YES;
    }else{
        NSLog(@"没有新版本");
        return NO;
        
    }
}

@end
