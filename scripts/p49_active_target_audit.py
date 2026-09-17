#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj' / 'project.pbxproj'
SOURCE_EXTS = {'.m','.mm','.c','.cc','.cpp','.cxx','.swift'}
TEXT_EXTS = SOURCE_EXTS | {'.h','.hpp','.pch','.json','.md','.yml','.yaml','.sh','.py','.plist'}


def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True, errors='replace')


def phase_entries(text: str, phase: str) -> list[str]:
    m = re.search(rf'/\* Begin PBX{phase}BuildPhase section \*/(.*?)/\* End PBX{phase}BuildPhase section \*/', text, re.S)
    if not m:
        raise SystemExit(f'missing PBX{phase}BuildPhase section')
    suffix = {'Sources':'Sources','Frameworks':'Frameworks','Headers':'Headers'}[phase]
    vals = re.findall(r'/\* (.+?) in ' + suffix + r' \*/', m.group(1))
    return sorted(dict.fromkeys(vals))


def tracked_files() -> list[str]:
    return [x for x in git('ls-files').splitlines() if x]


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors='replace')
    except Exception:
        return ''


def main() -> None:
    pbx = PBX.read_text(errors='replace')
    sources = phase_entries(pbx, 'Sources')
    frameworks = phase_entries(pbx, 'Frameworks')
    headers = phase_entries(pbx, 'Headers')

    tracked = tracked_files()
    tracked_sources = sorted(p for p in tracked if Path(p).suffix.lower() in SOURCE_EXTS and p.startswith('testmod/'))
    active_names = set(sources)
    dormant_sources = [p for p in tracked_sources if Path(p).name not in active_names]

    # Build a repository text corpus without vendored build outputs.
    text_files = [p for p in tracked if Path(p).suffix.lower() in TEXT_EXTS and not p.startswith('Vendor/')]
    texts = {p: read_text(ROOT / p) for p in text_files}

    # Import/use evidence for dormant translation units by basename/stem/class-like stem.
    dormant_evidence = []
    for p in dormant_sources:
        name = Path(p).name
        stem = Path(p).stem
        refs = []
        for q, txt in texts.items():
            if q == p:
                continue
            if name in txt or re.search(rf'(?<![A-Za-z0-9_]){re.escape(stem)}(?![A-Za-z0-9_])', txt):
                refs.append(q)
        dormant_evidence.append({'path': p, 'refs': sorted(refs)[:100], 'ref_count': len(refs)})

    # Dynamic lookup evidence visible in active product source.
    dynamic_patterns = {
        'NSClassFromString': r'NSClassFromString\s*\(',
        'NSSelectorFromString': r'NSSelectorFromString\s*\(',
        'objc_getClass': r'objc_getClass\s*\(',
        'sel_registerName': r'sel_registerName\s*\(',
        'dlsym': r'dlsym\s*\(',
        'dlopen': r'dlopen\s*\(',
    }
    dynamic_hits = []
    for p, txt in texts.items():
        if not p.startswith('testmod/'):
            continue
        for kind, pat in dynamic_patterns.items():
            for m in re.finditer(pat, txt):
                line = txt.count('\n', 0, m.start()) + 1
                dynamic_hits.append({'path': p, 'line': line, 'kind': kind})

    # Framework imports present in active source tree, for comparison with PBX Frameworks phase.
    fw_imports: dict[str, list[str]] = {}
    fw_re = re.compile(r'#(?:import|include)\s*[<\"]([A-Za-z0-9_+.-]+)(?:/[^>\"]+)?[>\"]')
    for p, txt in texts.items():
        if not p.startswith('testmod/'):
            continue
        for fw in fw_re.findall(txt):
            if fw in {'Foundation','UIKit','CoreGraphics','QuartzCore','Security','SystemConfiguration','MobileCoreServices','UniformTypeIdentifiers','WebKit','AVFoundation','Photos','CoreImage','CoreMedia','AudioToolbox'}:
                fw_imports.setdefault(fw, []).append(p)
    fw_imports = {k: sorted(set(v)) for k,v in sorted(fw_imports.items())}

    report = {
        'baseline': 'v1_p48_1',
        'active_source_count': len(sources),
        'active_sources': sources,
        'pbx_framework_count': len(frameworks),
        'pbx_frameworks': frameworks,
        'pbx_header_count': len(headers),
        'tracked_testmod_translation_units': len(tracked_sources),
        'dormant_translation_units': dormant_evidence,
        'dynamic_lookup_sites': dynamic_hits,
        'framework_import_evidence': fw_imports,
    }
    out = ROOT / 'build' / 'p49-active-target-audit.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({
        'ACTIVE_SOURCES': len(sources),
        'TRACKED_TRANSLATION_UNITS': len(tracked_sources),
        'DORMANT_TRANSLATION_UNITS': len(dormant_sources),
        'PBX_FRAMEWORKS': len(frameworks),
        'DYNAMIC_LOOKUP_SITES': len(dynamic_hits),
    }, ensure_ascii=False))
    print(out)

if __name__ == '__main__':
    main()
