#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from pathlib import Path


def sh(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()

TRACKED = [p for p in sh('git','-c','core.quotepath=false','ls-files').splitlines() if p]
SOURCE_EXTS = {'.h','.m','.mm','.c','.cc','.cpp','.hpp','.pch'}
# Reachability for product cleanup should only count the canonical testmod tree.
PRODUCT_TEXT_FILES = [p for p in TRACKED if p.startswith('testmod/') and Path(p).suffix.lower() in SOURCE_EXTS]
PBX = Path('testmod.xcodeproj/project.pbxproj').read_text(errors='replace')

GROUPS = {
    'appstore_legacy': [r'^testmod/AppStore/'],
    'empty_legacy_stubs': [r'^testmod/category/LRKeychain\.', r'^testmod/菜单/菜单UI/NSObject\+Menu\.'],
    'memory_editor': [
        r'^testmod/views/DLGMem', r'^testmod/category/UIWindow\+DLGMemUI',
        r'^testmod/category/mem(?:_utils)?\.', r'^testmod/category/search_result',
        r'^testmod/工具箱/jianghu\.', r'^testmod/JRMemory\.framework/'
    ],
    'runtime_hook_stack': [
        r'^testmod/工具箱/Hook/', r'^testmod/工具箱/变速器/',
        r'^testmod/工具箱/UISlider\+VDTrackHeight\.'
    ],
    'alternate_icon_ui': [r'^testmod/菜单/TDAlternateIconCell\.', r'^testmod/菜单/Localize\.'],
    'legacy_drag_ui': [r'^testmod/视图菜单/WMDragView\.'],
    'screenshot_shield_variants': [r'^testmod/视图菜单/HeeeNoScreenShotView\.', r'^testmod/category/TFJGVGLGKFTVCSV\.'],
}

AUTO_PATTERNS = {
    '+load': r'\+\s*\(\s*void\s*\)\s*load\b',
    'constructor': r'__attribute__\s*\(\(\s*constructor\s*\)\)',
    'CHConstructor': r'\bCHConstructor\b',
    '%ctor': r'%ctor\b',
    'MSHookMessageEx': r'\bMSHookMessageEx\b',
    'method_setImplementation': r'\bmethod_setImplementation\b',
    'fishhook': r'\brebind_symbols\b',
    'dlopen': r'\bdlopen\s*\(',
}

COMMON_METHODS = {
    'init','dealloc','layoutSubviews','addSubview','setValue','initWithFrame','initWithCoder',
    'viewDidLoad','viewDidAppear','viewWillAppear','viewWillDisappear','viewDidDisappear',
    'description','copy','mutableCopy','instance','sharedInstance','sharedManager'
}


def read(path: str) -> str:
    try:
        return Path(path).read_text(errors='replace')
    except Exception:
        return ''


def matches(path: str, pats: list[str]) -> bool:
    return any(re.search(p, path) for p in pats)


def symbols_for(paths: list[str]) -> set[str]:
    symbols: set[str] = set()
    for path in paths:
        text = read(path)
        stem = Path(path).stem
        if stem and '+' not in stem and len(stem) >= 4:
            symbols.add(stem)
        for _, cls in re.findall(r'@(interface|implementation|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)', text):
            symbols.add(cls)
        for name in re.findall(r'(?m)^\s*[-+]\s*\([^\n)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)', text):
            if len(name) >= 5 and name not in COMMON_METHODS:
                symbols.add(name)
        for name in re.findall(r'(?m)^\s*(?:static\s+)?(?:BOOL|void|int|long|float|double|NSString\s*\*|NSArray\s*\*|NSDictionary\s*\*|vector<[^>]+>)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', text):
            if len(name) >= 5:
                symbols.add(name)
    return symbols


def auto_markers(paths: list[str]):
    out = []
    for path in paths:
        text = read(path)
        marks = [name for name, pat in AUTO_PATTERNS.items() if re.search(pat, text)]
        if marks:
            out.append((path, marks))
    return out


def pbx_sources(paths: list[str]):
    out = []
    for path in paths:
        name = Path(path).name
        if f'{name} in Sources' in PBX:
            out.append(path)
    return out


def external_hits(group_paths: list[str], symbols: set[str]):
    group_set = set(group_paths)
    hits = []
    for path in PRODUCT_TEXT_FILES:
        if path in group_set:
            continue
        text = read(path)
        matched = []
        for sym in sorted(symbols):
            if re.search(r'\b' + re.escape(sym) + r'\b', text):
                matched.append(sym)
                if len(matched) >= 8:
                    break
        if matched:
            hits.append((path, matched))
    return hits


def imports_into_group(group_paths: list[str]):
    group_names = {Path(p).name for p in group_paths if Path(p).suffix.lower() in {'.h','.hpp'}}
    if not group_names:
        return []
    group_set = set(group_paths)
    hits = []
    for path in PRODUCT_TEXT_FILES:
        if path in group_set:
            continue
        text = read(path)
        names = []
        for name in group_names:
            if re.search(r'#\s*(?:import|include)\s*[<\"][^>\"]*' + re.escape(name) + r'[>\"]', text):
                names.append(name)
        if names:
            hits.append((path, sorted(names)))
    return hits


def main():
    print('# P34 Feature Reachability Audit')
    print()
    print('HEAD:', sh('git','rev-parse','HEAD'))
    print()
    for group, pats in GROUPS.items():
        paths = sorted(p for p in TRACKED if matches(p, pats))
        symbols = symbols_for(paths)
        autos = auto_markers(paths)
        sources = pbx_sources(paths)
        imports = imports_into_group(paths)
        refs = external_hits(paths, symbols)

        print(f'## {group}')
        print(f'- files: {len(paths)}')
        print(f'- PBX Sources members: {len(sources)}')
        print(f'- auto-start/hook files: {len(autos)}')
        print(f'- product import/include edges from outside group: {len(imports)}')
        print(f'- product symbol references from outside group: {len(refs)}')
        if sources:
            print('- sources:')
            for p in sources:
                print(f'  - {p}')
        if autos:
            print('- auto markers:')
            for p, marks in autos:
                print(f"  - {p}: {', '.join(marks)}")
        if imports:
            print('- product outside imports:')
            for p, names in imports[:40]:
                print(f"  - {p}: {', '.join(names)}")
        if refs:
            print('- product outside symbol refs:')
            for p, names in refs[:50]:
                print(f"  - {p}: {', '.join(names)}")
        print()

    print('## Notes')
    print('- PBX membership means code is linked, not necessarily reachable.')
    print('- Any auto-start/hook marker blocks automatic deletion until runtime behavior is explicitly retired.')
    print('- Zero product imports + zero product symbol refs + zero auto markers is a strong removal candidate, subject to successful full A/B rebuild.')


if __name__ == '__main__':
    main()
