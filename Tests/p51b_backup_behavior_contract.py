#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / 'testmod/导入导出/daochucd.m').read_text(errors='replace')

required = [
    '- (void)backupasd',
    '- (void)bfcundang:(NSString *)km',
    '- (BOOL)shouldSkipBackupItemNamed:',
    '- (void)copyBackupTopLevelFrom:',
    '50 * 1024 * 1024',
    '@"跳过"',
    '@"备份"',
    'dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)',
    '@"tmp/zonoe"',
    '@"Documents"',
    '@"Library"',
    '@"HeimdallrBU"',
    '@"Caches"',
    '@"UnityCache"',
    '@"zonoe"',
    '@"Documents/zonoe"',
    'createZipFileAtPath:zipPath withContentsOfDirectory:tmpBase',
    '[self fenxiang:km]',
    '@"准备备份..."',
    '@"开始压缩..."',
    '@"备份完成"',
    '@"压缩失败"',
]
for marker in required:
    if marker not in src:
        raise SystemExit(f'missing backup contract marker: {marker}')

# The old duplicated per-root loops must be gone; both roots use one helper.
if src.count('copyBackupTopLevelFrom:') != 3:  # declaration + two calls
    raise SystemExit('expected one generic backup helper declaration and two root calls')
if src.count('50 * 1024 * 1024') != 1:
    raise SystemExit('50 MiB threshold must have one canonical implementation')
if 'documentsSubfolders' in src or 'librarySubfolders' in src:
    raise SystemExit('duplicated Documents/Library loops returned')

version = (root / 'VERSION').read_text().strip()
if version != 'v1_p51b':
    raise SystemExit(f'unexpected VERSION: {version}')

print('P51B_BACKUP_BEHAVIOR_CONTRACT=PASS')
print('BACKUP_ROOTS=Documents,Library')
print('LARGE_ITEM_THRESHOLD_MIB=50')
print('GENERIC_BACKUP_ROOT_HELPER=true')
