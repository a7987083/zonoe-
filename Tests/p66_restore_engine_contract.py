from pathlib import Path

root = Path(__file__).resolve().parents[1]
picker = (root / "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m").read_text()
service_h = (root / "testmod/ZONServices/ZONRestoreService.h").read_text()
service_m = (root / "testmod/ZONServices/ZONRestoreService.m").read_text()
policy_m = (root / "testmod/ZONServices/ZONRestorePolicy.m").read_text()
zip_m = (root / "testmod/菜单/UNZip/SSZipArchive.m").read_text()
pbx = (root / "testmod.xcodeproj/project.pbxproj").read_text()
version = (root / "VERSION").read_text().strip()

assert version == "v1_p66", f"unexpected VERSION: {version}"

for marker in [
    "restoreArchiveAtPath:",
    "restorePreparedStagingAtPath:",
    "restoreStagingRootPath",
    "restoreInboxPathForBundleIdentifier:",
    "ZONRestoreErrorArchiveExtractFailed",
    "ZONRestoreErrorDocumentsApplyFailed",
    "ZONRestoreErrorLibraryApplyFailed",
]:
    assert marker in service_h or marker in service_m, f"missing restore-service marker: {marker}"

# Existing merge-restore behavior remains compatible while execution moves out of YYYPicker.
for marker in [
    'NSSearchPathForDirectoriesInDomains(NSDocumentDirectory',
    'NSSearchPathForDirectoriesInDomains(NSLibraryDirectory',
    'legacyFindTargetDirectory:',
    'commonBackupRootAtPath:',
    'copyItemAtPath:sourcePath toPath:destinationPath error:error',
    '[ZONRestorePolicy legacySkipItems]',
    'dispatch_queue_create("com.zonoe.restore.serial", DISPATCH_QUEUE_SERIAL)',
]:
    assert marker in service_m, f"missing compatibility/safety marker: {marker}"

for marker in ['@"__MACOSX"', '@".DS_Store"', '@"Preferences"']:
    assert marker in policy_m, f"legacy restore skip rule lost: {marker}"

# Picker is now presentation/orchestration only, while both local and cloud compatibility entries remain.
for marker in [
    '#import "ZONRestoreService.h"',
    '- (void)addBtnAction',
    '- (void)yidongwenjian',
    'seleDocumentWithDocumentTypes:@[@"public.data"]',
    'UIDocumentPickerModeImport',
    'restoreArchiveAtPath:archivePath',
    'restorePreparedStagingAtPath:stagingRoot',
    'loadCustomPlistIntoUserDefaults:@"MyCustomSettings"',
]:
    assert marker in picker, f"missing picker compatibility marker: {marker}"

for forbidden in [
    'recursivelyCopyContentsOfDirectory:',
    'restoreBackupTreeAtRoot:',
    'findTargetDir:',
    'unzipFileAtPath:archivePath toDestination:',
]:
    assert forbidden not in picker, f"restore engine leaked back into YYYPicker: {forbidden}"

# Shared unzip implementation must contain extraction within the requested destination.
for marker in [
    'blocked unsafe archive path',
    'stringByStandardizingPath',
    'destinationPrefix',
    'unsafe archive entry path',
]:
    assert marker in zip_m, f"missing Zip Slip guard marker: {marker}"

for source in ["ZONRestoreService.m", "ZONRestorePolicy.m"]:
    assert pbx.count(f"{source} in Sources") == 2, f"unexpected PBX source membership for {source}"

assert pbx.count('"$(SRCROOT)/testmod/ZONServices"') == 2, "ZONServices target header search path drifted"

print("P66 restore engine contract: PASS")
