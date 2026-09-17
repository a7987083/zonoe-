#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = '3342805ec3b6c5d11dae3974f5024a010acf98ea'  # P47 work HEAD/docs; runtime tree equals promoted P47 candidate

# Version and removed files.
assert (ROOT / 'VERSION').read_text().strip() == 'v1_p48'
assert not (ROOT / 'testmod/导入导出/fuzhu.h').exists()
assert not (ROOT / 'testmod/导入导出/fuhzu.m').exists()

# Only declared runtime/product paths may differ from P47.
out = subprocess.check_output([
    'git', '-c', 'core.quotepath=false', 'diff', '--name-only', BASE, '--',
    'testmod', 'testmod.xcodeproj', 'VERSION'
], text=True)
changed = {x.strip() for x in out.splitlines() if x.strip()}
expected = {
    'VERSION',
    'testmod/Bsphp/WX_NongShiFu123.mm',
    'testmod.xcodeproj/project.pbxproj',
    'testmod/导入导出/fuzhu.h',
    'testmod/导入导出/fuhzu.m',
}
assert changed == expected, f'unexpected P48 runtime diff: {changed ^ expected}'

# No legacy App Store checker surface may remain in canonical runtime.
banned = [
    'checkbanben',
    'checkAppStoreVersionWithAppId',
    'compareVersion:',
    'compareVersioncn:',
    'itunes.apple.com/lookup',
    'itunes.apple.com/cn/lookup',
    'App Store版本是',
    '#import "fuzhu.h"',
]
for path in (ROOT / 'testmod').rglob('*'):
    if not path.is_file() or path.suffix not in {'.h', '.m', '.mm', '.c', '.cpp'}:
        continue
    s = path.read_text(encoding='utf-8', errors='ignore')
    hits = [x for x in banned if x in s]
    assert not hits, f'{path.relative_to(ROOT)} still contains {hits}'

pbx = (ROOT / 'testmod.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
assert 'fuzhu.h' not in pbx and 'fuhzu.m' not in pbx

# PBXSources count must decrease exactly by one: fuhzu.m removed, no replacement TU.
start = pbx.index('/* Begin PBXSourcesBuildPhase section */')
end = pbx.index('/* End PBXSourcesBuildPhase section */')
phase = pbx[start:end]
source_refs = [line for line in phase.splitlines() if ' in Sources */,' in line]
assert len(source_refs) == 78, f'ACTIVE_SOURCES={len(source_refs)}, expected 78'

print('P48 App Store legacy removal contract PASS')
print('ACTIVE_SOURCES=78')
