#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path('.')
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'


def sh(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def tracked_files() -> list[str]:
    return [p for p in sh('git', 'ls-files').splitlines() if p]


def file_blob(path: str) -> str:
    return sh('git', 'hash-object', path)


def relative_tree(prefix: str, files: list[str]) -> dict[str, str]:
    prefix = prefix.rstrip('/') + '/'
    out: dict[str, str] = {}
    for path in files:
        if path.startswith(prefix):
            out[path[len(prefix):]] = file_blob(path)
    return out


def source_inventory(files: list[str]):
    pbx = PBX.read_text(errors='replace')
    names = []
    for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/', pbx):
        if name not in names:
            names.append(name)

    by_base: dict[str, list[str]] = defaultdict(list)
    for path in files:
        by_base[Path(path).name].append(path)

    resolved: list[str] = []
    ambiguous: dict[str, list[str]] = {}
    missing: list[str] = []
    for name in names:
        candidates = [p for p in by_base.get(name, []) if p.startswith('testmod/')]
        if len(candidates) == 1:
            resolved.append(candidates[0])
        elif len(candidates) > 1:
            ambiguous[name] = candidates
        else:
            # New ZON sources are absolute SOURCE_ROOT refs and still live under testmod/.
            all_candidates = by_base.get(name, [])
            if len(all_candidates) == 1:
                resolved.append(all_candidates[0])
            else:
                missing.append(name)

    return names, sorted(set(resolved)), ambiguous, missing


def read_text(path: str) -> str:
    try:
        return Path(path).read_text(errors='replace')
    except Exception:
        return ''


def auto_markers(text: str) -> list[str]:
    checks = {
        '+load': r'\+\s*\(\s*void\s*\)\s*load\b',
        'constructor': r'__attribute__\s*\(\(\s*constructor\s*\)\)',
        'CHConstructor': r'\bCHConstructor\b',
        '%ctor': r'%ctor\b',
        'MSHookMessageEx': r'\bMSHookMessageEx\b',
        'method_setImplementation': r'\bmethod_setImplementation\b',
        'fishhook/rebind': r'\brebind_symbols\b',
        'dlopen': r'\bdlopen\s*\(',
    }
    return [name for name, pat in checks.items() if re.search(pat, text)]


def objc_classes(text: str) -> list[str]:
    values = set(re.findall(r'@(interface|implementation)\s+([A-Za-z_][A-Za-z0-9_]*)', text))
    return sorted({name for _, name in values})


def simple_objc_methods(text: str) -> list[str]:
    # Conservative: only no-argument selectors. These are useful for spotting old public methods
    # like loadcaidan/ycdxiaz without pretending to prove absence of dynamic invocation.
    out = set()
    for m in re.finditer(r'(?m)^\s*[-+]\s*\([^\n)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:\{|$)', text):
        out.add(m.group(1))
    return sorted(out)


def count_external_references(path: str, text: str, active_texts: dict[str, str]):
    stem = Path(path).stem
    classes = objc_classes(text)
    tokens = [stem] + classes
    refs: set[str] = set()
    for other_path, other_text in active_texts.items():
        if other_path == path:
            continue
        for token in tokens:
            if token and re.search(r'\b' + re.escape(token) + r'\b', other_text):
                refs.add(other_path)
                break
    return sorted(refs), classes


def duplicate_roots(files: list[str]):
    top_dirs = sorted({p.split('/', 1)[0] for p in files if '/' in p and not p.startswith('testmod/')})
    testmod_dirs = sorted({p.split('/', 2)[1] for p in files if p.startswith('testmod/') and p.count('/') >= 2})
    shared = sorted(set(top_dirs) & set(testmod_dirs))
    rows = []
    for name in shared:
        left = relative_tree(name, files)
        right = relative_tree(f'testmod/{name}', files)
        if left and right:
            rows.append({
                'name': name,
                'root_files': len(left),
                'testmod_files': len(right),
                'identical': left == right,
                'root_only': sorted(set(left) - set(right)),
                'testmod_only': sorted(set(right) - set(left)),
                'changed_same_path': sorted(k for k in set(left) & set(right) if left[k] != right[k]),
            })
    return rows


def suspicious_files(files: list[str]):
    patterns = [
        r'(^|/)(?:build|DerivedData)(/|$)', r'xcuserdata', r'\.xcuserstate$',
        r'\.DS_Store$', r'(?:副本|copy|backup|bak)(?:\.|_|$)', r'~$',
        r'\.(?:deb|ipa)$',
    ]
    return sorted(p for p in files if any(re.search(pat, p, re.I) for pat in patterns))


def feature_group(path: str) -> str | None:
    p = path.lower()
    if any(x in p for x in ['dlgmem', '/mem.', 'mem_utils', 'search_result', 'jrmemory', 'jianghu']):
        return 'memory/editor legacy stack'
    if any(x in p for x in ['hookclass', 'jianghuhook', '/hook/', 'fishhook', 'imgtool', 'uislider+vdtrackheight']):
        return 'runtime hook / ad-speed stack'
    if any(x in p for x in ['tdalternateiconcell', 'localize']):
        return 'alternate-icon/localization legacy UI'
    if any(x in p for x in ['someotherfile', '/appstore/']):
        return 'AppStore legacy helper'
    if any(x in p for x in ['nsobject+menu', 'wmdragview', 'heeenoscreenshot']):
        return 'legacy menu/UI stack'
    if any(x in p for x in ['afnetworking', 'mbprogresshud', 'sclalertview', 'jdstatusbarnotification', 'svprogresshud']):
        return 'third-party UI/network dependency'
    if any(x in p for x in ['ssziparchive', '/minizip/', '/zip/']):
        return 'archive/backup dependency'
    if any(x in p for x in ['daochucd', 'yyy', 'sandboxbrowser', 'otherfiles', 'nksele', 'preference']):
        return 'current data/file feature stack'
    return None


def main():
    files = tracked_files()
    source_names, active_paths, ambiguous, missing = source_inventory(files)
    active_texts = {p: read_text(p) for p in active_paths}

    active_rows = []
    for path in active_paths:
        text = active_texts[path]
        refs, classes = count_external_references(path, text, active_texts)
        methods = simple_objc_methods(text)
        method_refs = {}
        for method in methods:
            count = 0
            hit_files = []
            pat = re.compile(r'\b' + re.escape(method) + r'\b')
            for other_path, other_text in active_texts.items():
                if other_path == path:
                    continue
                hits = len(pat.findall(other_text))
                if hits:
                    count += hits
                    hit_files.append(other_path)
            if count == 0:
                method_refs[method] = []
            elif count <= 4:
                method_refs[method] = sorted(set(hit_files))
        active_rows.append({
            'path': path,
            'group': feature_group(path),
            'auto_markers': auto_markers(text),
            'classes': classes,
            'external_reference_files': refs,
            'zero_ref_simple_methods': sorted(k for k, v in method_refs.items() if not v),
        })

    duplicates = duplicate_roots(files)
    junk = suspicious_files(files)

    data = {
        'git_head': sh('git', 'rev-parse', 'HEAD'),
        'source_name_count': len(source_names),
        'active_source_count': len(active_paths),
        'ambiguous_source_names': ambiguous,
        'missing_source_names': missing,
        'duplicates': duplicates,
        'suspicious_files': junk,
        'active_sources': active_rows,
    }
    Path('p34-audit-report.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

    lines = []
    lines.append('# P34 Repository Cleanup Audit')
    lines.append('')
    lines.append(f"- HEAD: `{data['git_head']}`")
    lines.append(f"- PBX source entries: **{data['source_name_count']}**")
    lines.append(f"- Resolved active source files: **{data['active_source_count']}**")
    lines.append('')

    lines.append('## Root/testmod duplicate trees')
    lines.append('')
    for d in duplicates:
        state = 'IDENTICAL' if d['identical'] else 'DIVERGED'
        lines.append(f"- **{d['name']}** — {state}; root={d['root_files']} files, testmod={d['testmod_files']} files")
        if not d['identical']:
            if d['root_only']:
                lines.append(f"  - root-only: {', '.join(d['root_only'][:20])}")
            if d['testmod_only']:
                lines.append(f"  - testmod-only: {', '.join(d['testmod_only'][:20])}")
            if d['changed_same_path']:
                lines.append(f"  - changed: {', '.join(d['changed_same_path'][:20])}")
    lines.append('')

    lines.append('## Obvious repository-noise candidates')
    lines.append('')
    for p in junk:
        lines.append(f'- `{p}`')
    if not junk:
        lines.append('- none detected by filename rules')
    lines.append('')

    lines.append('## Active source risk inventory')
    lines.append('')
    lines.append('| source | group | auto-start/hook | other active files referencing class/stem | zero-ref simple methods |')
    lines.append('|---|---|---|---:|---|')
    for row in active_rows:
        if row['group'] or row['auto_markers'] or not row['external_reference_files'] or row['zero_ref_simple_methods']:
            auto = ', '.join(row['auto_markers']) or '—'
            group = row['group'] or '—'
            zero = ', '.join(row['zero_ref_simple_methods'][:12]) or '—'
            lines.append(f"| `{row['path']}` | {group} | {auto} | {len(row['external_reference_files'])} | {zero} |")
    lines.append('')

    lines.append('## Interpretation rule')
    lines.append('')
    lines.append('- A zero textual reference is **not deletion proof** for Objective-C runtime classes/categories or hook code.')
    lines.append('- Files with `+load`, constructor, swizzle/hook, fishhook or `dlopen` markers require runtime-specific review before removal.')
    lines.append('- Identical root/testmod trees are strong repository-cleanup candidates, but CI/scripts must be repointed before deleting any root copy used by tooling.')
    lines.append('- Product behavior is not modified by this audit.')

    Path('p34-audit-report.md').write_text('\n'.join(lines) + '\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
