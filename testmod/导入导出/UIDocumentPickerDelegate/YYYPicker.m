
//
//  ViewController.m
//  DocumentPicker
//
//  Created by 聂宽 on 2018/6/27.
//  Copyright © 2018年 聂宽. All rights reserved.
//

#import "YYYPicker.h"
#import "NKSeleDocumentTool.h"
#import "OtherFilesViewCell.h"
#import <QuickLook/QuickLook.h>
#import "SVProgressHUD.h"
#import "SSZipArchive.h"
#import "PreferenceManager.h"
#import "jhpp.h"

#define screenW [[UIScreen mainScreen] bounds].size.width
#define screenH [[UIScreen mainScreen] bounds].size.height

#define NKColorWithRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface YYYPicker ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataArr;


@property (nonatomic, strong) NKOtherFilesModel *seleFileM;
 
@end
// cell
static NSString *OtherFilesViewCellID = @"OtherFilesViewCell";

@implementation YYYPicker

//- (NSMutableArray *)dataArr
//{
//    if (_dataArr == nil) {
//        _dataArr = [NSMutableArray array];
//        
//        NSString *documentPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"OtherFiles"];
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        NSArray *files = [fileManager contentsOfDirectoryAtPath:documentPath error:nil];
//        for (NSString *fileName in files) {
//            NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
//            NKOtherFilesModel *model = [[NKOtherFilesModel alloc] init];
//            model.fileName = fileName;
//            model.filePath = filePath;
//            [_dataArr addObject:model];
//        }
//    }
//    return _dataArr;
//}
- (NSMutableArray *)dataArr
{
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}
+ (void)recursivelyCopyContentsOfDirectory:(NSString *)sourcePath
                                toDirectory:(NSString *)destinationPath
                                  fileManager:(NSFileManager *)fm
                                    skipItems:(NSSet<NSString *> *)skipItems
                                        error:(NSError **)error
{
    BOOL srcIsDir = NO;
    if (![fm fileExistsAtPath:sourcePath isDirectory:&srcIsDir]) return;

    // 1. 类型预检查：如果目标已存在，但类型与源不符，强制删除目标以防冲突
    BOOL dstExists = NO;
    BOOL dstIsDir = NO;
    dstExists = [fm fileExistsAtPath:destinationPath isDirectory:&dstIsDir];

    if (dstExists && (srcIsDir != dstIsDir)) {
        // 类型不匹配（例如：源是文件夹，目标是文件；或反之）
        [fm removeItemAtPath:destinationPath error:nil];
        dstExists = NO; // 重置标记
    }

    if (srcIsDir) {
        // 处理目录
        if (!dstExists) {
            [fm createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:error];
        }
        
        NSArray *contents = [fm contentsOfDirectoryAtPath:sourcePath error:error];
        for (NSString *item in contents) {
            if ([skipItems containsObject:item]) continue;
            [self recursivelyCopyContentsOfDirectory:[sourcePath stringByAppendingPathComponent:item]
                                         toDirectory:[destinationPath stringByAppendingPathComponent:item]
                                           fileManager:fm
                                             skipItems:skipItems
                                                 error:error];
        }
    } else {
        // 处理文件：直接覆盖式拷贝
        if (dstExists) {
            [fm removeItemAtPath:destinationPath error:nil];
        }
        [fm copyItemAtPath:sourcePath toPath:destinationPath error:error];
    }
}




- (void)addBtnAction
{
  
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    

                             [[NKSeleDocumentTool shareDocumentTool] seleDocumentWithDocumentTypes:@[@"public.data"]
                                                                                              Mode:UIDocumentPickerModeImport controller:self finishBlock:^(NSArray<NSURL *> *urls) {
                                 NSURL *fileUrl = urls.firstObject;
 

                                 NSString *fileName = [[[fileUrl absoluteString] componentsSeparatedByString:@"/"] lastObject];
                                 NSString*fileNamezc = [fileName stringByRemovingPercentEncoding];
 
                                 
                                  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                                 NSString *CFBundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
                                  NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
                                 NSString *dataFilea = [NSHomeDirectory() stringByAppendingString:@"/tmp/"] ;
                                 NSString *cachesPathz = [NSString stringWithFormat:@"%@%@-Inbox",dataFilea,BundID];
                                 NSLog(@"🆚BundID=\n%@\n",CFBundleDisplayName);
 
                                     self->_dataArr = nil;
                                     [self.collectionView reloadData];
                                 NSString *dataFile = [cachesPathz stringByAppendingPathComponent:fileNamezc];
                                  NSString *zonoefile = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe"] ;
                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                     [SVProgressHUD showWithStatus:@"处理中..."];
                                     BOOL isSuccess =
                                     [SSZipArchive unzipFileAtPath:dataFile toDestination:zonoefile];

                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (isSuccess) {
                                             NSFileManager *Manager = [NSFileManager defaultManager];
                                             [Manager removeItemAtPath:cachesPathz error:nil];
                                             [self yidongwenjian];
                                         }
                                     });
                                 });
//                                 
//                                 BOOL isSuccess=[SSZipArchive unzipFileAtPath:dataFile toDestination:zonoefile];
//                                 
//                                 if (isSuccess) {
//                                     NSFileManager *Manager = [NSFileManager defaultManager];
//                                     [Manager removeItemAtPath:cachesPathz error:nil];
//                                     [self yidongwenjian];
//                                 }
                             }];
         });
}
- (NSString *)fixedName:(NSString *)name {
    NSData *data = [name dataUsingEncoding:NSISOLatin1StringEncoding];
    NSString *utf8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return utf8 ?: name;
}

