#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from pathlib import Path


def sh(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()

TRACKED = [p for p in sh('git','-c','core.quotepath=false','ls-files').splitlines() if p]
TEXT_EXTS = {'.h','.m','.mm','.c','.cc','.cpp','.hpp','.pch'}
PRODUCT = [p for p in TRACKED if p.startswith('testmod/') and Path(p).suffix.lower() in TEXT_EXTS]

CANDIDATES = {
    'jianghu': [r'\bjianghu\b', r'jianghu\.h'],
    'DLGMem': [r'\bDLGMem(?:UI|UIView|UIViewCell)?\b', r'DLGMem'],
    'MemScan': [r'MemScan\.h', r'\bJJMemoryEngine\b'],
    'JRMemory': [r'JRMemory'],
    'lz4': [r'lz4\.h', r'\bLZ4_[A-Za-z0-9_]+\b'],
    'SomeOtherFile': [r'\bSomeOtherFile\b', r'userClickedPromoteButton'],
    'AlternateIcon': [r'\bTDAlternateIconCell\b', r'\bLocalize\b'],
    'WMDragView': [r'\bWMDragView\b'],
    'ScreenshotShield': [r'\bHeeeNoScreenShotView\b', r'\bTFJGVGLGKFTVCSV\b'],
    'LRKeychain': [r'\bLRKeychain\b'],
    'NSObjectPlist': [r'NSObject\+Plist'],
    'NSObjectMenu': [r'NSObject\+Menu', r'\bvipyuncundang\b', r'\bloadadadd\b'],
    'AESUtility': [r'\bAESUtility\b'],
}


def read(path: str) -> str:
    try:
        return Path(path).read_text(errors='replace')
    except Exception:
        return ''


def strip_comments(text: str) -> str:
    # Good enough for audit: preserve newlines so reported line numbers remain useful.
    def block(m: re.Match) -> str:
        return '\n' * m.group(0).count('\n')
    text = re.sub(r'/\*.*?\*/', block, text, flags=re.S)
    text = re.sub(r'//[^\n]*', '', text)
    return text


def own_group(name: str, path: str) -> bool:
    p = path
    if name == 'jianghu': return p in {'testmod/工具箱/jianghu.h','testmod/工具箱/jianghu.mm'}
    if name == 'DLGMem': return ('/DLGMem' in p or 'UIWindow+DLGMemUI' in p or '/mem.' in p or '/mem_utils.' in p or '/search_result' in p)
    if name == 'MemScan': return p == 'testmod/工具箱/MemScan.h' or p.endswith('/jianghu.mm')
    if name == 'JRMemory': return p.startswith('testmod/JRMemory.framework/')
    if name == 'lz4': return p.endswith('/lz4.h') or p.endswith('/lz4.c')
    if name == 'SomeOtherFile': return p.startswith('testmod/AppStore/SomeOtherFile.')
    if name == 'AlternateIcon': return p.endswith('/TDAlternateIconCell.h') or p.endswith('/TDAlternateIconCell.m') or p.endswith('/Localize.h') or p.endswith('/Localize.m')
    if name == 'WMDragView': return p.endswith('/WMDragView.h') or p.endswith('/WMDragView.m')
    if name == 'ScreenshotShield': return any(x in p for x in ['HeeeNoScreenShotView.','TFJGVGLGKFTVCSV.'])
    if name == 'LRKeychain': return p.endswith('/LRKeychain.h') or p.endswith('/LRKeychain.m')
    if name == 'NSObjectPlist': return p.endswith('/NSObject+Plist.h') or p.endswith('/NSObject+Plist.m')
    if name == 'NSObjectMenu': return p.endswith('/NSObject+Menu.h') or p.endswith('/NSObject+Menu.mm')
    if name == 'AESUtility': return p.endswith('/AESUtility.h') or p.endswith('/AESUtility.m')
    return False


def main():
    print('# P34 Exact Candidate Reference Audit')
    print('HEAD:', sh('git','rev-parse','HEAD'))
    print()
    for name, patterns in CANDIDATES.items():
        hits = []
        for path in PRODUCT:
            if own_group(name, path):
                continue
            text = strip_comments(read(path))
            lines = text.splitlines()
            for i, line in enumerate(lines, 1):
                matched = [pat for pat in patterns if re.search(pat, line)]
                if matched:
                    hits.append((path, i, line.strip()))
        print(f'## {name}')
        print(f'- uncommented product references outside candidate group: {len(hits)}')
        for path, line_no, line in hits[:80]:
            print(f'  - {path}:{line_no}: {line[:220]}')
        print()


if __name__ == '__main__':
    main()
