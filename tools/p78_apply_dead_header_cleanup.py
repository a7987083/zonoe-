#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj' / 'project.pbxproj'
TARGETS = [
    ROOT / 'testmod/category/wyURLProtocol.h',
    ROOT / 'testmod/工具箱/Hook/BUPlayableAd.h',
    ROOT / 'testmod/工具箱/变速器/ZSHeader.h',
]

pbx = PBX.read_text(encoding='utf-8')
names = {p.name for p in TARGETS}

# Xcode's pbxproj entries for these three files are single-line records in the
# PBXBuildFile, PBXFileReference, PBXGroup children and PBXHeadersBuildPhase lists.
# Remove only lines naming an exact dead header; do not rewrite unrelated IDs.
lines = pbx.splitlines()
kept = [line for line in lines if not any(f'/* {name}' in line or f'path = {name};' in line for name in names)]
new_pbx = '\n'.join(kept) + '\n'

for name in names:
    if name in new_pbx:
        raise SystemExit(f'PBX cleanup incomplete for {name}')

PBX.write_text(new_pbx, encoding='utf-8')

for p in TARGETS:
    if p.exists():
        p.unlink()

for p in TARGETS:
    if p.exists():
        raise SystemExit(f'failed to remove {p.relative_to(ROOT)}')

print('P78 dead header cleanup applied:')
for p in TARGETS:
    print(f'  - {p.relative_to(ROOT)}')
