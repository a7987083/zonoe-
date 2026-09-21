#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBG = ROOT / 'testmod/菜单/PubgLoad.mm'
VERSION = ROOT / 'VERSION'

src = PUBG.read_text(encoding='utf-8')
assert VERSION.read_text(encoding='utf-8').strip() == 'v1_p67a'
assert 'P67A_POST_RESTORE_EXIT' in src
assert 'restoreArchiveAtPath:archivePath' in src
assert 'exit(0);' in src
assert src.index('P67A_POST_RESTORE_EXIT') > src.index('restoreArchiveAtPath:archivePath')
assert '[ZONRemoteDownloadService sharedService]' in src
assert '[ZONRestoreService sharedService]' in src
print('P67a post-restore exit contract passed')
