#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
wx = ROOT / 'testmod/Bsphp/WX_NongShiFu123.mm'
pbx = ROOT / 'testmod.xcodeproj/project.pbxproj'
header = ROOT / 'testmod/导入导出/fuzhu.h'
impl = ROOT / 'testmod/导入导出/fuhzu.m'
version = ROOT / 'VERSION'

# Remove legacy header import and both post-activation version-check calls.
text = wx.read_text(encoding='utf-8')
text2 = re.sub(r'^#import\s+"fuzhu\.h"\s*\n', '', text, flags=re.M)
text2, n_calls = re.subn(r'^[ \t]*\[NSObject\s+checkbanben\];[ \t]*\n', '', text2, flags=re.M)
if n_calls not in (0, 2):
    raise SystemExit(f'expected 2 checkbanben calls before migration, removed={n_calls}')
wx.write_text(text2, encoding='utf-8')

# fuzhu.h / fuhzu.m are unique legacy file names. Remove every PBX line that names
# either file so build-file, file-ref, group, headers, and sources entries all vanish.
p = pbx.read_text(encoding='utf-8')
lines = p.splitlines(keepends=True)
removed = [line for line in lines if 'fuzhu.h' in line or 'fuhzu.m' in line]
if len(removed) not in (0, 7):
    raise SystemExit(f'expected 7 PBX legacy-file lines before migration, found={len(removed)}')
p = ''.join(line for line in lines if 'fuzhu.h' not in line and 'fuhzu.m' not in line)
pbx.write_text(p, encoding='utf-8')

# Delete source/header: this pair exists only for the removed App Store version-check category.
for path in (header, impl):
    if path.exists():
        path.unlink()

version.write_text('v1_p48\n', encoding='utf-8')

# Postconditions: no active legacy selector or iTunes lookup endpoint remains in canonical runtime.
banned = [
    'checkbanben',
    'checkAppStoreVersionWithAppId',
    'compareVersion:',
    'compareVersioncn:',
    'itunes.apple.com/lookup',
    'itunes.apple.com/cn/lookup',
    'App Store版本是',
]
for path in ROOT.joinpath('testmod').rglob('*'):
    if not path.is_file() or path.suffix not in {'.h', '.m', '.mm', '.c', '.cpp'}:
        continue
    s = path.read_text(encoding='utf-8', errors='ignore')
    hits = [x for x in banned if x in s]
    if hits:
        raise SystemExit(f'banned App Store legacy remains in {path.relative_to(ROOT)}: {hits}')

pbx_text = pbx.read_text(encoding='utf-8')
if 'fuhzu.m' in pbx_text or 'fuzhu.h' in pbx_text:
    raise SystemExit('PBX still references removed fuhzu/fuzhu files')

print('P48 App Store legacy removal applied successfully')
