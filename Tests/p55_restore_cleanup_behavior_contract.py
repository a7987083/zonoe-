from pathlib import Path

src = Path("testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m").read_text()
version = Path("VERSION").read_text().strip()

required = [
    "cleanupRestorePath:",
    "prepareRestoreStagingRoot:",
    "unzipRestoreArchiveAtPath:",
    "restoreBackupTreeAtRoot:",
    "restoreStagingRootPath",
    "restoreInboxPathForBundleIdentifier:",
    'showErrorWithStatus:stagingCleaned ? @"解压失败" : @"解压失败，临时文件清理失败"',
    'showErrorWithStatus:stagingCleaned ? @"恢复失败" : @"恢复失败，临时文件清理失败"',
    'showSuccessWithStatus:stagingCleaned ? @"恢复完成" : @"恢复完成，但临时文件清理失败"',
    "[self cleanupRestorePath:stagingRoot]",
    "[self cleanupRestorePath:inboxPath]",
    "[self reloadRestoredPreferences]",
    '@"public.data"',
    '@"__MACOSX"',
    '@".DS_Store"',
    '@"Preferences"',
]

for marker in required:
    assert marker in src, f"missing behavior marker: {marker}"

# Cloud restore compatibility: yidongwenjian must restore first, then clean staging.
yidong = src.split("- (void)yidongwenjian", 1)[1].split("#pragma mark - UICollectionViewDataSource", 1)[0]
assert yidong.index("restoreBackupTreeAtRoot:stagingRoot") < yidong.index("cleanupRestorePath:stagingRoot"), "staging cleanup must occur after restore for cloud compatibility"

# Local unzip failure must clean both staging and imported Inbox.
unzip = src.split("- (void)unzipRestoreArchiveAtPath:", 1)[1].split("- (void)handlePickedRestoreURL:", 1)[0]
assert "if (!isSuccess)" in unzip
failure = unzip.split("if (!isSuccess)", 1)[1].split("return;", 1)[0]
assert "cleanupRestorePath:stagingRoot" in failure
assert "cleanupRestorePath:inboxPath" in failure

# Successful local unzip must clean Inbox but leave staging for yidongwenjian to consume.
success_tail = unzip.rsplit("if (!isSuccess)", 1)[1]
assert "cleanupRestorePath:inboxPath" in success_tail
assert success_tail.index("cleanupRestorePath:inboxPath") < success_tail.index("[self yidongwenjian]")

assert version == "v1_p55", f"unexpected VERSION: {version}"
print("P55 restore cleanup behavior contract: PASS")
