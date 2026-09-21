#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
PREF = ROOT / 'testmod/导入导出/PreferenceManager.m'

src = PUBG.read_text(encoding='utf-8')
pref = PREF.read_text(encoding='utf-8')

required = [
    'P67A_RESTORE_P66_POST_SUCCESS',
    '[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]',
    'restoreArchiveAtPath:archivePath',
]
for marker in required:
    if marker not in src:
        raise SystemExit(f'missing P67a compatibility marker: {marker}')

# Preserve the existing P66/P67a behavior source of process termination.
if 'exit(0);' not in pref:
    raise SystemExit('PreferenceManager no longer contains the legacy post-restore exit behavior')

# P67a must not duplicate process termination in PubgLoad; it must reuse the P66 success tail.
if 'exit(0);' in src:
    raise SystemExit('PubgLoad contains a duplicated direct exit(0); expected PreferenceManager tail only')

print('P67a post-restore compatibility contract passed')
