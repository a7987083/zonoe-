from pathlib import Path

p = Path('testmod/ZONServices/ZONAuthorizationCoordinator.m')
s = p.read_text()

# Stage/version identity.
assert Path('VERSION').read_text().strip() == 'v1_p65'

# P62 externally observable authorization semantics remain present.
required = [
    'method_setImplementation(method, (IMP)ZONDeleteKMAndUDID)',
    'ZONLaunchTraceAuthorizationEnter',
    'ZONLaunchTraceAuthorizationExistingDZUDID',
    'ZONLaunchTraceAuthorizationBridgeCache',
    'ZONLaunchTraceAuthorizationAwaitUDID',
    'ZONLaunchTraceAuthorizationUDIDCallback',
    'ZONLaunchTraceAuthorizationContinue',
    'ZonoeCurrentUDID()',
    'ZonoeSetUDIDCallback',
    'ZonoeRequestUDIDIfNeeded()',
    '[auth loada];',
    '正在获取设备 UDID...',
    'UDID 写入失败\\n请重新启动后再试',
    'UDID 获取成功\\n%@\\n已写入 DZUDID\\n正在继续授权',
]
for marker in required:
    assert marker in s, marker

# Persistence keys are centralized but unchanged from P62.
key_literals = [
    'DZUDID',
    'zonoe.udid.bridge.value',
    'zonoe.udid.bridge.scheme',
    'zonoe.udid.bridge.requestTimestamp',
    'zonoe.udid.bridge.requestNonce',
]
for key in key_literals:
    assert f'@"{key}"' in s, key

# The refactor must keep exactly one write path and one keychain clear path.
assert s.count('[getKeychain addKeychainData:') == 1
assert s.count('[getKeychain removeKeychainDataForKey:') == 1

# New ownership helpers must exist and be used by both existing/callback paths.
for helper in [
    'ZONAuthorizationUDIDIsValid',
    'ZONReadStoredAuthorizationUDID',
    'ZONPersistAndVerifyAuthorizationUDID',
]:
    assert helper in s, helper

# Guard against accidental reintroduction of raw DZUDID keychain access outside
# the centralized constant/helper path.
assert '[getKeychain getKeychainDataForKey:@"DZUDID"]' not in s
assert '[getKeychain addKeychainData:udid forKey:@"DZUDID"]' not in s
assert '[getKeychain removeKeychainDataForKey:@"DZUDID"]' not in s

print('P65 P62 maintainability contract: PASS')
