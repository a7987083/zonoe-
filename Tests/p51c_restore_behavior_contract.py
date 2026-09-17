from pathlib import Path

p = Path('testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m')
s = p.read_text(encoding='utf-8')

required = [
    '- (void)addBtnAction',
    '@[@"public.data"]',
    'UIDocumentPickerModeImport',
    '(int64_t)(1 * NSEC_PER_SEC)',
    '- (void)handlePickedRestoreURL:(NSURL *)fileUrl',
    '- (NSString *)restoreInboxPathForBundleIdentifier:',
    '@"/tmp/"',
    '@"%@%@-Inbox"',
    '- (NSString *)restoreStagingRootPath',
    '@"tmp/zonoe"',
    '- (void)unzipRestoreArchiveAtPath:',
    '[SSZipArchive unzipFileAtPath:archivePath toDestination:stagingRoot]',
    'removeItemAtPath:inboxPath error:nil',
    '[self yidongwenjian]',
    '- (NSString *)fixedName:(NSString *)name',
    '- (NSString *)findTargetDir:(NSString *)target inRoot:(NSString *)root',
    '[item hasPrefix:@"."]',
    '[item isEqualToString:@"__MACOSX"]',
    '- (BOOL)restoreBackupTreeAtRoot:(NSString *)root',
    '[self findTargetDir:@"Documents" inRoot:root]',
    '[self findTargetDir:@"Library" inRoot:root]',
    '@"__MACOSX", @".DS_Store", @"Preferences"',
    'NSDocumentDirectory',
    'NSLibraryDirectory',
    '+ (void)recursivelyCopyContentsOfDirectory:',
    'if (dstExists && (srcIsDir != dstIsDir))',
    '- (void)yidongwenjian',
    '[self restoreBackupTreeAtRoot:[self restoreStagingRootPath]]',
    '- (void)reloadRestoredPreferences',
    '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]',
]

missing = [item for item in required if item not in s]
if missing:
    raise SystemExit('missing restore contract markers: ' + repr(missing))

# Picker must delegate picked URL handling rather than own unzip/copy logic.
start = s.index('- (void)addBtnAction')
end = s.index('- (void)yidongwenjian', start)
entry = s[start:end]
if '[self handlePickedRestoreURL:urls.firstObject]' not in entry:
    raise SystemExit('restore picker does not delegate to handlePickedRestoreURL')
if 'unzipFileAtPath' in entry:
    raise SystemExit('restore picker still owns unzip logic')

# Keep the compatibility entry thin and preserve reload ordering.
y_start = s.index('- (void)yidongwenjian')
y_end = s.index('#pragma mark - UICollectionViewDataSource', y_start)
y = s[y_start:y_end]
if y.count('restoreBackupTreeAtRoot') != 1:
    raise SystemExit('compatibility restore entry must call restoreBackupTreeAtRoot exactly once')
if y.count('reloadRestoredPreferences') != 1:
    raise SystemExit('compatibility restore entry must reload preferences exactly once')

# Skip-list semantics must stay centralized and exact.
if s.count('@"__MACOSX", @".DS_Store", @"Preferences"') != 1:
    raise SystemExit('restore skip list must be centralized exactly once')

# Version is a candidate bookkeeping marker, not a behavior gate.
version = Path('VERSION').read_text(encoding='utf-8').strip()
if version != 'v1_p51c':
    raise SystemExit(f'unexpected VERSION: {version}')

print('P51C_RESTORE_BEHAVIOR_CONTRACT=PASS')
