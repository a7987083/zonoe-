from pathlib import Path

p = Path('testmod/菜单/PubgLoad.mm')
s = p.read_text()

insert_marker = '''-(void)yuanchengdwon\n{'''
helpers = r'''- (NSURLSession *)zonoeArchiveDownloadSession
{
    return [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:self
                                       delegateQueue:[NSOperationQueue mainQueue]];
}

- (void)startArchiveDownloadWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    NSURLSessionDownloadTask *task = [[self zonoeArchiveDownloadSession] downloadTaskWithURL:url];
    [task resume];
}

- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code
                                    msg:(NSString *)msg
                                 expire:(NSNumber *)expire
                               testMode:(BOOL)testMode
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return testMode || (code && [code intValue] == 1 &&
                        msg && [msg isEqualToString:@"ok"] &&
                        expire && [expire doubleValue] > now);
}

'''
if helpers not in s:
    if s.count(insert_marker) != 1:
        raise SystemExit('P51-D insert marker mismatch')
    s = s.replace(insert_marker, helpers + insert_marker, 1)

manual_old = '''         NSURL *url = [NSURL URLWithString:远程下载地址];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        // 2、利用NSURLSessionDownloadTask创建任务(task)
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
        // 3、执行任务
        [task resume];'''
manual_new = '''         NSURL *url = [NSURL URLWithString:远程下载地址];
        [self startArchiveDownloadWithURL:url];'''
if manual_old in s:
    s = s.replace(manual_old, manual_new, 1)
elif manual_new not in s:
    raise SystemExit('P51-D manual download block mismatch')

cloud_old = '''            NSURLSession *session =
            [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                          delegate:self
                                     delegateQueue:[NSOperationQueue mainQueue]];
            
            NSURLSessionDownloadTask *task =
            [session downloadTaskWithURL:downloadURL];
            
            [task resume];'''
cloud_new = '''            [self startArchiveDownloadWithURL:downloadURL];'''
if cloud_old in s:
    s = s.replace(cloud_old, cloud_new, 1)
elif cloud_new not in s:
    raise SystemExit('P51-D cloud download block mismatch')

entitlement_old = '''        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

        if (testMode || (code && [code intValue] == 1 &&
                         msg && [msg isEqualToString:@"ok"] &&
                         expire && [expire doubleValue] > now)) {'''
entitlement_new = '''        BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）

        if ([self isCloudEntitlementValidWithCode:code
                                              msg:msg
                                           expire:expire
                                         testMode:testMode]) {'''
if entitlement_old in s:
    s = s.replace(entitlement_old, entitlement_new, 1)
elif entitlement_new not in s:
    raise SystemExit('P51-D entitlement block mismatch')

required = [
    '- (NSURLSession *)zonoeArchiveDownloadSession',
    '- (void)startArchiveDownloadWithURL:(NSURL *)url',
    '- (BOOL)isCloudEntitlementValidWithCode:(NSNumber *)code',
    '[self startArchiveDownloadWithURL:url];',
    '[self startArchiveDownloadWithURL:downloadURL];',
    '[self isCloudEntitlementValidWithCode:code',
    'BOOL testMode = NO; // NO = 正常验证, YES = 测试模式（绕过验证）',
]
for marker in required:
    if marker not in s:
        raise SystemExit(f'missing expected P51-D marker: {marker}')

p.write_text(s)
print('P51D_PUBGLOAD_REFACTOR=APPLIED')