- (NSString *)findTargetDir:(NSString *)target inRoot:(NSString *)root
{
    NSFileManager *fm = [NSFileManager defaultManager];

    BOOL isDir = NO;
    if (![fm fileExistsAtPath:root isDirectory:&isDir] || !isDir) {
        return nil;
    }

    NSArray *items = [fm contentsOfDirectoryAtPath:root error:nil];
    for (NSString *item in items) {

        // 跳过无意义目录
        if ([item hasPrefix:@"."] || [item isEqualToString:@"__MACOSX"]) {
            continue;
        }

        NSString *fixed = [self fixedName:item];
        NSString *path = [root stringByAppendingPathComponent:item];

        if (![fm fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
            continue;
        }

        // 1️⃣ 当前目录就是目标
        if ([fixed isEqualToString:target]) {
            return path;
        }

        // 2️⃣ 递归子目录
        NSString *found = [self findTargetDir:target inRoot:path];
        if (found) return found;
    }

    return nil;
}


- (void)yidongwenjian {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *root = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];

        // 1️⃣ 找真实 Documents / Library
        NSString *srcDoc = [self findTargetDir:@"Documents" inRoot:root];
        NSString *srcLib = [self findTargetDir:@"Library" inRoot:root];

        if (!srcDoc && !srcLib) {
            NSLog(@"❌ zip 中未找到 Documents / Library");
            return;
        }

        NSError *err = nil;
        NSSet *skip = [NSSet setWithObjects:
            @"__MACOSX", @".DS_Store", @"Preferences", nil];

        // 2️⃣ 拷贝 Documents
        if (srcDoc) {
            NSString *dstDoc =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;

            [YYYPicker recursivelyCopyContentsOfDirectory:srcDoc
                                                toDirectory:dstDoc
                                                  fileManager:fm
                                                    skipItems:skip
                                                        error:&err];

            NSLog(err ? @"❌ Documents 复制失败" : @"✅ Documents 复制完成");
        }

        // 3️⃣ 拷贝 Library
        if (srcLib) {
            NSString *dstLib =
            NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;

            [YYYPicker recursivelyCopyContentsOfDirectory:srcLib
                                                toDirectory:dstLib
                                                  fileManager:fm
                                                    skipItems:skip
                                                        error:&err];

            NSLog(err ? @"❌ Library 复制失败" : @"✅ Library 复制完成");
        }

        // 4️⃣ 加载配置
        dispatch_async(dispatch_get_main_queue(), ^{
            [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];
        });
    });
}

  
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OtherFilesViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:OtherFilesViewCellID forIndexPath:indexPath];
    NKOtherFilesModel *model = self.dataArr[indexPath.item];
    cell.model = model;
    return cell;
}



#pragma mark - item宽高
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemW = (screenW - (1 + 3)*5 ) /3 ;
    return CGSizeMake(itemW, itemW + 10);
}

#pragma mark - <UICollectionViewDelegateFlowLayout>
#pragma mark - X间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}

#pragma mark - Y间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}



- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:self.seleFileM.filePath];
    return documentsDirectoryURL;
}
 
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *documentPath =[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"OtherFiles"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        [[NSFileManager defaultManager]
         createDirectoryAtPath:documentPath
         withIntermediateDirectories:YES
         attributes:nil error:nil];
    }

    [self loadOtherFilesAsync]; // ✅ 异步加载
}
- (void)loadOtherFilesAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *tmpArr = [NSMutableArray array];

        NSString *documentPath =[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"OtherFiles"];

        NSArray *files =
        [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil];

        for (NSString *fileName in files) {
            NKOtherFilesModel *model = [[NKOtherFilesModel alloc] init];
            model.fileName = fileName;
            model.filePath = [documentPath stringByAppendingPathComponent:fileName];
            [tmpArr addObject:model];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataArr = tmpArr;
            [self.collectionView reloadData];
        });
    });
}

- (void)showAppStoreProductPage {
    // 1. 创建 SKStoreProductViewController 实例
    SKStoreProductViewController *storeProductVC = [[SKStoreProductViewController alloc] init];

    // 2. 设置代理，以便在用户关闭产品页面时收到通知
    storeProductVC.delegate = self;

    NSString *bbid=[[NSUserDefaults standardUserDefaults] objectForKey:@"游戏版本ID"];

    // 3. 定义要加载的 App 的参数
    // SKStoreProductParameterITunesItemIdentifier 是必需的，用于指定要展示的 App 的唯一 ID
    // 这是一个示例 ID，你需要替换为你的目标 App 的实际 ID
    // 例如，如果你想展示微信的App Store页面，它的ID是 414478124
    // 你可以在 App Store 链接中找到这个 ID，例如：https://apps.apple.com/cn/app/%E5%BE%AE%E4%BF%A1/id414478124
    // 最后的 "id" 后面跟着的数字就是 Item ID id6739293205
//    NSNumber *appID =bbid; // 示例：微信的 App ID

    NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier : bbid};
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
              
      
   
    // 4. 加载产品信息
    // completionBlock 会在产品信息加载完成后被调用，无论成功或失败
    [storeProductVC loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (result) {
            // 成功加载产品信息后，呈现 SKStoreProductViewController
            [self presentViewController:storeProductVC animated:YES completion:nil];
        } else {
            // 加载失败，处理错误
            NSLog(@"Failed to load App Store product page: %@", error.localizedDescription);
            // 可以在这里给用户一个提示，例如网络问题或 App ID 错误
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Could not load App Store page. Please try again later."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    });
}

#pragma mark - SKStoreProductViewControllerDelegate

// 当用户点击“完成”按钮或通过其他方式关闭产品页面时，此方法会被调用
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    // 关闭 SKStoreProductViewController
    [viewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"App Store product page dismissed.");
        // 在这里可以执行任何产品页面关闭后的逻辑，例如刷新UI，记录事件等
    }];
}
@end

