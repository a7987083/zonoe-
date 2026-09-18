from pathlib import Path

src = Path("testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m").read_text()
version = Path("VERSION").read_text().strip()

required = [
    # P54 inherited restore reliability guarantees
    "prepareRestoreStagingRoot:",
    "recursivelyCopyContentsOfDirectory:",
    "return [fm copyItemAtPath:sourcePath toPath:destinationPath error:error];",
    "NSError *docError = nil;",
    "NSError *libError = nil;",
    "BOOL allSucceeded = YES;",
    "return allSucceeded;",
    'showErrorWithStatus:@"准备恢复目录失败"',
    "[self reloadRestoredPreferences]",
    'seleDocumentWithDocumentTypes:@[@"public.data"]',
    "UIDocumentPickerModeImport",
    '@"__MACOSX"',
    '@".DS_Store"',
    '@"Preferences"',
    "[self yidongwenjian]",

    # P55 cleanup lifecycle guarantees
    "cleanupRestorePath:",
    "unzipRestoreArchiveAtPath:",
    "restoreBackupTreeAtRoot:",
    "restoreStagingRootPath",
    "restoreInboxPathForBundleIdentifier:",
    'showErrorWithStatus:stagingCleaned ? @"解压失败" : @"解压失败，临时文件清理失败"',
    'showErrorWithStatus:stagingCleaned ? @"恢复失败" : @"恢复失败，临时文件清理失败"',
    'showSuccessWithStatus:stagingCleaned ? @"恢复完成" : @"恢复完成，但临时文件清理失败"',
    "[self cleanupRestorePath:stagingRoot]",
    "[self cleanupRestorePath:inboxPath]",
]

for marker in required:
    assert marker in src, f"missing behavior marker: {marker}"

# Local staging must still be prepared before unzip.
unzip = src.split("- (void)unzipRestoreArchiveAtPath:", 1)[1].split("- (void)handlePickedRestoreURL:", 1)[0]
assert unzip.index("prepareRestoreStagingRoot:stagingRoot") < unzip.index("unzipFileAtPath:archivePath toDestination:stagingRoot"), "staging preparation must happen before local unzip"

# Local unzip failure must clean both staging and imported Inbox before returning.
assert "if (!isSuccess)" in unzip
failure = unzip.split("if (!isSuccess)", 1)[1].split("return;", 1)[0]
assert "cleanupRestorePath:stagingRoot" in failure
assert "cleanupRestorePath:inboxPath" in failure

# Successful local unzip must clean Inbox first, then consume staging via yidongwenjian.
success_tail = unzip.rsplit("if (!isSuccess)", 1)[1]
assert "cleanupRestorePath:inboxPath" in success_tail
assert success_tail.index("cleanupRestorePath:inboxPath") < success_tail.index("[self yidongwenjian]")

# Cloud/local shared restore compatibility: restore first, cleanup staging only after copy completes.
yidong = src.split("- (void)yidongwenjian", 1)[1].split("#pragma mark - UICollectionViewDataSource", 1)[0]
assert yidong.index("restoreBackupTreeAtRoot:stagingRoot") < yidong.index("cleanupRestorePath:stagingRoot"), "staging cleanup must occur after restore for cloud compatibility"
assert yidong.index("cleanupRestorePath:stagingRoot") < yidong.index("dispatch_async(dispatch_get_main_queue()"), "cleanup must finish before final success/failure UI"
assert yidong.index("[self reloadRestoredPreferences]") < yidong.index('showSuccessWithStatus:stagingCleaned ? @"恢复完成"'), "preferences must reload before success is shown"

assert version == "v1_p55", f"unexpected VERSION: {version}"
print("P55 restore cleanup behavior contract: PASS")
