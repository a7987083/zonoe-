from pathlib import Path

p = Path('testmod/菜单/PubgLoad.mm')
s = p.read_text()

old_progress = '''- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
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
    NSString*下载进度=[NSString stringWithFormat:@"下载中请稍后-已下载%.0f％\\n请耐心等待不要关闭游戏",jd*100];
    
    
    if (jd!=1) {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.detailsLabelText =下载进度;
    hud.userInteractionEnabled = YES;
    hud.progress = jd;
    [hud hide:YES afterDelay:1];
    }
  
}
'''

new_progress = '''- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    BOOL hasKnownTotal = totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown;
    if (!hasKnownTotal) {
        double downloadedMB = (double)totalBytesWritten / (1024.0 * 1024.0);
        NSString *progressText = [NSString stringWithFormat:@"请耐心等待,下载中... %.1f MB", downloadedMB];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[JDStatusBarNotificationPresenter sharedPresenter] updateText:progressText];
        });
        return;
    }

    float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    progress = MAX(0.0f, MIN(1.0f, progress));
    if (progress < 1.0f) {
        NSString *progressText = [NSString stringWithFormat:@"请耐心等待,下载中... %.0f%%", progress * 100];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[JDStatusBarNotificationPresenter sharedPresenter] updateText:progressText];
            [[JDStatusBarNotificationPresenter sharedPresenter] displayProgressBarWithPercentage:progress];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[JDStatusBarNotificationPresenter sharedPresenter] presentWithText:@"下载成功"
                    dismissAfterDelay:1
                    includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
        });
    }

    NSString *下载进度 = [NSString stringWithFormat:@"下载中请稍后-已下载%.0f％\\n请耐心等待不要关闭游戏", progress * 100];
    if (progress < 1.0f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
            hud.detailsLabelText = 下载进度;
            hud.userInteractionEnabled = YES;
            hud.progress = progress;
            [hud hide:YES afterDelay:1];
        });
    }
}
'''

if s.count(old_progress) != 1:
    raise SystemExit(f'expected one progress block, found {s.count(old_progress)}')
s = s.replace(old_progress, new_progress, 1)

old_copy = '''        NSURL*saveUrl = [NSURL fileURLWithPath:savePath];
        // 通过文件管理 复制文件
    [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&error];
    // 1. 必须是 zip 文件
       if (![[savePath pathExtension].lowercaseString isEqualToString:@"zip"]) {
           NSLog(@"❌ 不是 zip 文件: %@", savePath);
           return;
       }
'''
new_copy = '''        NSURL*saveUrl = [NSURL fileURLWithPath:savePath];
        // 通过文件管理 复制文件
    BOOL copied = [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&error];
    if (!copied) {
        NSLog(@"❌ 保存下载文件失败: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:@"保存下载文件失败"];
            [SVProgressHUD dismissWithDelay:3.0];
        });
        return;
    }
    // 1. 必须是 zip 文件
       if (![[savePath pathExtension].lowercaseString isEqualToString:@"zip"]) {
           NSLog(@"❌ 不是 zip 文件: %@", savePath);
           [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
           dispatch_async(dispatch_get_main_queue(), ^{
               [SVProgressHUD showErrorWithStatus:@"下载文件不是ZIP"];
               [SVProgressHUD dismissWithDelay:3.0];
           });
           return;
       }
'''
if s.count(old_copy) != 1:
    raise SystemExit(f'expected one copy block, found {s.count(old_copy)}')
s = s.replace(old_copy, new_copy, 1)

anchor = '''- (void)startArchiveDownloadWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    NSURLSessionDownloadTask *task = [[self zonoeArchiveDownloadSession] downloadTaskWithURL:url];
    [task resume];
}
'''
addition = anchor + '''\n- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error\n{\n    if (!error) {\n        return;\n    }\n    NSLog(@"❌ 下载任务失败: %@", error.localizedDescription);\n    dispatch_async(dispatch_get_main_queue(), ^{\n        [[JDStatusBarNotificationPresenter sharedPresenter] dismissAnimated:YES];\n        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"下载失败: %@", error.localizedDescription ?: @"未知错误"]];\n        [SVProgressHUD dismissWithDelay:3.0];\n    });\n}\n'''
if s.count(anchor) != 1:
    raise SystemExit(f'expected one startArchiveDownloadWithURL anchor, found {s.count(anchor)}')
s = s.replace(anchor, addition, 1)

p.write_text(s)
Path('VERSION').write_text('v1_p58\n')
