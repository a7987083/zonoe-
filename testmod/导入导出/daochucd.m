#import "daochucd.h"
#import "SSZipArchive.h"
 #import <QuickLook/QuickLook.h>
#import "JHPP.h"
#import "SVProgressHUD.h"


@interface daochucd ()<UIDocumentInteractionControllerDelegate>
//@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController ;
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
        textField.layer.masksToBounds=YES;
     

    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
        NSString *logDirectoryy = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];
  
            NSFileManager *Manager = [NSFileManager defaultManager];
            [Manager removeItemAtPath:logDirectory error:nil];
            [Manager removeItemAtPath:logDirectoryy error:nil];
        // 确定操作
        UITextField *textField = alert.textFields.firstObject;
        NSLog(@"输入框1：%@", textField.text);
        if (textField.text.length ==0 ) {
            NSLog(@"输入框内容为空");
            // 输入框内容为空，做出相应提示或处理
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *BundID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
                
                 [self bfcundang:BundID];


            });
        }else{
            
            [self bfcundang:textField.text];


        }
        
    }];
    UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    
    }];
    [alert addAction:okAction];
    [alert addAction:cAction];
//
 
    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
    }


-(void)fenxiang:(NSString*)km
{

    NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
    NSString *fileName = [NSString stringWithFormat:@"%@.zip",km];
    NSString *filePath = [logDirectory stringByAppendingPathComponent:fileName];
    _docVc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
    _docVc.delegate = self;
    //直接显示预览界面
//    [_docVc presentPreviewAnimated:YES];
    //    //显示分享文档界面
//    [_docVc  presentOptionsMenuFromRect:[UIScreen mainScreen].bounds inView:[UIApplication sharedApplication].keyWindow.rootViewController.view animated:YES];

//    [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
    UIWindow *targetWindow = nil;

    if (@available(iOS 13.0, *)) {
        // For iOS 13 and later, find the key window from the active scene
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        targetWindow = window;
                        break;
                    }
                }
            }
            if (targetWindow) {
                break;
            }
        }
    } else {
        // For iOS versions prior to 13.0, use the deprecated keyWindow
        targetWindow = [UIApplication sharedApplication].keyWindow;
    }

    // Ensure a valid window is found before proceeding
    if (targetWindow) {
        // Ensure the root view controller exists
        UIViewController *rootVC = targetWindow.rootViewController;
        if (rootVC) {
            // Find the topmost presented view controller
            UIViewController *topmostVC = rootVC;
            while (topmostVC.presentedViewController) {
                topmostVC = topmostVC.presentedViewController;
            }

            // Present the options menu from the view of the topmost view controller
            // Note: It's generally better to present from a specific view within the hierarchy
            // instead of the entire screen bounds (UIScreen mainScreen].bounds).
            // For demonstration, we'll use topmostVC.view's bounds.
            [_docVc presentOptionsMenuFromRect:topmostVC.view.bounds inView:topmostVC.view animated:YES];
        } else {
            NSLog(@"Error: Root view controller not found for the target window.");
        }
    } else {
        NSLog(@"Error: No active key window found to present UIDocumentInteractionController.");
    }

  

}

#pragma mark - UIDocumentInteractionControllerDelegate

// 返回用于预览的视图控制器。这是必须实现的。
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [JHPP currentViewController] ; // 返回当前视图控制器
}

// 当预览即将显示时调用
- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"预览即将开始");
}

// 当预览已经显示时调用
- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"预览已结束");
}

// 当文件即将传递给另一个应用程序时调用 (例如，用户选择了“用...打开”)
- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    NSLog(@"即将发送到应用程序: %@", application);
}

// 当文件已经传递给另一个应用程序时调用
- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    NSLog(@"已发送到应用程序: %@", application);
}

// 当菜单被取消时调用 (例如，用户点击了菜单以外的区域)
- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"“打开方式”菜单已取消");
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"“操作”菜单已取消");
    NSString *logDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents/zonoe/"];
    NSString *logDirectoryy = [NSHomeDirectory() stringByAppendingString:@"/tmp/zonoe/"];


    
        NSFileManager *Manager = [NSFileManager defaultManager];
        [Manager removeItemAtPath:logDirectory error:nil];
        [Manager removeItemAtPath:logDirectoryy error:nil];
}

