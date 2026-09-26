#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "testmod"
PBX = ROOT / "testmod.xcodeproj" / "project.pbxproj"
OUT = ROOT / "P78_DEAD_SOURCE_AUDIT.md"

EXTS = {'.m', '.mm', '.h'}
SCAN_EXTS = {'.m', '.mm', '.h', '.c', '.cc', '.cpp', '.hpp', '.pch'}

files = sorted(p for p in SRC.rglob('*') if p.is_file() and p.suffix.lower() in EXTS)
scan_files = sorted(p for p in SRC.rglob('*') if p.is_file() and p.suffix.lower() in SCAN_EXTS)
pbx = PBX.read_text(encoding='utf-8', errors='ignore')
texts = {p: p.read_text(encoding='utf-8', errors='ignore') for p in scan_files}

source_section = ''
header_section = ''
m = re.search(r'/\* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/', pbx, re.S)
if m: source_section = m.group(1)
m = re.search(r'/\* Begin PBXHeadersBuildPhase section \*/(.*?)/\* End PBXHeadersBuildPhase section \*/', pbx, re.S)
if m: header_section = m.group(1)


def objc_classes(text):
    names = set(re.findall(r'@(?:interface|implementation)\s+([A-Za-z_][A-Za-z0-9_]*)', text))
    return sorted(names)


def method_selectors(text):
    sels = set()
    for line in text.splitlines():
        s = line.strip()
        if not (s.startswith('- (') or s.startswith('+ (')):
            continue
        # Capture Objective-C selector components: foo:bar: from declaration/definition line.
        tail = re.sub(r'^[+-]\s*\([^)]*\)\s*', '', s)
        parts = re.findall(r'([A-Za-z_][A-Za-z0-9_]*)\s*:', tail)
        if parts:
            sels.add(':'.join(parts) + ':')
        else:
            m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', tail)
            if m: sels.add(m.group(1))
    return sorted(sels)


def count_other(pattern, owner, regex=False):
    hits = []
    rx = re.compile(pattern) if regex else None
    for p, t in texts.items():
        if p == owner:
            continue
        n = len(rx.findall(t)) if regex else t.count(pattern)
        if n:
            hits.append((p, n))
    return hits

rows = []
for p in files:
    rel = p.relative_to(ROOT).as_posix()
    text = texts.get(p, '')
    name = p.name
    stem = p.stem
    in_sources = name in source_section
    in_headers = name in header_section
    is_category = '+' in name or bool(re.search(r'@interface\s+\w+\s*\(', text))
    classes = objc_classes(text)
    selectors = method_selectors(text) if p.suffix.lower() in {'.m', '.mm'} else []

    imports = []
    base_h = p.with_suffix('.h').name
    base_m = p.with_suffix('.m').name
    base_mm = p.with_suffix('.mm').name
    for target in {name, base_h, base_m, base_mm}:
        imports.extend(count_other(target, p))
    imports = sorted(set(imports), key=lambda x: x[0].as_posix())

    class_refs = []
    dynamic_refs = []
    for cls in classes:
        for q, t in texts.items():
            if q == p: continue
            # Generic class token ref.
            n = len(re.findall(r'(?<![A-Za-z0-9_])' + re.escape(cls) + r'(?![A-Za-z0-9_])', t))
            if n: class_refs.append((q, n))
            dyn = (f'NSClassFromString(@"{cls}")', f'objc_getClass("{cls}")', f'NSClassFromString(@\"{cls}\")')
            if any(x in t for x in dyn): dynamic_refs.append(q)

    selector_refs = []
    for sel in selectors:
        probes = [f'@selector({sel})', f'NSSelectorFromString(@"{sel}")', f'performSelector:@selector({sel})']
        for q, t in texts.items():
            if q == p: continue
            if any(pr in t for pr in probes): selector_refs.append(q)

    # Dedup, self header/impl pair counts as internal compatibility, not external usage.
    sibling_paths = {p.with_suffix('.h'), p.with_suffix('.m'), p.with_suffix('.mm')}
    ext_imports = [(q,n) for q,n in imports if q not in sibling_paths]
    ext_class_refs = [(q,n) for q,n in class_refs if q not in sibling_paths]
    dynamic_refs = sorted(set(q for q in dynamic_refs if q not in sibling_paths))
    selector_refs = sorted(set(q for q in selector_refs if q not in sibling_paths))

    external = bool(ext_imports or ext_class_refs or dynamic_refs or selector_refs)
    compiled = in_sources or in_headers

    if not compiled and not external and not is_category:
        status = 'SAFE_DELETE'
        reason = 'not in target; no external static/dynamic reference detected'
    elif compiled and not external and not is_category:
        status = 'REVIEW'
        reason = 'compiled/exported but no external reference detected; candidate for PBX removal test'
    elif external and not is_category:
        status = 'ACTIVE'
        reason = 'external references detected'
    else:
        status = 'REVIEW'
        reason = 'Objective-C category/implicit-load risk'

    # Tiny forwarding shells are compatibility-only candidates, not safe delete.
    if p.name in {'daochucd.m','daochucd.h','PubgLoad.mm','PubgLoad.h'}:
        status = 'COMPAT_ONLY'
        reason = 'known legacy forwarding/compatibility surface; verify runtime selector/class lookup before removal'

    rows.append({
        'rel': rel, 'size': p.stat().st_size, 'src': in_sources, 'hdr': in_headers,
        'category': is_category, 'classes': classes, 'selectors': selectors,
        'imports': ext_imports, 'class_refs': ext_class_refs,
        'dynamic': dynamic_refs, 'sel_refs': selector_refs,
        'status': status, 'reason': reason,
    })

order = {'SAFE_DELETE':0,'COMPAT_ONLY':1,'REVIEW':2,'ACTIVE':3}
rows.sort(key=lambda r:(order[r['status']], r['rel']))

counts = {k: sum(1 for r in rows if r['status']==k) for k in order}
lines = [
    '# P78 Dead Source Audit', '',
    f'- Baseline commit: `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`',
    f'- Files audited: **{len(rows)}** (`.m/.mm/.h` under `testmod/`)',
    f'- SAFE_DELETE: **{counts["SAFE_DELETE"]}**',
    f'- COMPAT_ONLY: **{counts["COMPAT_ONLY"]}**',
    f'- REVIEW: **{counts["REVIEW"]}**',
    f'- ACTIVE: **{counts["ACTIVE"]}**', '',
    '> SAFE_DELETE is a static-analysis candidate only. No runtime source is deleted by P78 audit.', '',
    '| Status | File | Bytes | Sources | Headers | External imports/class refs | Dynamic/selector refs | Reason |',
    '|---|---|---:|:---:|:---:|---:|---:|---|'
]
for r in rows:
    ext = len({q for q,_ in r['imports']} | {q for q,_ in r['class_refs']})
    dyn = len(set(r['dynamic']) | set(r['sel_refs']))
    lines.append(f'| {r["status"]} | `{r["rel"]}` | {r["size"]} | {"Y" if r["src"] else "-"} | {"Y" if r["hdr"] else "-"} | {ext} | {dyn} | {r["reason"]} |')

lines += ['', '## SAFE_DELETE details', '']
for r in rows:
    if r['status'] == 'SAFE_DELETE':
        lines.append(f'- `{r["rel"]}` ({r["size"]} bytes)')

lines += ['', '## COMPAT_ONLY details', '']
for r in rows:
    if r['status'] == 'COMPAT_ONLY':
        lines.append(f'- `{r["rel"]}` — {r["reason"]}')

OUT.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print('\n'.join(lines[:20]))
print(f'Wrote {OUT}')
