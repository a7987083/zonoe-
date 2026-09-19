from pathlib import Path

p = Path('testmod/Bsphp/WX_NongShiFu123.mm')
s = p.read_text()

assert 'zon_validOfflineAuthorizationMode' in s
assert 'ZONAuthorizationRetryModeSoftwareSource' in s
assert 'ZONAuthorizationRetryModeAdSpeed' in s
assert '解锁码到期时间' in s
assert '到期时间' in s
assert 'offlineMode != ZONAuthorizationRetryModeUnknown' in s
assert '[self zon_activateOfflineAuthorizationForMode:offlineMode];' in s
assert '[self getNet]' in s
print('P64 offline authorization preroute contract PASS')
