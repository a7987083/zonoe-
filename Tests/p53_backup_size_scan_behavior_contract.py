from pathlib import Path

src = Path("testmod/导入导出/daochucd.m").read_text()
version = Path("VERSION").read_text().strip()

required = [
    "requestBackupDecisionForItemNamed:",
    "copyBackupItems:",
    "copyBackupTopLevelFrom:",
    "folderSizeAtPath:",
    "NSDirectoryEnumerator<NSString *> *enumerator",
    "enumeratorAtPath:folderPath",
    "enumerator.fileAttributes",
    "NSFileTypeRegular",
    "attributes.fileSize",
    "50 * 1024 * 1024",
    '@"跳过"',
    '@"备份"',
    'label:@"Documents"',
    'label:@"Library"',
    'createZipFileAtPath:zipPath withContentsOfDirectory:tmpBase',
    '[self fenxiang:km]',
]

for marker in required:
    assert marker in src, f"missing behavior marker: {marker}"

for forbidden in [
    "subpathsOfDirectoryAtPath:folderPath",
    "attributesOfItemAtPath:fullPath",
    "dispatch_semaphore_wait",
    "DISPATCH_TIME_FOREVER",
]:
    assert forbidden not in src, f"legacy expensive/blocking marker still present: {forbidden}"

assert src.index('label:@"Documents"') < src.index('label:@"Library"'), "Documents must still be backed up before Library"
assert src.count("50 * 1024 * 1024") == 1, "50 MiB threshold drifted"
assert version == "v1_p53", f"unexpected VERSION: {version}"
print("P53 backup size scan behavior contract: PASS")
