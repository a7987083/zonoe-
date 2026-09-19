from pathlib import Path

src = Path('testmod/Bsphp/WX_NongShiFu123.mm').read_text()

assert 'zon_tryOfflineAuthorizationForMode' in src
assert 'zon_hasValidOfflineAuthorizationForMode' in src
assert 'zon_activateOfflineAuthorizationForMode' in src
assert 'ZONAuthorizationRetryModeSoftwareSource' in src
assert 'ZONAuthorizationRetryModeAdSpeed' in src
assert '@"解锁码到期时间"' in src
assert '@"到期时间"' in src
assert '[localState isEqualToString:@"ok"]' in src
assert 'card.length <= 34' in src
assert 'deviceID.length <= 16' in src
assert '[expiry timeIntervalSinceNow] <= 0' in src
assert '离线模式\\n软件源授权有效' in src
assert '离线模式\\n秒过广告授权有效' in src
assert 'if ([self getNet]) return NO;' in src
assert 'if (!NET && [self zon_tryOfflineAuthorizationForMode:ZONAuthorizationRetryModeAdSpeed])' in src
assert 'if (![self getNet] && [self zon_tryOfflineAuthorizationForMode:ZONAuthorizationRetryModeSoftwareSource])' in src
print('P63 offline authorization contract: PASS')
