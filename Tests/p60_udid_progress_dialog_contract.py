from pathlib import Path

src = Path('testmod/ZONServices/ZONUDIDBridge.m').read_text()
version = Path('VERSION').read_text().strip()

assert version == 'v1_p60', version
assert 'ZONUDIDBridgeOpenRetryDelay' not in src
assert '@"获取UDID中"' in src
assert '@"重新获取"' in src
assert '@"正在通过 Zonoe 获取设备信息，请完成操作。"' in src
assert 'presentViewController:alert animated:YES completion:launchHandler' in src
assert 'static void ZONUDIDBridgeBeginAppRequest' in src
assert 'NSString *nonce = ZONUDIDBridgeNewNonce();' in src
assert 'ZONUDIDBridgeClearPendingRequest();' in src
assert 'ZONUDIDBridgeBeginAppRequest(unavailableHandler);' in src
assert 'ZONUDIDBridgeDismissProgressAlert(nil);' in src
assert src.count('ZONUDIDBridgeDismissProgressAlert(unavailableHandler);') >= 3
assert 'if (success) return;' in src
assert 'ignoring stale zonoe open failure' in src
assert 'now - previous < 10.0' in src
assert 'ZONUDIDBridgeStart();' in src

store = src[src.index('void ZONUDIDBridgeStoreUDID'):src.index('#pragma mark - Callback URL compatibility parser')]
assert 'ZONUDIDBridgeDismissProgressAlert(nil);' in store

show = src[src.index('static void ZONUDIDBridgeShowProgressAlert'):src.index('#pragma mark - Stored value')]
assert 'actionWithTitle:@"重新获取"' in show
assert 'ZONUDIDBridgeClearPendingRequest();' in show
assert 'ZONUDIDBridgeBeginAppRequest(unavailableHandler);' in show

request = src[src.index('#pragma mark - Request'):src.index('void ZONUDIDBridgeRequestIfNeeded(void)')]
assert 'ZONUDIDBridgeShowProgressAlert' in request
assert 'openURL:requestURL' in request
assert request.index('ZONUDIDBridgeShowProgressAlert') < request.index('openURL:requestURL')

print('P60 UDID progress dialog contract: PASS')
