from pathlib import Path

p = Path('testmod/Bsphp/WX_NongShiFu123.mm')
s = p.read_text()

assert 'ZONAuthorizationRetryModeSoftwareSource' in s
assert 'ZONAuthorizationRetryModeAdSpeed' in s
assert 'zon_presentAuthorizationNetworkRetry' in s
assert 'actionWithTitle:@"重新检查"' in s
assert '[self BSPHPy];' in s
assert '[self BSPHP];' in s
assert '授权初始化网络失败' in s
assert '[self loada];\n        return NO;' not in s
assert '[self zon_presentAuthorizationNetworkRetry];' in s
assert Path('VERSION').read_text().strip() == 'v1_p62'
print('P62 contract: PASS')
