from pathlib import Path

p = Path('testmod/Bsphp/WX_NongShiFu123.mm')
s = p.read_text()

# getNet must remain a pure reachability check: no recursive auth entry from its offline branch.
start = s.index('- (BOOL)getNet')
end = s.index('#pragma mark --- 验证弹窗', start)
getnet = s[start:end]
assert '[self loada]' not in getnet

# Both auth modes must defer retry until the current UIAlert action dismissal finishes.
assert s.count('0.35 * NSEC_PER_SEC') >= 2
assert 'dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n                    [self BSPHP];' in s
assert 'dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n                    [self BSPHPy];' in s

# Existing user-visible failure wording and retry action are preserved.
assert s.count('@"网络连接失败"') >= 2
assert s.count('actionWithTitle:@"重新检查"') >= 2

assert Path('VERSION').read_text().strip() == 'v1_p61_1'
print('P61.1 offline retry dismissal-race contract PASS')