- (void)bfcundang:(NSString *)km {
    
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
            
            // 创建基础目录（只创建父目录！）
            [self ensureDirectoryExists:documentsTmp];
            [self ensureDirectoryExists:libraryTmp];
            
            // ============================
            // 1️⃣ Documents
            // ============================
            NSArray *documentsSubfolders = [fm contentsOfDirectoryAtPath:documentsSrc error:nil];
            
            for (NSUInteger i = 0; i < documentsSubfolders.count; i++) {
                
                NSString *sub = documentsSubfolders[i];
                NSString *srcPath = [documentsSrc stringByAppendingPathComponent:sub];
                NSString *dstPath = [documentsTmp stringByAppendingPathComponent:sub];
                
                // 👉 大小判断（保留你原逻辑）
                unsigned long long size = [self folderSizeAtPath:srcPath];
                if (size > 50 * 1024 * 1024) {
                    
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    __block BOOL skip = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                       message:[NSString stringWithFormat:@"备份 \"%@\" 大于 %.2f MB，是否跳过？", sub, size / 1024.0 / 1024.0]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"跳过" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                            skip = YES;
                            dispatch_semaphore_signal(sema);
                        }]];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            skip = NO;
                            dispatch_semaphore_signal(sema);
                        }]];
                        
                        [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
                    });
                    
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    if (skip) continue;
                }
                
                // ✅ 核心修复：系统拷贝
                NSError *error = nil;
                
                if ([fm fileExistsAtPath:dstPath]) {
                    [fm removeItemAtPath:dstPath error:nil];
                }
                
                [fm copyItemAtPath:srcPath toPath:dstPath error:&error];
                
                if (error) {
                    NSLog(@"拷贝失败 %@ -> %@ : %@", srcPath, dstPath, error);
                }
                
                CGFloat progress = (CGFloat)(i + 1) / documentsSubfolders.count;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"拷贝 Documents %.0f%%", progress*100]];
                });
            }
            
            // ============================
            // 2️⃣ Library
            // ============================
            NSArray *librarySubfolders = [fm contentsOfDirectoryAtPath:librarySrc error:nil];
            
            for (NSUInteger i = 0; i < librarySubfolders.count; i++) {
                
                NSString *sub = librarySubfolders[i];
                NSString *srcPath = [librarySrc stringByAppendingPathComponent:sub];
                NSString *dstPath = [libraryTmp stringByAppendingPathComponent:sub];
                
                unsigned long long size = [self folderSizeAtPath:srcPath];
                if (size > 50 * 1024 * 1024) {
                    
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    __block BOOL skip = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                       message:[NSString stringWithFormat:@"备份 \"%@\" 大于 %.2f MB，是否跳过？", sub, size / 1024.0 / 1024.0]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"跳过" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                            skip = YES;
                            dispatch_semaphore_signal(sema);
                        }]];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            skip = NO;
                            dispatch_semaphore_signal(sema);
                        }]];
                        
                        [[JHPP currentViewController] presentViewController:alert animated:YES completion:nil];
                    });
                    
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    if (skip) continue;
                }
                
                NSError *error = nil;
                
                if ([fm fileExistsAtPath:dstPath]) {
                    [fm removeItemAtPath:dstPath error:nil];
                }
                
                [fm copyItemAtPath:srcPath toPath:dstPath error:&error];
                
                if (error) {
                    NSLog(@"拷贝失败 %@ -> %@ : %@", srcPath, dstPath, error);
                }
                
                CGFloat progress = (CGFloat)(i + 1) / librarySubfolders.count;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"拷贝 Library %.0f%%", progress*100]];
                });
            }
            
            // ============================
            // 3️⃣ 清理 + 压缩
            // ============================
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
// 计算文件夹大小（递归）
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
// ----------------------------
// 封装方法 - 拷贝目录并更新 SVProgressHUD
// ----------------------------
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
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"%@ %.0f%%", prefix, progress*100]];
        });
    }
}

// ----------------------------
// 封装方法 - 清理目录并更新 SVProgressHUD
// ----------------------------
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
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"%@ %.0f%%", prefix, progress*100]];
        });
    }
}

// ----------------------------
// 封装方法 - 确保目录存在
// ----------------------------
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
