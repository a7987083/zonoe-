#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path('.')
P37_DOC_HEAD = '5f9d3844bff98314e0af109a6803a4642e685cb7'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
PAIRS = {
    'Bsphp': 'testmod/Bsphp',
    '菜单': 'testmod/菜单',
    '导入导出': 'testmod/导入导出',
    '视图菜单': 'testmod/视图菜单',
}
AUTO_PATTERNS = {
    '+load': r'\+\s*\(\s*void\s*\)\s*load\b',
    'constructor': r'__attribute__\s*\(\(\s*constructor\s*\)\)',
    'CHConstructor': r'\bCHConstructor\b',
    '%ctor': r'%ctor\b',
    'MSHookMessageEx': r'\bMSHookMessageEx\b',
    'method_setImplementation': r'\bmethod_setImplementation\b',
    'fishhook/rebind': r'\brebind_symbols\b',
    'dlopen': r'\bdlopen\s*\(',
}
TEXT_SUFFIXES = {'.h','.m','.mm','.c','.cc','.cpp','.py','.sh','.yml','.yaml','.md','.json','.plist','.pbxproj','.txt'}


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True, errors='replace').strip()


def tracked_files() -> list[str]:
    return [p for p in out('git','-c','core.quotepath=false','ls-files').splitlines() if p]


def blob(path: str) -> str:
    return out('git','hash-object',path)


def rel_tree(prefix: str, files: list[str]) -> dict[str,str]:
    base = prefix.rstrip('/') + '/'
    return {p[len(base):]: blob(p) for p in files if p.startswith(base)}


def read_text(path: str) -> str:
    try:
        return Path(path).read_text(errors='replace')
    except Exception:
        return ''


def auto_markers(path: str) -> list[str]:
    text = read_text(path)
    return [name for name, pat in AUTO_PATTERNS.items() if re.search(pat, text)]


def pbx_source_inventory(files: list[str]):
    pbx = PBX.read_text(errors='replace')
    names = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)
    by_base: dict[str,list[str]] = defaultdict(list)
    for p in files:
        by_base[Path(p).name].append(p)
    resolved, ambiguous, missing = [], {}, []
    for name in names:
        canonical = [p for p in by_base.get(name,[]) if p.startswith('testmod/')]
        if len(canonical) == 1:
            resolved.append(canonical[0])
        elif len(canonical) > 1:
            ambiguous[name] = canonical
        else:
            allc = by_base.get(name,[])
            if len(allc) == 1:
                resolved.append(allc[0])
            else:
                missing.append(name)
    return names, sorted(set(resolved)), ambiguous, missing


def grep_external_token(token: str, excluded_prefixes: tuple[str,...], files: list[str]) -> list[str]:
    hits = []
    if not token:
        return hits
    rx = re.compile(r'(?<![A-Za-z0-9_])' + re.escape(token) + r'(?![A-Za-z0-9_])')
    for p in files:
        if p.startswith(excluded_prefixes):
            continue
        if Path(p).suffix.lower() not in TEXT_SUFFIXES:
            continue
        if rx.search(read_text(p)):
            hits.append(p)
    return sorted(set(hits))


def exact_path_refs(root_name: str, files: list[str]) -> list[str]:
    needle = root_name + '/'
    hits = []
    for p in files:
        if p.startswith(root_name + '/') or p.startswith('testmod/' + root_name + '/'):
            continue
        if Path(p).suffix.lower() not in TEXT_SUFFIXES:
            continue
        if needle in read_text(p):
            hits.append(p)
    return sorted(set(hits))


def stem_tokens(path: str) -> list[str]:
    text = read_text(path)
    tokens = {Path(path).stem}
    for m in re.finditer(r'@(interface|implementation)\s+([A-Za-z_][A-Za-z0-9_]*)', text):
        tokens.add(m.group(2))
    return sorted(t for t in tokens if len(t) >= 4)


def main() -> None:
    head = out('git','rev-parse','HEAD')
    if head != P37_DOC_HEAD:
        raise SystemExit(f'expected p37 documentation head {P37_DOC_HEAD}, got {head}')
    files = tracked_files()
    source_names, active_sources, ambiguous, missing = pbx_source_inventory(files)
    root_active = [p for p in active_sources if not p.startswith('testmod/')]
    if root_active:
        raise SystemExit(f'PBX unexpectedly resolves root product sources: {root_active}')
    if ambiguous or missing:
        raise SystemExit(f'PBX resolution unsafe: ambiguous={ambiguous} missing={missing}')

    report = {
        'head': head,
        'pbx_source_entries': len(source_names),
        'active_sources': len(active_sources),
        'root_active_sources': root_active,
        'pairs': {},
    }

    for root_name, canonical in PAIRS.items():
        left = rel_tree(root_name, files)
        right = rel_tree(canonical, files)
        identical = sorted(k for k in set(left)&set(right) if left[k] == right[k])
        changed = sorted(k for k in set(left)&set(right) if left[k] != right[k])
        root_only = sorted(set(left)-set(right))
        canonical_only = sorted(set(right)-set(left))
        pair = {
            'root_files': len(left), 'canonical_files': len(right),
            'identical_count': len(identical), 'identical': identical,
            'changed': changed, 'root_only': root_only, 'canonical_only': canonical_only,
            'exact_root_path_references_outside_pair': exact_path_refs(root_name, files),
            'root_candidate_evidence': {},
        }
        for rel in root_only + changed:
            path = f'{root_name}/{rel}'
            tokens = stem_tokens(path)
            refs = set()
            for token in tokens:
                refs.update(grep_external_token(token, (root_name+'/', canonical+'/'), files))
            pair['root_candidate_evidence'][rel] = {
                'path': path,
                'auto_markers': auto_markers(path),
                'tokens': tokens,
                'external_token_reference_files': sorted(refs),
            }
        report['pairs'][root_name] = pair

    Path('p38-divergent-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    lines = ['# P38 Divergent Root Audit','',f"- HEAD: `{head}`",f"- PBX source entries: **{len(source_names)}**",f"- Resolved active sources: **{len(active_sources)}**",'- Root PBX product sources: **0**','']
    for name, pair in report['pairs'].items():
        lines += [f'## {name}', '', f"- root={pair['root_files']}, testmod={pair['canonical_files']}", f"- identical={pair['identical_count']}", f"- changed={len(pair['changed'])}: {', '.join(pair['changed']) or 'none'}", f"- root-only={len(pair['root_only'])}: {', '.join(pair['root_only']) or 'none'}", f"- testmod-only={len(pair['canonical_only'])}: {', '.join(pair['canonical_only']) or 'none'}", f"- exact `{name}/` references outside pair: {', '.join(pair['exact_root_path_references_outside_pair']) or 'none'}", '']
        candidates = pair['root_candidate_evidence']
        if candidates:
            lines += ['| root candidate | auto/hook markers | external token refs |','|---|---|---|']
            for rel, ev in candidates.items():
                lines.append(f"| `{ev['path']}` | {', '.join(ev['auto_markers']) or '—'} | {', '.join(ev['external_token_reference_files']) or '—'} |")
            lines.append('')
    lines += ['## Guard','', '- No deletion is performed by this audit.', '- A root copy can only be removed in the cleanup phase if PBX does not own it, no external exact root-path reference exists, and any changed/root-only file is reviewed for runtime auto-start/hook behavior and external symbol references.','']
    Path('p38-divergent-audit.md').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines))

if __name__ == '__main__':
    main()
