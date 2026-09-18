from pathlib import Path

p = Path('testmod/菜单/PubgLoad.mm')
s = p.read_text()
old = '''- (void)cleanupTemporaryFiles {
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
}'''
new = '''- (void)cleanupTemporaryFiles {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *tmpRoot = [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"] stringByStandardizingPath];
    NSString *stagingRoot = [[tmpRoot stringByAppendingPathComponent:@"zonoe"] stringByStandardizingPath];

    NSError *stagingError = nil;
    if ([manager fileExistsAtPath:stagingRoot] &&
        ![manager removeItemAtPath:stagingRoot error:&stagingError]) {
        NSLog(@"移除缓存目录 %@ 错误：%@", stagingRoot, stagingError);
    } else if (!stagingError) {
        NSLog(@"✈️清理 PubgLoad staging：%@", stagingRoot);
    }

    // 只清理由本进程 PubgLoad 明确记录的旧下载 ZIP；绝不枚举/清空整个 App /tmp。
    NSString *ownedArchivePath = [savePath stringByStandardizingPath];
    NSString *tmpPrefix = [tmpRoot stringByAppendingString:@"/"];
    BOOL ownedByPubgLoad = ownedArchivePath.length > 0 &&
                           [ownedArchivePath hasPrefix:tmpPrefix] &&
                           [[[ownedArchivePath pathExtension] lowercaseString] isEqualToString:@"zip"];
    if (ownedByPubgLoad && [manager fileExistsAtPath:ownedArchivePath]) {
        NSError *archiveError = nil;
        if (![manager removeItemAtPath:ownedArchivePath error:&archiveError]) {
            NSLog(@"移除旧下载 ZIP %@ 错误：%@", ownedArchivePath, archiveError);
        }
    }
    savePath = nil;
}'''
if s.count(old) != 1:
    raise SystemExit(f'cleanupTemporaryFiles block count mismatch: {s.count(old)}')
p.write_text(s.replace(old, new, 1))
print('P56 transform applied')
