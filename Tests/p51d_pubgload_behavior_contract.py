from pathlib import Path

p = Path('testmod/菜单/PubgLoad.mm')
s = p.read_text()
pbx = Path('testmod.xcodeproj/project.pbxproj').read_text()

required = [
    '- (NSURLSession *)zonoeArchiveDownloadSession',
    '- (void)startArchiveDownloadWithURL:(NSURL *)url',
    '- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code',
    '[self startArchiveDownloadWithURL:url];',
    '[self startArchiveDownloadWithURL:downloadURL];',
    '[self isCloudEntitlementValidWithCode:code',
    'BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）',
    'https://app.zonoeios.xyz/index/index/apiface?udid=%@',
    'getKeychainDataForKey:@"DZUDID"',
    '[NSString stringWithFormat:@"%@%@.json", homeurl, bundleID]',
    '[NSString stringWithFormat:@"%@%@.zip", homezip, bundleID]',
    'downloadAddress == nil',
    'downloadAddress.length == 0',
    'downloadURLString = downloadAddress;',
    'stringByAddingPercentEncodingWithAllowedCharacters',
    '- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location',
    '[SSZipArchive unzipFileAtPath:savePath',
    'stringByAppendingPathComponent:@"tmp/zonoe/"',
    '[[YYYPicker alloc] yidongwenjian];',
    '- (void)cleanupTemporaryFiles',
    'presentWithText:@"准备下载存档,请稍后."',
    'presentWithText:@"正在加载存档，请稍等..."',
]
for marker in required:
    if marker not in s:
        raise SystemExit(f'missing P51-D behavior marker: {marker}')

# Both live download entry paths must use the shared task helper.
if s.count('[self startArchiveDownloadWithURL:') != 2:
    raise SystemExit('expected exactly two shared archive-download call sites')

# Direct task creation should now live only inside the helper; legacy loadddd is excluded
# from this strict count because it is dormant compatibility code.
helper_start = s.index('- (void)startArchiveDownloadWithURL:(NSURL *)url')
helper_end = s.index('- (BOOL)isCloudEntitlementValidWithCode:', helper_start)
helper = s[helper_start:helper_end]
if helper.count('downloadTaskWithURL:url') != 1 or helper.count('[task resume]') != 1:
    raise SystemExit('shared archive download helper contract mismatch')

# Purchase semantics remain exactly code=1, msg=ok, non-expired, or testMode.
ent_start = s.index('- (BOOL)isCloudEntitlementValidWithCode:')
ent_end = s.index('-(void)yuanchengdwon', ent_start)
ent = s[ent_start:ent_end]
for marker in ['[code intValue] == 1', '[msg isEqualToString:@"ok"]', '[expire doubleValue] > now', 'testMode ||']:
    if marker not in ent:
        raise SystemExit(f'entitlement semantics drift: {marker}')

count = pbx.count(' in Sources */,' )
print(f'ACTIVE_SOURCES={count}')
if count != 78:
    raise SystemExit(f'active source count drift: {count}')

print('P51D_PUBGLOAD_BEHAVIOR_CONTRACT=PASS')
