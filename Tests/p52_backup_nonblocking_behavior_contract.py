from pathlib import Path

src = Path("testmod/导入导出/daochucd.m").read_text()
version = Path("VERSION").read_text().strip()

required = [
    "requestBackupDecisionForItemNamed:",
    "copyBackupItems:",
    "copyBackupTopLevelFrom:",
    '50 * 1024 * 1024',
    '@"提示"',
    '@"跳过"',
    '@"备份"',
    '备份 \"%@\" 大于 %.2f MB，是否跳过？',
    'label:@"Documents"',
    'label:@"Library"',
    'HeimdallrBU',
    'UnityCache',
    'Documents/zonoe',
    'createZipFileAtPath:zipPath withContentsOfDirectory:tmpBase',
    '[self fenxiang:km]',
    '准备备份...',
    '开始压缩...',
    '备份完成',
    '压缩失败',
]

for marker in required:
    assert marker in src, f"missing behavior marker: {marker}"

for forbidden in [
    "dispatch_semaphore_t",
    "dispatch_semaphore_create",
    "dispatch_semaphore_wait",
    "dispatch_semaphore_signal",
    "DISPATCH_TIME_FOREVER",
    "shouldSkipBackupItemNamed:",
]:
    assert forbidden not in src, f"blocking legacy marker still present: {forbidden}"

assert src.index('label:@"Documents"') < src.index('label:@"Library"'), "Documents must still be backed up before Library"
assert src.count("50 * 1024 * 1024") == 1, "50 MiB threshold drifted"
assert version == "v1_p52", f"unexpected VERSION: {version}"
print("P52 backup nonblocking behavior contract: PASS")
