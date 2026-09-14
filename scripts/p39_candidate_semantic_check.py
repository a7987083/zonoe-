#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

CANDIDATE_M = 'testmod/category/NSString+Tools.m'
CANDIDATE_H = 'testmod/category/NSString+Tools.h'
EXACT_TERMS = [
    'NSString+Tools.h',
    'sizeOfFontSize:',
    'sizeWithString:',
    'andMaxSize:',
]
# fileSize is generic, so count only Objective-C selector-like uses in product text.
SELECTOR_PATTERNS = {
    'sizeOfFontSize': re.compile(r'\bsizeOfFontSize\s*:'),
    'sizeWithString': re.compile(r'\bsizeWithString\s*:'),
    'fileSize-message': re.compile(r'\[[^\]\n]+\s+fileSize\s*\]'),
    'selector-fileSize': re.compile(r'@selector\s*\(\s*fileSize\s*\)|NSSelectorFromString\s*\(\s*@?"fileSize"'),
}


def sh(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def main():
    tracked = [p for p in sh('git','-c','core.quotepath=false','ls-files').splitlines() if p.startswith('testmod/')]
    findings = []
    for path in tracked:
        if path in {CANDIDATE_M, CANDIDATE_H}:
            continue
        try:
            text = Path(path).read_text(errors='replace')
        except Exception:
            continue
        for term in EXACT_TERMS:
            if term in text:
                findings.append({'path': path, 'kind': 'exact-term', 'term': term})
        for name, pat in SELECTOR_PATTERNS.items():
            if pat.search(text):
                findings.append({'path': path, 'kind': 'selector-pattern', 'term': name})

    pbx = Path('testmod.xcodeproj/project.pbxproj').read_text(errors='replace')
    pbx_m = 'NSString+Tools.m' in pbx
    pbx_h = 'NSString+Tools.h' in pbx
    report = {
        'head': sh('git','rev-parse','HEAD'),
        'candidate_m': CANDIDATE_M,
        'candidate_h': CANDIDATE_H,
        'pbx_mentions_m': pbx_m,
        'pbx_mentions_h': pbx_h,
        'external_product_findings': findings,
        'semantic_reference_count': len(findings),
        'assessment': 'deletion_candidate_strong' if not findings else 'manual_review_required',
    }
    Path('p39-candidate-semantic-check.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    lines = [
        '# P39 NSString+Tools semantic check', '',
        f"- HEAD: `{report['head']}`",
        f"- candidate: `{CANDIDATE_M}` + `{CANDIDATE_H}`",
        f"- PBX mentions implementation: **{pbx_m}**",
        f"- PBX mentions header: **{pbx_h}**",
        f"- external product selector/import findings: **{len(findings)}**",
        f"- assessment: **{report['assessment']}**", '',
    ]
    if findings:
        lines.append('## Findings')
        lines.append('')
        for x in findings:
            lines.append(f"- `{x['path']}` — {x['kind']} `{x['term']}`")
    else:
        lines += [
            '- No tracked `testmod/` file outside the category itself imports `NSString+Tools.h`.',
            '- No tracked `testmod/` file outside the category itself contains the category-specific size selectors.',
            '- No Objective-C `fileSize` message send / selector-string pattern was found outside the category itself.',
            '- The implementation is still in PBX Sources, so removal must also prune its PBX build entry.',
        ]
    Path('p39-candidate-semantic-check.md').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines))

if __name__ == '__main__':
    main()
