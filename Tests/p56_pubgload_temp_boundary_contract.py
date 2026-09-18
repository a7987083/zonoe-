from pathlib import Path

src = Path('testmod/菜单/PubgLoad.mm').read_text()
version = Path('VERSION').read_text().strip()

required = [
    '- (void)cleanupTemporaryFiles',
    'NSString *tmpRoot = [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"] stringByStandardizingPath];',
    'NSString *stagingRoot = [[tmpRoot stringByAppendingPathComponent:@"zonoe"] stringByStandardizingPath];',
    'NSString *ownedArchivePath = [savePath stringByStandardizingPath];',
    'BOOL ownedByPubgLoad = ownedArchivePath.length > 0',
    '[ownedArchivePath hasPrefix:tmpPrefix]',
    '[[[ownedArchivePath pathExtension] lowercaseString] isEqualToString:@"zip"]',
    'savePath = nil;',
    '[self cleanupTemporaryFiles];',
    '[self startArchiveDownloadWithURL:downloadURL];',
    '[SSZipArchive unzipFileAtPath:savePath',
    '[[YYYPicker alloc] yidongwenjian];',
]
for marker in required:
    assert marker in src, f'missing P56 behavior marker: {marker}'

method = src.split('- (void)cleanupTemporaryFiles', 1)[1].split('\n}\n//', 1)[0]
for forbidden in [
    'enumeratorAtPath:',
    'NSDirectoryEnumerator',
    'for (NSString *fileName',
    'removeItemAtPath:[libraryPath stringByAppendingPathComponent:fileName]',
]:
    assert forbidden not in method, f'unsafe broad tmp cleanup remains in active method: {forbidden}'

assert method.index('removeItemAtPath:stagingRoot') < method.index('ownedArchivePath'), 'staging cleanup must remain explicit and first'
assert version == 'v1_p56', f'unexpected VERSION: {version}'
print('P56 PubgLoad temp-boundary contract: PASS')
