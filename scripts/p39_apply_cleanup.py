#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from pathlib import Path

BASELINE_HEAD = 'f8ff5d72483d63b2d8a1216e012a5922978db19a'
P38_SOURCE = '43c632d4ce6d04e51f9c8cc033292f9d98b134ff'
CANDIDATES = [
    'testmod/category/NSString+Tools.m',
    'testmod/category/NSString+Tools.h',
]
ACTIVE_FEATURE_IDS = [
    'base.remote-download','base.cloud-save','base.local-files',
    'data.backup-save','data.restore-save','data.clear-game-data',
    'auth.clear-records','runtime.iap-noads','runtime.ad-speed',
]


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True, errors='replace').strip()


def run(*args: str) -> None:
    subprocess.check_call(args)


def tree(ref: str, path: str) -> str:
    return out('git', 'rev-parse', f'{ref}:{path}')


def source_names(pbx: str) -> list[str]:
    names = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    return names


def main() -> None:
    head = out('git', 'rev-parse', 'HEAD')
    if head != BASELINE_HEAD:
        raise SystemExit(f'expected p39 audit baseline {BASELINE_HEAD}, got {head}')
    if Path('VERSION').read_text().strip() != 'v1_p38':
        raise SystemExit('expected v1_p38 before p39 cleanup')
    if tree('HEAD', 'testmod') != tree(P38_SOURCE, 'testmod'):
        raise SystemExit('testmod runtime tree drifted from device-verified p38')
    if tree('HEAD', 'testmod.xcodeproj') != tree(P38_SOURCE, 'testmod.xcodeproj'):
        raise SystemExit('Xcode project drifted from device-verified p38')

    for path in CANDIDATES:
        if not Path(path).is_file():
            raise SystemExit(f'candidate missing before cleanup: {path}')

    pbx_path = Path('testmod.xcodeproj/project.pbxproj')
    pbx = pbx_path.read_text(errors='replace')
    before_sources = source_names(pbx)
    if len(before_sources) != 76:
        raise SystemExit(f'expected 76 PBX source entries before cleanup, got {len(before_sources)}')
    if 'NSString+Tools.m' not in before_sources:
        raise SystemExit('NSString+Tools.m is not an active PBX source')
    if 'NSString+Tools.h' not in pbx:
        raise SystemExit('NSString+Tools.h PBX reference missing before cleanup')

    # Remove all PBX lines owned by these two files. Xcode stores each relevant build,
    # file-reference, group-child and build-phase record on a line carrying the filename comment.
    lines = pbx.splitlines(keepends=True)
    kept = [line for line in lines if 'NSString+Tools.m' not in line and 'NSString+Tools.h' not in line]
    if len(kept) == len(lines):
        raise SystemExit('no PBX lines removed')
    pbx_path.write_text(''.join(kept))

    run('git', 'rm', '--', *CANDIDATES)
    Path('VERSION').write_text('v1_p39\n')

    pbx_after = pbx_path.read_text(errors='replace')
    after_sources = source_names(pbx_after)
    if len(after_sources) != 75:
        raise SystemExit(f'expected 75 PBX source entries after cleanup, got {len(after_sources)}')
    if 'NSString+Tools.m' in pbx_after or 'NSString+Tools.h' in pbx_after:
        raise SystemExit('stale NSString+Tools PBX reference remains')

    # Product source changes relative to p38 are intentionally limited to this single retired category.
    changed = set(out('git', 'diff', '--name-only', P38_SOURCE, '--', 'testmod', 'testmod.xcodeproj').splitlines())
    allowed = set(CANDIDATES + ['testmod.xcodeproj/project.pbxproj'])
    if changed != allowed:
        raise SystemExit(f'unexpected product-source diff vs p38: {sorted(changed)}')

    registry = Path('testmod/ZONCore/ZONFeatureRegistry.m').read_text()
    for ident in ACTIVE_FEATURE_IDS:
        if f'@"{ident}"' not in registry:
            raise SystemExit(f'active feature missing: {ident}')
    if 'runtime.placeholder-203' in registry:
        raise SystemExit('retired placeholder 203 reappeared')

    bridge = Path('testmod/ZONServices/ZONUDIDBridge.h').read_text()
    ui = Path('testmod/视图菜单/NSObject+UI.m').read_text()
    for marker in ['ZONUDIDBridgeRequestIfNeededWithUnavailableHandler', 'unable to open zonoe://udid; using web fallback']:
        if marker not in bridge:
            raise SystemExit(f'UDID bridge marker missing: {marker}')
    for marker in ['ZonoeStartLegacyWebUDIDFallback', 'ZONUDIDBridgeStoreUDID(udid);']:
        if marker not in ui:
            raise SystemExit(f'UDID fallback wiring missing: {marker}')

    run('git', 'diff', '--check')
    print('p39 NSString+Tools cleanup: PASS')


if __name__ == '__main__':
    main()
