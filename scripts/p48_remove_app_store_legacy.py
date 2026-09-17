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

# Remove exact PBX build/file/group/source/header records for fuzhu/fuhzu.
p = pbx.read_text(encoding='utf-8')
patterns = [
    r'^\s*7ECF60192E157C5E00459866 /\* fuzhu\.h in Headers \*/ = \{isa = PBXBuildFile;.*\n',
    r'^\s*7ECF60302E157C5E00459866 /\* fuhzu\.m in Sources \*/ = \{isa = PBXBuildFile;.*\n',
    r'^\s*7ECF5FE92E157C5E00459866 /\* fuzhu\.h \*/ = \{isa = PBXFileReference;.*\n',
    r'^\s*7ECF60032E157C5E00459866 /\* fuhzu\.m \*/ = \{isa = PBXFileReference;.*\n',
    r'^\s*7ECF5FE92E157C5E00459866 /\* fuzhu\.h \*/,\s*\n',
    r'^\s*7ECF60032E157C5E00459866 /\* fuhzu\.m \*/,\s*\n',
    r'^\s*7ECF60302E157C5E00459866 /\* fuhzu\.m in Sources \*/,\s*\n',
]
for pat in patterns:
    p, count = re.subn(pat, '', p, flags=re.M)
    if count not in (0, 1):
        raise SystemExit(f'unexpected PBX match count {count}: {pat}')
pbx.write_text(p, encoding='utf-8')

# Delete source/header: they contain only the removed App Store legacy category surface.
for path in (header, impl):
    if path.exists():
        path.unlink()

version.write_text('v1_p48\n', encoding='utf-8')

# Postconditions: no active legacy selector or iTunes lookup endpoint remains in canonical runtime.
for path in ROOT.joinpath('testmod').rglob('*'):
    if not path.is_file() or path.suffix not in {'.h','.m','.mm','.c','.cpp'}:
        continue
    s = path.read_text(encoding='utf-8', errors='ignore')
    banned = ['checkbanben', 'checkAppStoreVersionWithAppId', 'compareVersioncn:', 'itunes.apple.com/lookup', 'itunes.apple.com/cn/lookup']
    hits = [x for x in banned if x in s]
    if hits:
        raise SystemExit(f'banned App Store legacy remains in {path.relative_to(ROOT)}: {hits}')

pbx_text = pbx.read_text(encoding='utf-8')
if 'fuhzu.m' in pbx_text or 'fuzhu.h' in pbx_text:
    raise SystemExit('PBX still references removed fuhzu/fuzhu files')

print('P48 App Store legacy removal applied successfully')
