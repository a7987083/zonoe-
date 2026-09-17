#import "daochucd.h"
#import "SSZipArchive.h"
#import <QuickLook/QuickLook.h>
#import "JHPP.h"
#import "SVProgressHUD.h"

@interface daochucd ()<UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *docVc;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end

@implementation daochucd

- (void)backupasd
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请输入文件名字\n直接确定是BundID名字" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"在这里输入文件名字";
        textField.secureTextEntry = NO;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.layer.masksToBounds = YES;
    }];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
        NSString *logDirectoryy = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:logDirectory error:nil];
        [manager removeItemAtPath:logDirectoryy error:nil];

        UITextField *textField = alert.textFields.firstObject;
        NSLog(@"输入框1：%@", textField.text);
        if (textField.text.length == 0) {
            NSLog(@"输入框内容为空");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
                [self bfcundang:BundID];
            });
        } else {
            [self bfcundang:textField.text];
        }
    }];

    UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {}];
    [alert addAction:okAction];
    [alert addAction:cAction];
    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)fenxiang:(NSString *)km
{
    NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
    NSString *fileName = [NSString stringWithFormat:@"%@.zip", km];
    NSString *filePath = [logDirectory stringByAppendingPathComponent:fileName];
    _docVc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
    _docVc.delegate = self;

    UIWindow *targetWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        targetWindow = window;
                        break;
                    }
                }
            }
            if (targetWindow) break;
        }
    } else {
        targetWindow = [UIApplication sharedApplication].keyWindow;
    }

    if (targetWindow) {
        UIViewController *rootVC = targetWindow.rootViewController;
        if (rootVC) {
            UIViewController *topmostVC = rootVC;
            while (topmostVC.presentedViewController) {
                topmostVC = topmostVC.presentedViewController;
            }
            [_docVc presentOptionsMenuFromRect:topmostVC.view.bounds inView:topmostVC.view animated:YES];
        } else {
            NSLog(@"Error: Root view controller not found for the target window.");
        }
    } else {
        NSLog(@"Error: No active key window found to present UIDocumentInteractionController.");
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [JHPP currentViewController];
}

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"预览即将开始");
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"预览已结束");
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    NSLog(@"即将发送到应用程序: %@", application);
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    NSLog(@"已发送到应用程序: %@", application);
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"“打开方式”菜单已取消");
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"“操作”菜单已取消");
    NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
    NSString *logDirectoryy = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:logDirectory error:nil];
    [manager removeItemAtPath:logDirectoryy error:nil];
}

#pragma mark - Backup engine

- (BOOL)shouldSkipBackupItemNamed:(NSString *)itemName size:(unsigned long long)size
{
    if (size <= 50 * 1024 * 1024) return NO;

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL skip = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:[NSString stringWithFormat:@"备份 \"%@\" 大于 %.2f MB，是否跳过？", itemName, size / 1024.0 / 1024.0]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"跳过" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {
            skip = YES;
            dispatch_semaphore_signal(sema);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"备份" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            skip = NO;
            dispatch_semaphore_signal(sema);
        }]];
        [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return skip;
}

- (void)copyBackupTopLevelFrom:(NSString *)source
                            to:(NSString *)destination
                         label:(NSString *)label
                   fileManager:(NSFileManager *)fm
{
    NSArray<NSString *> *items = [fm contentsOfDirectoryAtPath:source error:nil];
    for (NSUInteger i = 0; i < items.count; i++) {
        NSString *item = items[i];
        NSString *srcPath = [source stringByAppendingPathComponent:item];
        NSString *dstPath = [destination stringByAppendingPathComponent:item];

        unsigned long long size = [self folderSizeAtPath:srcPath];
        if ([self shouldSkipBackupItemNamed:item size:size]) continue;

        NSError *error = nil;
        if ([fm fileExistsAtPath:dstPath]) {
            [fm removeItemAtPath:dstPath error:nil];
        }
        [fm copyItemAtPath:srcPath toPath:dstPath error:&error];
        if (error) {
            NSLog(@"拷贝失败 %@ -> %@ : %@", srcPath, dstPath, error);
        }

        CGFloat progress = (CGFloat)(i + 1) / items.count;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"拷贝 %@ %.0f%%", label, progress * 100]];
        });
    }
}

