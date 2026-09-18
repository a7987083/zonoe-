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

#pragma mark - Restore engine

+ (NSSet<NSString *> *)restoreSkipItems
{
    static NSSet<NSString *> *skipItems;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        skipItems = [NSSet setWithObjects:@"__MACOSX", @".DS_Store", @"Preferences", nil];
    });
    return skipItems;
}

- (NSString *)restoreStagingRootPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];
}

- (NSString *)restoreInboxPathForBundleIdentifier:(NSString *)bundleIdentifier
{
    NSString *tmpRoot = [NSHomeDirectory() stringByAppendingString:@"/tmp/"];
    return [NSString stringWithFormat:@"%@%@-Inbox", tmpRoot, bundleIdentifier];
}

- (BOOL)cleanupRestorePath:(NSString *)path
{
    if (path.length == 0) return YES;

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) return YES;

    NSError *error = nil;
    BOOL removed = [fm removeItemAtPath:path error:&error];
    if (!removed) {
        NSLog(@"❌ 清理恢复临时路径失败 %@: %@", path, error.localizedDescription);
    }
    return removed;
}

- (BOOL)prepareRestoreStagingRoot:(NSString *)stagingRoot error:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![self cleanupRestorePath:stagingRoot]) {
        if (error) {
            *error = [NSError errorWithDomain:@"ZONRestore"
                                         code:1000
                                     userInfo:@{NSLocalizedDescriptionKey: @"无法清理恢复临时目录"}];
        }
        return NO;
    }

    return [fm createDirectoryAtPath:stagingRoot
         withIntermediateDirectories:YES
                          attributes:nil
                               error:error];
}

+ (BOOL)recursivelyCopyContentsOfDirectory:(NSString *)sourcePath
                               toDirectory:(NSString *)destinationPath
                               fileManager:(NSFileManager *)fm
                                 skipItems:(NSSet<NSString *> *)skipItems
                                     error:(NSError **)error
{
    BOOL srcIsDir = NO;
    if (![fm fileExistsAtPath:sourcePath isDirectory:&srcIsDir]) {
        if (error) {
            *error = [NSError errorWithDomain:@"ZONRestore"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"恢复源文件不存在"}];
        }
        return NO;
    }

    BOOL dstExists = NO;
    BOOL dstIsDir = NO;
    dstExists = [fm fileExistsAtPath:destinationPath isDirectory:&dstIsDir];

    if (dstExists && (srcIsDir != dstIsDir)) {
        if (![fm removeItemAtPath:destinationPath error:error]) {
            return NO;
        }
        dstExists = NO;
    }

    if (srcIsDir) {
        if (!dstExists) {
            if (![fm createDirectoryAtPath:destinationPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:error]) {
                return NO;
            }
        }

        NSArray *contents = [fm contentsOfDirectoryAtPath:sourcePath error:error];
        if (!contents) return NO;

        for (NSString *item in contents) {
            if ([skipItems containsObject:item]) continue;
            BOOL copied = [self recursivelyCopyContentsOfDirectory:[sourcePath stringByAppendingPathComponent:item]
                                                       toDirectory:[destinationPath stringByAppendingPathComponent:item]
                                                       fileManager:fm
                                                         skipItems:skipItems
                                                             error:error];
            if (!copied) return NO;
        }
        return YES;
    }

    if (dstExists && ![fm removeItemAtPath:destinationPath error:error]) {
        return NO;
    }
    return [fm copyItemAtPath:sourcePath toPath:destinationPath error:error];
}

- (NSString *)fixedName:(NSString *)name
{
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
        if ([item hasPrefix:@"."] || [item isEqualToString:@"__MACOSX"]) {
            continue;
        }

        NSString *fixed = [self fixedName:item];
        NSString *path = [root stringByAppendingPathComponent:item];

        if (![fm fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
            continue;
        }

        if ([fixed isEqualToString:target]) {
            return path;
        }

        NSString *found = [self findTargetDir:target inRoot:path];
        if (found) return found;
    }

    return nil;
}

- (BOOL)restoreDirectoryFrom:(NSString *)sourcePath
               toDestination:(NSString *)destinationPath
                       label:(NSString *)label
                 fileManager:(NSFileManager *)fileManager
                   skipItems:(NSSet<NSString *> *)skipItems
                       error:(NSError **)error
{
    if (sourcePath.length == 0 || destinationPath.length == 0) return YES;

    BOOL restored = [YYYPicker recursivelyCopyContentsOfDirectory:sourcePath
                                                       toDirectory:destinationPath
                                                       fileManager:fileManager
                                                         skipItems:skipItems
                                                             error:error];

    NSLog(restored ? @"✅ %@ 复制完成" : @"❌ %@ 复制失败: %@", label, restored ? @"" : (*error).localizedDescription);
    return restored;
}

