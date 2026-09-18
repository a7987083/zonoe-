from pathlib import Path

src = Path('testmod/菜单/PubgLoad.mm').read_text()
version = Path('VERSION').read_text().strip()
assert version == 'v1_p58', version

required = [
    'NSURLSessionTransferSizeUnknown',
    'totalBytesExpectedToWrite > 0',
    'downloadedMB',
    '下载失败:',
    'didCompleteWithError:(NSError *)error',
    'BOOL copied = [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&error];',
    '保存下载文件失败',
    '下载文件不是ZIP',
    'removeItemAtPath:savePath error:nil',
    'cleanupTemporaryFiles',
    'startArchiveDownloadWithURL:',
    'SSZipArchive unzipFileAtPath:savePath',
    '[[YYYPicker alloc] yidongwenjian]',
]
for marker in required:
    assert marker in src, marker

# Unknown/absent Content-Length must not enter percentage division.
progress_start = src.index('- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:')
progress_end = src.index('/*\n 2.下载完成', progress_start)
progress = src[progress_start:progress_end]
assert 'if (!hasKnownTotal)' in progress
assert progress.index('if (!hasKnownTotal)') < progress.index('(float)totalBytesWritten / (float)totalBytesExpectedToWrite')

# P56 ownership boundary must remain active.
cleanup_start = src.index('- (void)cleanupTemporaryFiles')
cleanup = src[cleanup_start:]
assert 'ownedByPubgLoad' in cleanup
assert 'enumeratorAtPath:tmpRoot' not in cleanup

print('P58 download lifecycle contract PASS')
