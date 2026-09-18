from pathlib import Path

src = Path("testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m").read_text()
version = Path("VERSION").read_text().strip()

required = [
    "prepareRestoreStagingRoot:",
    "recursivelyCopyContentsOfDirectory:",
    "return [fm copyItemAtPath:sourcePath toPath:destinationPath error:error];",
    "NSError *docError = nil;",
    "NSError *libError = nil;",
    "BOOL allSucceeded = YES;",
    "return allSucceeded;",
    "showErrorWithStatus:@\"准备恢复目录失败\"",
    "showErrorWithStatus:@\"解压失败\"",
    "showErrorWithStatus:@\"恢复失败\"",
    "showSuccessWithStatus:@\"恢复完成\"",
    "loadCustomPlistIntoUserDefaults:@\"MyCustomSettings\"",
    "seleDocumentWithDocumentTypes:@[@\"public.data\"]",
    "UIDocumentPickerModeImport",
    "__MACOSX",
    ".DS_Store",
    "Preferences",
    "[self yidongwenjian]",
]

for marker in required:
    assert marker in src, f"missing P54 behavior marker: {marker}"

assert src.count('removeItemAtPath:stagingRoot') == 1, "staging root should only be reset in local unzip preparation"
assert src.index('prepareRestoreStagingRoot:stagingRoot') < src.index('unzipFileAtPath:archivePath toDestination:stagingRoot'), "staging reset must happen before local unzip"
assert src.index('[self reloadRestoredPreferences]') < src.index('showSuccessWithStatus:@\"恢复完成\"'), "preferences must reload before success is shown"
assert version == "v1_p54", f"unexpected VERSION: {version}"

print("P54 restore reliability contract: PASS")
