#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path('.')
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

AUTO_PATTERNS = {
    '+load': r'\+\s*\(\s*void\s*\)\s*load\b',
    'constructor': r'__attribute__\s*\(\(\s*constructor\s*\)\)',
    'CHConstructor': r'\bCHConstructor\b',
    '%ctor': r'%ctor\b',
    'MSHookMessageEx': r'\bMSHookMessageEx\b',
    'method_setImplementation': r'\bmethod_setImplementation\b',
    'fishhook/rebind': r'\brebind_symbols\b',
    'dlopen': r'\bdlopen\s*\(',
    'objc_getClass': r'\bobjc_getClass\s*\(',
    'NSClassFromString': r'\bNSClassFromString\s*\(',
}

VENDOR_RULES = [
    ('AFNetworking', '/Bsphp/AFNetworking/'),
    ('MBProgressHUD', '/Bsphp/MBProgressHUD/'),
    ('SCLAlertView', '/Bsphp/SCLAlertView/'),
    ('JDStatusBarNotification', '/导入导出/JDStatusBarNotification/'),
    ('SSZipArchive', '/菜单/UNZip/'),
    ('minizip', '/菜单/ZIP/minizip/'),
    ('SVProgressHUD', '/SVProgressHUD/'),
]

PROTECTED_PREFIXES = [
    'testmod/ZONBootstrap/',
    'testmod/ZONCore/',
]

PROTECTED_FILES = {
    'testmod/Bsphp/main.m': 'startup / bootstrap owner',
    'testmod/Bsphp/WX_NongShiFu123.mm': 'authorization + web UDID flow',
    'testmod/视图菜单/NSObject+UI.m': 'floating UI + stable UDID C API',
    'testmod/菜单/JHDragView.m': 'floating/menu entry',
    'testmod/菜单/PopupMenuVC.m': 'menu compatibility shell',
    'testmod/菜单/PubgLoad.mm': 'VIP cloud save',
    'testmod/菜单/SandboxBrowserVC.m': 'local file browser',
    'testmod/导入导出/daochucd.m': 'backup/export data path',
    'testmod/导入导出/fuhzu.m': 'restore/import data path',
    'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m': 'document picker path',
    'testmod/工具箱/Hook/JiangHuHook.m': 'IAP/no-ads runtime hooks',
    'testmod/工具箱/变速器/HookClass.m': 'ad-speed runtime hooks',
    'testmod/工具箱/变速器/ImgTool.m': 'runtime IAP/ad-speed state',
    'testmod/工具箱/变速器/fishhook/fishhook.c': 'runtime symbol rebind dependency',
    'testmod/工具箱/UISlider+VDTrackHeight.m': 'ad-speed slider UI support',
}

KNOWN_FEATURE_TOKENS = {
    'remote download': ['downLoad', 'download', 'remote-download'],
    'cloud save': ['PubgLoad', 'cloud-save'],
    'local files': ['SandboxBrowser', 'local-files'],
    'backup': ['daochucd', 'backup-save'],
    'restore': ['fuhzu', 'restore-save'],
    'clear game data': ['clear-game-data'],
    'clear auth': ['clear-records'],
    'iap/no-ads': ['NeiGou', 'iap-noads'],
    'ad speed': ['ADSpeed', 'ad-speed'],
}


