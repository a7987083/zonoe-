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
#import "ZONRestoreService.h"

#define screenW [[UIScreen mainScreen] bounds].size.width
#define screenH [[UIScreen mainScreen] bounds].size.height

#define NKColorWithRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)(rgbValue & 0xFF00) >> 8)/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface YYYPicker ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) NKOtherFilesModel *seleFileM;
@end

static NSString *OtherFilesViewCellID = @"OtherFilesViewCell";

@implementation YYYPicker

- (NSMutableArray *)dataArr
{
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

#pragma mark - Restore orchestration

+ (void)completeRestoreSuccessWithError:(NSError *)error
{
    // Preserve the P66 success tail exactly. PreferenceManager performs:
    // restored preference reload -> synchronize -> legacy staging cleanup -> exit(0).
    [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];

    // Kept for behavioral compatibility if PreferenceManager ever returns instead
    // of terminating the process (for example, synchronize failure).
    if (error.code == ZONRestoreErrorCleanupFailed) {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成，但临时文件清理失败"];
    } else {
        [SVProgressHUD showSuccessWithStatus:@"恢复完成"];
    }
}

- (void)presentRestoreResult:(BOOL)success error:(NSError *)error
{
    if (!success) {
        NSString *message = error.localizedDescription.length ? error.localizedDescription : @"恢复失败";
        [SVProgressHUD showErrorWithStatus:message];
        return;
    }

    [[self class] completeRestoreSuccessWithError:error];
}

- (void)handlePickedRestoreURL:(NSURL *)fileUrl
{
    if (!fileUrl) return;

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    ZONRestoreService *service = [ZONRestoreService sharedService];
    NSString *inboxPath = [service restoreInboxPathForBundleIdentifier:bundleIdentifier];
    NSString *archivePath = fileUrl.path;

    if (![[NSFileManager defaultManager] fileExistsAtPath:archivePath]) {
        NSString *decodedFileName = [[[fileUrl absoluteString] componentsSeparatedByString:@"/"] lastObject].stringByRemovingPercentEncoding;
        archivePath = [inboxPath stringByAppendingPathComponent:decodedFileName ?: @""];
    }

    self->_dataArr = nil;
    [self.collectionView reloadData];
    [SVProgressHUD showWithStatus:@"处理中..."];

    [service restoreArchiveAtPath:archivePath inboxPath:inboxPath completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

#pragma mark - Restore UI entry

- (void)addBtnAction
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[NKSeleDocumentTool shareDocumentTool]
         seleDocumentWithDocumentTypes:@[@"public.data"]
         Mode:UIDocumentPickerModeImport
         controller:self
         finishBlock:^(NSArray<NSURL *> *urls) {
            [self handlePickedRestoreURL:urls.firstObject];
        }];
    });
}

- (void)restorePreparedArchiveStaging
{
    ZONRestoreService *service = [ZONRestoreService sharedService];
    NSString *stagingRoot = [service restoreStagingRootPath];
    [service restorePreparedStagingAtPath:stagingRoot completion:^(BOOL success, NSError *error) {
        [self presentRestoreResult:success error:error];
    }];
}

- (void)yidongwenjian
{
    // Legacy compatibility entry retained for historical callers.
    [self restorePreparedArchiveStaging];
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

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemW = (screenW - (1 + 3)*5 ) /3 ;
    return CGSizeMake(itemW, itemW + 10);
}

#pragma mark - <UICollectionViewDelegateFlowLayout>
#pragma mark - X间距

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

#pragma mark - Y间距

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndexPath:(NSIndexPath *)indexPath
{
    return 5;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:self.seleFileM.filePath];
    return documentsDirectoryURL;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *documentPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask,
                                                                    YES) lastObject]
                              stringByAppendingPathComponent:@"OtherFiles"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }

    [self loadOtherFilesAsync];
}

- (void)loadOtherFilesAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *tmpArr = [NSMutableArray array];

        NSString *documentPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject]
                                  stringByAppendingPathComponent:@"OtherFiles"];

        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil];

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

@end
