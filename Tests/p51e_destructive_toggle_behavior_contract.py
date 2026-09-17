#!/usr/bin/env python3
from pathlib import Path

src = Path('testmod/ZONCore/ZONFeatureDispatcher.m').read_text(encoding='utf-8')

required = [
    'static void ZONPresentDestructiveConfirmation(',
    '@"清除游戏数据"',
    '@"此操作会清除本地游戏数据，且不可恢复。\\n确定要继续吗？"',
    '[SVProgressHUD showWithStatus:@"处理中..."]',
    'ZONClearGameDataPreservingTmp();',
    '@"清除授权记录"',
    '@"此操作会删除授权信息，删除后需要重新授权。\\n确定继续吗？"',
    '[[WX_NongShiFu123 alloc] deletekm];',
    '(int64_t)(3 * NSEC_PER_SEC)',
    '(int64_t)(5 * NSEC_PER_SEC)',
    'removePersistentDomainForName:appDomain',
    'stringByAppendingString:@"/Documents/"',
    'stringByAppendingString:@"/Library/"',
    'ZONEnsureTmpDirectory();',
    'static void ZONApplyRuntimeToggle(',
    '[defaults setInteger:on forKey:integerKey];',
    '[defaults setBool:on forKey:booleanKey];',
    '[defaults synchronize];',
    '@"NNGG", @"NNGGNNGG"',
    '[ImgTool share].NeiGou = enabled;',
    '@"AADD", @"AADDAADD"',
    '[ImgTool share].ADSpeed = enabled;',
    '@"data.clear-game-data"',
    '@"auth.clear-records"',
    '@"runtime.iap-noads"',
    '@"runtime.ad-speed"',
]
for marker in required:
    if marker not in src:
        raise SystemExit(f'missing behavior marker: {marker}')

if 'ZONPersistRuntimeToggle' in src:
    raise SystemExit('legacy duplicated toggle persistence helper still present')
if src.count('UIAlertControllerStyleAlert') != 1:
    raise SystemExit('destructive confirmation UI should be centralized to one alert constructor')
if src.count('UIAlertActionStyleDestructive') != 1:
    raise SystemExit('destructive confirmation action should be centralized')
if src.count('ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults') != 2:
    raise SystemExit('both runtime toggles must use common apply helper')
if src.count('(int64_t)(3 * NSEC_PER_SEC)') != 1:
    raise SystemExit('authorization exit delay contract drift')
if src.count('(int64_t)(5 * NSEC_PER_SEC)') != 2:
    raise SystemExit('clear-data 5-second scheduling contract drift')

print('P51E_DESTRUCTIVE_TOGGLE_BEHAVIOR_CONTRACT=PASS')