def sh(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def tracked() -> list[str]:
    return [x for x in sh('git', '-c', 'core.quotepath=false', 'ls-files').splitlines() if x]


def read(path: str) -> str:
    try:
        return Path(path).read_text(errors='replace')
    except Exception:
        return ''


def source_inventory(files: list[str]):
    pbx = PBX.read_text(errors='replace')
    names = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    by_base: dict[str, list[str]] = defaultdict(list)
    for p in files:
        if p.startswith('testmod/'):
            by_base[Path(p).name].append(p)
    resolved, ambiguous, missing = [], {}, []
    for name in names:
        cands = by_base.get(name, [])
        if len(cands) == 1:
            resolved.append(cands[0])
        elif len(cands) > 1:
            ambiguous[name] = cands
        else:
            missing.append(name)
    return names, sorted(set(resolved)), ambiguous, missing


def imports(text: str) -> list[str]:
    vals = []
    for m in re.finditer(r'^\s*#\s*(?:import|include)\s*[<\"]([^>\"]+)[>\"]', text, re.M):
        vals.append(m.group(1))
    return vals


def auto_markers(text: str) -> list[str]:
    return [k for k, p in AUTO_PATTERNS.items() if re.search(p, text)]


def classes(text: str) -> list[str]:
    return sorted(set(re.findall(r'@(?:interface|implementation)\s+([A-Za-z_][A-Za-z0-9_]*)', text)))


def c_functions(text: str) -> list[str]:
    # Deliberately conservative: only top-level-looking function definitions.
    out = set()
    pat = re.compile(r'(?m)^\s*(?:static\s+)?(?:inline\s+)?(?:const\s+)?(?:unsigned\s+|signed\s+)?(?:void|int|long|short|float|double|BOOL|bool|char|size_t|uint\d+_t|int\d+_t|NSString\s*\*|id|CF\w+Ref)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^;\n]*\)\s*\{')
    for m in pat.finditer(text):
        out.add(m.group(1))
    return sorted(out)


def vendor_group(path: str) -> str | None:
    normalized = '/' + path
    for name, needle in VENDOR_RULES:
        if needle in normalized:
            return name
    return None


def protected_reason(path: str) -> str | None:
    if path in PROTECTED_FILES:
        return PROTECTED_FILES[path]
    if any(path.startswith(p) for p in PROTECTED_PREFIXES):
        return 'ZON architecture/runtime boundary'
    return None


def relative_import_candidates(src: str, imp: str, files_set: set[str]) -> list[str]:
    if imp.startswith(('Foundation/', 'UIKit/', 'StoreKit/', 'AVFoundation/', 'objc/', 'mach/', 'dlfcn.h', 'dispatch/', 'CommonCrypto/', 'Security/', 'MobileCoreServices/', 'UniformTypeIdentifiers/')):
        return []
    src_dir = Path(src).parent
    guesses = [
        str((src_dir / imp).as_posix()),
        'testmod/' + imp,
    ]
    base = Path(imp).name
    hits = [g for g in guesses if g in files_set]
    if hits:
        return sorted(set(hits))
    return sorted(p for p in files_set if Path(p).name == base)


def main():
    files = tracked()
    files_set = set(files)
    names, active, ambiguous, missing = source_inventory(files)
    if ambiguous or missing:
        raise SystemExit(f'PBX resolution not clean: ambiguous={ambiguous} missing={missing}')

    texts = {p: read(p) for p in active}
    active_set = set(active)

    # Map headers/imports to implementation files by basename stem where possible.
    import_edges: dict[str, set[str]] = {p: set() for p in active}
    imported_by: dict[str, set[str]] = {p: set() for p in active}
    for src, text in texts.items():
        for imp in imports(text):
            for target in relative_import_candidates(src, imp, files_set):
                stem = Path(target).stem
                # If the imported file is a header, connect to active .m/.mm/.c with the same stem.
                cands = [p for p in active if Path(p).stem == stem]
                for cand in cands:
                    if cand != src:
                        import_edges[src].add(cand)
                        imported_by[cand].add(src)

    # Broader symbol/token evidence across active sources.
    token_refs: dict[str, set[str]] = {p: set() for p in active}
    defined_tokens: dict[str, list[str]] = {}
    for path, text in texts.items():
        toks = set(classes(text) + c_functions(text) + [Path(path).stem])
        toks = {t for t in toks if len(t) >= 4 and not t.startswith('NS')}
        defined_tokens[path] = sorted(toks)
    for path, toks in defined_tokens.items():
        for other, text in texts.items():
            if other == path:
                continue
            if any(re.search(r'\b' + re.escape(t) + r'\b', text) for t in toks):
                token_refs[path].add(other)

    rows = []
    for path in active:
        text = texts[path]
        group = vendor_group(path)
        protect = protected_reason(path)
        autos = auto_markers(text)
        inbound = sorted(imported_by[path])
        refs = sorted(token_refs[path])
        feature_hits = [name for name, toks in KNOWN_FEATURE_TOKENS.items() if any(tok in text or tok in path for tok in toks)]
        if protect:
            bucket = 'KEEP_PROTECTED'
        elif autos:
            bucket = 'KEEP_RUNTIME_ENTRY'
        elif group:
            bucket = 'AUDIT_VENDOR_GROUP'
        elif inbound or refs or feature_hits:
            bucket = 'KEEP_REFERENCED'
        else:
            bucket = 'LOW_RISK_CANDIDATE'
        rows.append({
            'path': path,
            'bucket': bucket,
            'protected_reason': protect,
            'vendor_group': group,
            'auto_markers': autos,
            'direct_imported_by': inbound,
            'token_reference_files': refs,
            'feature_hits': feature_hits,
            'defined_tokens': defined_tokens[path],
        })

    # Vendor unit summary and external inbound evidence.
    vendor_summary = []
    for group, _ in VENDOR_RULES:
        members = [r for r in rows if r['vendor_group'] == group]
        if not members:
            continue
        member_paths = {r['path'] for r in members}
        inbound = set()
        token_inbound = set()
        autos = []
        for r in members:
            inbound.update(x for x in r['direct_imported_by'] if x not in member_paths)
            token_inbound.update(x for x in r['token_reference_files'] if x not in member_paths)
            if r['auto_markers']:
                autos.append({'path': r['path'], 'markers': r['auto_markers']})
        vendor_summary.append({
            'group': group,
            'source_count': len(members),
            'external_importers': sorted(inbound),
            'external_token_refs': sorted(token_inbound),
            'auto_entries': autos,
            'members': sorted(member_paths),
        })

    buckets = defaultdict(list)
    for r in rows:
        buckets[r['bucket']].append(r)

    data = {
        'head': sh('git', 'rev-parse', 'HEAD'),
        'pbx_source_entries': len(names),
        'resolved_active_sources': len(active),
        'ambiguous': ambiguous,
        'missing': missing,
        'bucket_counts': {k: len(v) for k, v in sorted(buckets.items())},
        'vendor_groups': vendor_summary,
        'rows': rows,
    }
    Path('p39-active-target-audit.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

    out = []
    out += ['# P39 Active Target Audit', '', f"- HEAD: `{data['head']}`", f"- PBX source entries: **{len(names)}**", f"- Resolved active sources: **{len(active)}**", '- Runtime/product changes: **none (audit only)**', '']
    out += ['## Bucket counts', '']
    for key in ['KEEP_PROTECTED','KEEP_RUNTIME_ENTRY','KEEP_REFERENCED','AUDIT_VENDOR_GROUP','LOW_RISK_CANDIDATE']:
        out.append(f"- {key}: **{len(buckets.get(key, []))}**")
    out.append('')

    out += ['## Low-risk deletion candidates (not deletion approval)', '']
    lows = buckets.get('LOW_RISK_CANDIDATE', [])
    if not lows:
        out.append('- none')
    else:
        for r in lows:
            toks = ', '.join(r['defined_tokens'][:8]) or '—'
            out.append(f"- `{r['path']}` — no auto-entry, no active direct importer, no active token reference; defined tokens: {toks}")
    out += ['', '> These are only candidates for second-pass semantic review. Objective-C categories, selectors built at runtime, resources and ABI symbols can still make a zero-reference source live.', '']

    out += ['## Runtime-entry / hook protected files', '']
    for r in buckets.get('KEEP_RUNTIME_ENTRY', []):
        out.append(f"- `{r['path']}` — {', '.join(r['auto_markers'])}")
    out.append('')

    out += ['## Explicit product/architecture protected files', '']
    for r in buckets.get('KEEP_PROTECTED', []):
        out.append(f"- `{r['path']}` — {r['protected_reason']}")
    out.append('')

    out += ['## Vendor/dependency units', '']
    for v in vendor_summary:
        out.append(f"### {v['group']} — {v['source_count']} active source(s)")
        out.append(f"- external direct importers: {', '.join(v['external_importers']) if v['external_importers'] else 'none detected'}")
        out.append(f"- external token refs: {', '.join(v['external_token_refs']) if v['external_token_refs'] else 'none detected'}")
        if v['auto_entries']:
            out.append('- runtime entries: ' + '; '.join(f"{x['path']} ({', '.join(x['markers'])})" for x in v['auto_entries']))
        out.append('- members: ' + ', '.join(v['members']))
        out.append('')

    out += ['## Referenced non-vendor active sources', '']
    for r in buckets.get('KEEP_REFERENCED', []):
        evidence = []
        if r['direct_imported_by']:
            evidence.append(f"imported by {len(r['direct_imported_by'])}")
        if r['token_reference_files']:
            evidence.append(f"token refs {len(r['token_reference_files'])}")
        if r['feature_hits']:
            evidence.append('feature=' + ','.join(r['feature_hits']))
        out.append(f"- `{r['path']}` — {'; '.join(evidence) or 'referenced'}")
    out += ['', '## P39 decision rule', '', '- No file is removed in this audit.', '- A LOW_RISK_CANDIDATE must pass a second semantic review before deletion: inspect exported symbols/selectors/categories/resources and compare final dylib behavior/build outputs.', '- Vendor libraries are approved/removed only as complete dependency units, never by isolated zero-reference .m files.', '- `+load`, constructors, swizzles, fishhook/rebind, `dlopen`, auth/UDID, file/cloud, IAP/no-ads and ad-speed paths are protected by default.', '']

    Path('p39-active-target-audit.md').write_text('\n'.join(out) + '\n')
    print('\n'.join(out))


if __name__ == '__main__':
    main()
