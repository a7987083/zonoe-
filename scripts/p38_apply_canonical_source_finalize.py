#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from collections import defaultdict
from pathlib import Path

P37_DOC_HEAD = '5f9d3844bff98314e0af109a6803a4642e685cb7'
P36_RUNTIME = 'c85a6a235daf3287b70c13fbe69be455a3aecce2'
ROOT_MIRRORS = ['Bsphp', '菜单', '导入导出', '视图菜单']
ACTIVE_FEATURE_IDS = [
    'base.remote-download','base.cloud-save','base.local-files',
    'data.backup-save','data.restore-save','data.clear-game-data',
    'auth.clear-records','runtime.iap-noads','runtime.ad-speed',
]


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True, errors='replace').strip()


def run(*args: str) -> None:
    subprocess.check_call(args)


def tracked_files() -> list[str]:
    return [p for p in out('git','-c','core.quotepath=false','ls-files').splitlines() if p]


def blob(path: str) -> str:
    return out('git','hash-object',path)


def rel_tree(prefix: str, files: list[str]) -> dict[str,str]:
    base = prefix.rstrip('/') + '/'
    return {p[len(base):]: blob(p) for p in files if p.startswith(base)}


def tree_sha(ref: str, path: str) -> str:
    return out('git','rev-parse',f'{ref}:{path}')


def pbx_sources(files: list[str]) -> list[str]:
    pbx = Path('testmod.xcodeproj/project.pbxproj').read_text(errors='replace')
    names=[]
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    by_base: dict[str,list[str]] = defaultdict(list)
    for p in files:
        by_base[Path(p).name].append(p)
    resolved=[]
    for name in names:
        canonical=[p for p in by_base.get(name,[]) if p.startswith('testmod/')]
        if len(canonical) != 1:
            raise SystemExit(f'unsafe PBX source resolution for {name}: {canonical}')
        resolved.append(canonical[0])
    return sorted(set(resolved))


def main() -> None:
    head=out('git','rev-parse','HEAD')
    if head != P37_DOC_HEAD:
        raise SystemExit(f'expected p37 documentation head {P37_DOC_HEAD}, got {head}')

    files=tracked_files()
    active=pbx_sources(files)
    if len(active) != 76:
        raise SystemExit(f'expected 76 active PBX sources, got {len(active)}')
    if any(not p.startswith('testmod/') for p in active):
        raise SystemExit('root source unexpectedly active in PBX')

    # Product runtime and project must start exactly from the p36/p37 runtime tree.
    if tree_sha('HEAD','testmod') != tree_sha(P36_RUNTIME,'testmod'):
        raise SystemExit('testmod tree diverged before p38 cleanup')
    if tree_sha('HEAD','testmod.xcodeproj') != tree_sha(P36_RUNTIME,'testmod.xcodeproj'):
        raise SystemExit('Xcode project diverged before p38 cleanup')

    # Every remaining root mirror is a strict subset/same-path mirror: no unique root file may be lost.
    for root in ROOT_MIRRORS:
        canonical=f'testmod/{root}'
        left=rel_tree(root,files)
        right=rel_tree(canonical,files)
        if not left:
            raise SystemExit(f'expected root mirror missing: {root}')
        if not right:
            raise SystemExit(f'canonical tree missing: {canonical}')
        root_only=sorted(set(left)-set(right))
        if root_only:
            raise SystemExit(f'refusing to delete unique root files in {root}: {root_only}')
        changed=sorted(k for k in set(left)&set(right) if left[k] != right[k])
        identical=sorted(k for k in set(left)&set(right) if left[k] == right[k])
        print(f'{root}: root={len(left)} canonical={len(right)} identical={len(identical)} changed_old_copies={len(changed)} root_only=0')

    for root in ROOT_MIRRORS:
        run('git','rm','-r','--',root)

    Path('VERSION').write_text('v1_p38\n')

    # Cleanup must not modify the canonical runtime or project.
    if tree_sha('HEAD','testmod') != tree_sha(P36_RUNTIME,'testmod'):
        raise SystemExit('p38 changed canonical runtime tree')
    if tree_sha('HEAD','testmod.xcodeproj') != tree_sha(P36_RUNTIME,'testmod.xcodeproj'):
        raise SystemExit('p38 changed Xcode project')

    registry=Path('testmod/ZONCore/ZONFeatureRegistry.m').read_text()
    for ident in ACTIVE_FEATURE_IDS:
        if f'@"{ident}"' not in registry:
            raise SystemExit(f'active feature missing: {ident}')
    if 'runtime.placeholder-203' in registry:
        raise SystemExit('retired placeholder 203 reappeared')

    bridge=Path('testmod/ZONServices/ZONUDIDBridge.h').read_text()
    ui=Path('testmod/视图菜单/NSObject+UI.m').read_text()
    for marker in ['ZONUDIDBridgeRequestIfNeededWithUnavailableHandler','unable to open zonoe://udid; using web fallback']:
        if marker not in bridge:
            raise SystemExit(f'UDID fallback marker missing: {marker}')
    for marker in ['ZonoeStartLegacyWebUDIDFallback','ZONUDIDBridgeStoreUDID(udid);']:
        if marker not in ui:
            raise SystemExit(f'UDID fallback wiring missing: {marker}')

    for root in ROOT_MIRRORS:
        if Path(root).exists():
            raise SystemExit(f'root mirror still exists: {root}')
        if not Path(f'testmod/{root}').exists():
            raise SystemExit(f'canonical tree damaged: testmod/{root}')

    run('git','diff','--check')
    print('p38 canonical source finalization: PASS')

if __name__ == '__main__':
    main()