- (void)bfcundang:(NSString *)km
{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showProgress:0 status:@"准备备份..."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSFileManager *fm = [NSFileManager defaultManager];

            NSString *tmpBase = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/zonoe"];
            NSString *documentsTmp = [tmpBase stringByAppendingPathComponent:@"Documents"];
            NSString *libraryTmp = [tmpBase stringByAppendingPathComponent:@"Library"];

            NSString *documentsSrc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *librarySrc = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];

            [self ensureDirectoryExists:documentsTmp];
            [self ensureDirectoryExists:libraryTmp];

            [self copyBackupTopLevelFrom:documentsSrc to:documentsTmp label:@"Documents" fileManager:fm];
            [self copyBackupTopLevelFrom:librarySrc to:libraryTmp label:@"Library" fileManager:fm];

            [self clearDirectory:[libraryTmp stringByAppendingPathComponent:@"HeimdallrBU"] svProgressPrefix:@"清理 HeimdallrBU"];
            [self clearDirectory:[libraryTmp stringByAppendingPathComponent:@"Caches"] svProgressPrefix:@"清理 Caches"];
            [self clearDirectory:[libraryTmp stringByAppendingPathComponent:@"UnityCache"] svProgressPrefix:@"清理 UnityCache"];
            [self clearDirectory:[documentsTmp stringByAppendingPathComponent:@"zonoe"] svProgressPrefix:@"清理 zonoe"];

            NSString *saveDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zonoe"];
            [self ensureDirectoryExists:saveDir];
            NSString *zipPath = [saveDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", km]];

            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showProgress:0 status:@"开始压缩..."];
            });

            BOOL zipSuccess = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:tmpBase];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (zipSuccess) {
                    [SVProgressHUD showSuccessWithStatus:@"备份完成"];
                    [self fenxiang:km];
                } else {
                    [SVProgressHUD showErrorWithStatus:@"压缩失败"];
                }
            });
        }
    });
}

- (unsigned long long)folderSizeAtPath:(NSString *)folderPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm subpathsOfDirectoryAtPath:folderPath error:nil];
    unsigned long long totalSize = 0;
    for (NSString *file in files) {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
            NSDictionary *attr = [fm attributesOfItemAtPath:fullPath error:nil];
            totalSize += [attr fileSize];
        }
    }
    return totalSize;
}

- (void)copyContentsFrom:(NSString *)source to:(NSString *)destination svProgressPrefix:(NSString *)prefix {
    NSFileManager *fm = [NSFileManager defaultManager];
    [self ensureDirectoryExists:destination];
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:source error:&error];
    if (error) { NSLog(@"读取目录失败 %@ : %@", source, error); return; }

    NSUInteger total = contents.count;
    for (NSUInteger i = 0; i < total; i++) {
        NSString *fileName = contents[i];
        NSString *srcPath = [source stringByAppendingPathComponent:fileName];
        NSString *dstPath = [destination stringByAppendingPathComponent:fileName];
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        [fm copyItemAtPath:srcPath toPath:dstPath error:&error];
        if (error) NSLog(@"拷贝失败 %@ -> %@ : %@", srcPath, dstPath, error);

        CGFloat progress = (CGFloat)(i + 1) / total;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"%@ %.0f%%", prefix, progress * 100]];
        });
    }
}

- (void)clearDirectory:(NSString *)path svProgressPrefix:(NSString *)prefix {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) return;
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:&error];
    if (error) { NSLog(@"读取目录失败 %@ : %@", path, error); return; }

    NSUInteger total = contents.count;
    for (NSUInteger i = 0; i < total; i++) {
        NSString *fileName = contents[i];
        NSString *fullPath = [path stringByAppendingPathComponent:fileName];
        [fm removeItemAtPath:fullPath error:&error];
        if (error) NSLog(@"删除失败 %@ : %@", fullPath, error);

        CGFloat progress = (CGFloat)(i + 1) / total;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"%@ %.0f%%", prefix, progress * 100]];
        });
    }
}

- (BOOL)ensureDirectoryExists:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL success = [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) NSLog(@"创建目录失败 %@ : %@", path, error);
        return success;
    }
    return YES;
}

@end
