//
//  ViewController.m
//  DocumentPicker
//
//  Created by 聂宽 on 2018/6/27.
//  Copyright © 2018年 聂宽. All rights reserved.
//

#import "YYYPicker.h"
#import "OtherFilesViewCell.h"
#import <QuickLook/QuickLook.h>
#import "ZONLocalRestoreCoordinator.h"

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

#pragma mark - Restore compatibility surface

- (void)addBtnAction
{
    __weak typeof(self) weakSelf = self;
    [[ZONLocalRestoreCoordinator sharedCoordinator]
     presentLocalRestoreFromViewController:self
     selectionHandler:^(__unused NSURL *selectedURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self->_dataArr = nil;
        [self.collectionView reloadData];
    }];
}

- (void)restorePreparedArchiveStaging
{
    [[ZONLocalRestoreCoordinator sharedCoordinator] restorePreparedArchiveStaging];
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
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
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