- (BOOL)restoreBackupTreeAtRoot:(NSString *)root
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *srcDoc = [self findTargetDir:@"Documents" inRoot:root];
    NSString *srcLib = [self findTargetDir:@"Library" inRoot:root];

    if (!srcDoc && !srcLib) {
        NSLog(@"❌ zip 中未找到 Documents / Library");
        return NO;
    }

    NSSet<NSString *> *skipItems = [YYYPicker restoreSkipItems];
    BOOL allSucceeded = YES;

    if (srcDoc) {
        NSError *docError = nil;
        NSString *dstDoc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                NSUserDomainMask,
                                                                YES).firstObject;
        BOOL docSucceeded = [self restoreDirectoryFrom:srcDoc
                                         toDestination:dstDoc
                                                 label:@"Documents"
                                           fileManager:fm
                                             skipItems:skipItems
                                                 error:&docError];
        if (!docSucceeded) {
            allSucceeded = NO;
            NSLog(@"❌ Documents 恢复失败: %@", docError.localizedDescription);
        }
    }

    if (srcLib) {
        NSError *libError = nil;
        NSString *dstLib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                NSUserDomainMask,
                                                                YES).firstObject;
        BOOL libSucceeded = [self restoreDirectoryFrom:srcLib
                                         toDestination:dstLib
                                                 label:@"Library"
                                           fileManager:fm
                                             skipItems:skipItems
                                                 error:&libError];
        if (!libSucceeded) {
            allSucceeded = NO;
            NSLog(@"❌ Library 恢复失败: %@", libError.localizedDescription);
        }
    }

    return allSucceeded;
}

- (void)reloadRestoredPreferences
{
    [PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"];
}

- (void)unzipRestoreArchiveAtPath:(NSString *)archivePath
                        inboxPath:(NSString *)inboxPath
                      stagingRoot:(NSString *)stagingRoot
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showWithStatus:@"处理中..."];
        });

        NSError *stagingError = nil;
        BOOL prepared = [self prepareRestoreStagingRoot:stagingRoot error:&stagingError];
        if (!prepared) {
            NSLog(@"❌ 准备恢复临时目录失败: %@", stagingError.localizedDescription);
            [self cleanupRestorePath:stagingRoot];
            [self cleanupRestorePath:inboxPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"准备恢复目录失败"];
            });
            return;
        }

        BOOL isSuccess = [SSZipArchive unzipFileAtPath:archivePath toDestination:stagingRoot];
        if (!isSuccess) {
            NSLog(@"❌ 解压恢复包失败: %@", archivePath);
            BOOL stagingCleaned = [self cleanupRestorePath:stagingRoot];
            [self cleanupRestorePath:inboxPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:stagingCleaned ? @"解压失败" : @"解压失败，临时文件清理失败"];
            });
            return;
        }

        [self cleanupRestorePath:inboxPath];
        [self yidongwenjian];
    });
}

- (void)handlePickedRestoreURL:(NSURL *)fileUrl
{
    if (!fileUrl) return;

    NSString *fileName = [[[fileUrl absoluteString] componentsSeparatedByString:@"/"] lastObject];
    NSString *decodedFileName = [fileName stringByRemovingPercentEncoding];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *displayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *bundleIdentifier = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *inboxPath = [self restoreInboxPathForBundleIdentifier:bundleIdentifier];
    NSString *archivePath = [inboxPath stringByAppendingPathComponent:decodedFileName];
    NSString *stagingRoot = [self restoreStagingRootPath];

    NSLog(@"🆚BundID=\n%@\n", displayName);

    self->_dataArr = nil;
    [self.collectionView reloadData];

    [self unzipRestoreArchiveAtPath:archivePath
                         inboxPath:inboxPath
                       stagingRoot:stagingRoot];
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

- (void)yidongwenjian
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *stagingRoot = [self restoreStagingRootPath];
        BOOL restored = [self restoreBackupTreeAtRoot:stagingRoot];
        BOOL stagingCleaned = [self cleanupRestorePath:stagingRoot];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!restored) {
                [SVProgressHUD showErrorWithStatus:stagingCleaned ? @"恢复失败" : @"恢复失败，临时文件清理失败"];
                return;
            }

            [self reloadRestoredPreferences];
            [SVProgressHUD showSuccessWithStatus:stagingCleaned ? @"恢复完成" : @"恢复完成，但临时文件清理失败"];
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
