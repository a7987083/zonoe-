from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
six = (root / 'testmod/ZONServices/ZONSixButtonActionService.m').read_text()
coord_h = (root / 'testmod/ZONServices/ZONResetCoordinator.h').read_text()
coord_m = (root / 'testmod/ZONServices/ZONResetCoordinator.m').read_text()
game_h = (root / 'testmod/ZONServices/ZONGameDataResetService.h').read_text()
game_m = (root / 'testmod/ZONServices/ZONGameDataResetService.m').read_text()
auth_h = (root / 'testmod/ZONServices/ZONAuthorizationResetService.h').read_text()
auth_m = (root / 'testmod/ZONServices/ZONAuthorizationResetService.m').read_text()
pbx = (root / 'testmod.xcodeproj/project.pbxproj').read_text()

assert version in {'v1_p72', 'v1_p73', 'v1_p74'}, f'unexpected VERSION: {version}'

for marker in [
    '@interface ZONResetCoordinator',
    '+ (instancetype)sharedCoordinator;',
    'presentClearGameDataFromViewController:',
    'presentClearAuthorizationFromViewController:',
    'resetGameDataWithoutConfirmation',
]:
    assert marker in coord_h, f'missing P72 coordinator API marker: {marker}'

for marker in [
    '#import "ZONGameDataResetService.h"',
    '#import "ZONAuthorizationResetService.h"',
    '#import "SVProgressHUD.h"',
    'UIAlertControllerStyleAlert',
    'UIAlertActionStyleDestructive',
    '@"清除游戏数据"',
    '@"此操作会清除本地游戏数据，且不可恢复。\\n确定要继续吗？"',
    '@"清除授权记录"',
    '@"此操作会删除授权信息，删除后需要重新授权。\\n确定继续吗？"',
    'QOS_CLASS_USER_INITIATED',
    '[ZONGameDataResetService resetGameDataWithProgress:',
    '正在准备清理…',
    '正在清理游戏存档…',
    '正在清理游戏数据…',
    '正在清理临时文件…',
    '正在重置本地设置…',
    '正在检查清理结果…',
    '清理完成，正在退出…',
    '[ZONAuthorizationResetService clearAuthorizationData:&error]',
    '(int64_t)(3 * NSEC_PER_SEC)',
    'exit(0);',
    'showErrorWithStatus:',
]:
    assert marker in coord_m, f'missing P72 coordinator behavior marker: {marker}'

for marker in [
    '#import "ZONResetCoordinator.h"',
    '[ZONResetCoordinator sharedCoordinator]',
    'presentClearGameDataFromViewController:hostViewController',
    'presentClearAuthorizationFromViewController:hostViewController',
    'resetGameDataWithoutConfirmation',
]:
    assert marker in six, f'missing P72 six-button route: {marker}'

for forbidden in [
    'ZONGameDataResetService',
    'ZONAuthorizationResetService',
    'SVProgressHUD',
    'UIAlertController',
    'QOS_CLASS_USER_INITIATED',
    '(3 * NSEC_PER_SEC)',
    'exit(0);',
]:
    assert forbidden not in six, f'SixButton still owns reset presentation/business: {forbidden}'

for marker in [
    'ZONGameDataResetStagePreparing', 'ZONGameDataResetStageDocuments', 'ZONGameDataResetStageLibrary',
    'ZONGameDataResetStageTemporary', 'ZONGameDataResetStagePreferences',
    'ZONGameDataResetStageVerification', 'ZONGameDataResetStageCompleted',
    'resetGameDataWithProgress:',
]:
    assert marker in game_h, f'missing game reset API marker: {marker}'

for marker in [
    '[home stringByAppendingPathComponent:@"Documents"]',
    '[home stringByAppendingPathComponent:@"Library"]',
    '[home stringByAppendingPathComponent:@"tmp"]',
    'removePersistentDomainForName:bundleIdentifier',
    'persistentDomainForName:bundleIdentifier',
    'isDirectoryEmptyAtPath:',
    'clearDirectoryContentsAtPath:',
    'directoryContainsPayloadAtPath:',
    'verifyPayloadClearedAtPath:',
]:
    assert marker in game_m, f'game reset engine drift: {marker}'

for forbidden in ['UIKit', 'SVProgressHUD', 'UIAlertController', 'dispatch_after', 'NSEC_PER_SEC']:
    assert forbidden not in game_m, f'game reset engine gained presentation/timing behavior: {forbidden}'

assert 'clearAuthorizationData:' in auth_h
for marker in ['SJUSERID', 'ShiSanGeDZKM', 'rjyyz', 'DZUDID', 'zonoe.udid.bridge.value', 'com.china.TestKeyChain']:
    assert marker in auth_m, f'authorization reset contract drift: {marker}'

assert pbx.count('ZONResetCoordinator.m in Sources') == 2
assert pbx.count('ZONGameDataResetService.m in Sources') == 2
assert pbx.count('ZONAuthorizationResetService.m in Sources') == 2

print('P72 reset presentation coordinator contract: PASS')
