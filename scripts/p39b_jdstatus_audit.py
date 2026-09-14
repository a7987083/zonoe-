#!/usr/bin/env python3
from pathlib import Path
import json,re

ROOT=Path(__file__).resolve().parents[1]
TESTMOD=ROOT/'testmod'
GROUP=TESTMOD/'导入导出'/'JDStatusBarNotification'
PBX=ROOT/'testmod.xcodeproj'/'project.pbxproj'
OUT=ROOT/'build'
OUT.mkdir(exist_ok=True)

expected_m={
'JDStatusBarNotificationStyle.m','JDStatusBarNotificationPresenter.m',
'JDSBNotificationStyleCache.m','JDSBNotificationWindow.m',
'UIApplication+JDSB_MainWindow.m','JDSBNotificationView.m',
'JDSBNotificationAnimator.m','JDSBNotificationViewController.m'}

all_m=sorted(p.name for p in GROUP.rglob('*.m'))
all_h=sorted(p.name for p in GROUP.rglob('*.h'))
all_swift=sorted(p.name for p in GROUP.rglob('*.swift'))
if set(all_m)!=expected_m:
    raise SystemExit(f'JDStatus .m inventory mismatch: {all_m}')

pbx=PBX.read_text(errors='replace')
sources_sec=pbx.split('/* Begin PBXSourcesBuildPhase section */',1)[1].split('/* End PBXSourcesBuildPhase section */',1)[0]
pbx_source_hits={name:sources_sec.count(f'{name} in Sources') for name in sorted(expected_m)}
if any(v!=1 for v in pbx_source_hits.values()):
    raise SystemExit(f'JDStatus active source mismatch: {pbx_source_hits}')
swift_pbx_hits={name:pbx.count(name) for name in all_swift}

exts={'.m','.mm','.h','.c','.cc','.cpp','.swift','.pch'}
external_files=[p for p in TESTMOD.rglob('*') if p.is_file() and p.suffix in exts and GROUP not in p.parents]
class_tokens=[
'JDStatusBarNotification','JDStatusBarNotificationPresenter','JDStatusBarNotificationStyle',
'JDSBNotification','UIApplication+JDSB_MainWindow']
api_tokens=[
'sharedPresenter','presentWithText','presentWithTitle','presentWithCustomView',
'updateText','updateDefaultStyle','addStyleNamed','displayProgressBarWithPercentage',
'displayActivityIndicator','dismissAnimated','dismissAfterDelay','dismissWithCompletion']

texts={}
external_imports=[]
external_refs=[]
dynamic_refs=[]
for p in external_files:
    try: text=p.read_text(errors='replace')
    except Exception: continue
    rel=str(p.relative_to(ROOT)); texts[rel]=text
    for i,line in enumerate(text.splitlines(),1):
        s=line.strip()
        if s.startswith('#import') and any(t in line for t in class_tokens):
            external_imports.append({'file':rel,'line':i,'text':s})
        if any(t in line for t in class_tokens):
            external_refs.append({'file':rel,'line':i,'text':s})
        if any(k in line for k in ('NSClassFromString','objc_getClass','NSSelectorFromString','sel_registerName','performSelector')) and (any(t in line for t in class_tokens) or any(t in line for t in api_tokens)):
            dynamic_refs.append({'file':rel,'line':i,'text':s})

def codeish(s):
    t=s.lstrip()
    return not (t.startswith('//') or t.startswith('/*') or t.startswith('*'))
external_refs_code=[x for x in external_refs if codeish(x['text'])]
non_import_class_refs=[x for x in external_refs_code if not x['text'].startswith('#import')]

# API scan only inside files that actually import/refer to the JDStatus unit. This avoids
# generic selector-name collisions with unrelated HUD libraries.
jd_files=sorted(set(x['file'] for x in external_imports) | set(x['file'] for x in non_import_class_refs))
external_api_code=[]
for rel in jd_files:
    for i,line in enumerate(texts[rel].splitlines(),1):
        if codeish(line) and any(t in line for t in api_tokens):
            external_api_code.append({'file':rel,'line':i,'text':line.strip()})

auto_patterns={
'+load':re.compile(r'\+\s*\(\s*void\s*\)\s*load\b'),
'+initialize':re.compile(r'\+\s*\(\s*void\s*\)\s*initialize\b'),
'constructor':re.compile(r'__attribute__\s*\(\(\s*constructor'),
'swizzle':re.compile(r'method_exchangeImplementations|class_addMethod|class_replaceMethod|swizzl',re.I),
'fishhook':re.compile(r'rebind_symbols'),
'dlopen':re.compile(r'\bdlopen\s*\('),
'runtime_class_lookup':re.compile(r'NSClassFromString|objc_getClass'),
'dynamic_selector':re.compile(r'NSSelectorFromString|sel_registerName|performSelector')}
internal_auto=[]; categories=[]
for p in sorted(GROUP.rglob('*.m')):
    text=p.read_text(errors='replace'); rel=str(p.relative_to(ROOT))
    for name,pat in auto_patterns.items():
        for m in pat.finditer(text):
            internal_auto.append({'file':rel,'line':text.count('\n',0,m.start())+1,'kind':name})
    for m in re.finditer(r'@implementation\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]+)\)',text):
        categories.append({'file':rel,'class':m.group(1),'category':m.group(2).strip()})

import_files=sorted(set(x['file'] for x in external_imports))
live_ref_files=sorted(set(x['file'] for x in non_import_class_refs) | set(x['file'] for x in external_api_code))
stale_import_candidates=sorted(set(import_files)-set(live_ref_files))
strong_removal=(not non_import_class_refs and not external_api_code and not dynamic_refs and not internal_auto)
decision='REMOVAL_CANDIDATE' if strong_removal else 'KEEP_LIVE_DEPENDENCY'

result={
'baseline_version':(ROOT/'VERSION').read_text().strip(),
'group_path':str(GROUP.relative_to(ROOT)),
'objective_c_source_count':len(all_m),'objective_c_sources':all_m,
'header_count':len(all_h),'swift_files':all_swift,
'pbx_source_hits':pbx_source_hits,'swift_pbx_hits':swift_pbx_hits,
'external_imports':external_imports,
'external_class_refs_code':non_import_class_refs,
'external_api_refs_code':external_api_code,
'external_dynamic_refs':dynamic_refs,
'internal_auto_runtime_entries':internal_auto,
'internal_categories':categories,
'live_ref_files':live_ref_files,
'stale_import_candidates':stale_import_candidates,
'strong_removal_candidate':strong_removal,
'decision':decision,
'notes':["A compiled Objective-C category is not treated as an automatic entry unless it has +load/swizzle/constructor behavior.","NotificationPresenter.swift is repository content only when PBX hit count is zero.","An audit result of KEEP_LIVE_DEPENDENCY is a successful audit outcome, not a CI failure."]}
(OUT/'p39b-jdstatus-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
md=['# P39-B JDStatusBarNotification Audit','',f"- Baseline: `{result['baseline_version']}`",f"- Group: `{result['group_path']}`",f"- Decision: **{decision}**",f"- Active Objective-C source units: **{len(all_m)}**",f"- Swift repository files: **{len(all_swift)}**; PBX hits: `{swift_pbx_hits}`",'']
md += ['## PBX active sources']+[f"- `{k}`: {v} Sources entry" for k,v in pbx_source_hits.items()]+['']
md += ['## External imports']+([f"- `{x['file']}:{x['line']}` — `{x['text']}`" for x in external_imports] or ['- None'])+['']
md += ['## Live class/API reference files']+([f"- `{x}`" for x in live_ref_files] or ['- None'])+['']
md += ['## External non-import class references']+([f"- `{x['file']}:{x['line']}` — `{x['text']}`" for x in non_import_class_refs] or ['- None'])+['']
md += ['## External JDStatus API references']+([f"- `{x['file']}:{x['line']}` — `{x['text']}`" for x in external_api_code] or ['- None'])+['']
md += ['## External dynamic references']+([f"- `{x['file']}:{x['line']}` — `{x['text']}`" for x in dynamic_refs] or ['- None'])+['']
md += ['## Internal automatic/runtime entry scan']+([f"- `{x['file']}:{x['line']}` — {x['kind']}" for x in internal_auto] or ['- None'])+['']
md += ['## Objective-C categories inside group']+([f"- `{x['file']}` — `{x['class']} ({x['category']})`" for x in categories] or ['- None'])+['']
md += ['## Stale import candidates']+([f"- `{x}`" for x in stale_import_candidates] or ['- None'])+['']
md += ['## Decision',f"- Strong whole-group removal candidate: **{str(strong_removal).lower()}**",f"- Final audit classification: **{decision}**",'- Product runtime was not modified by this audit.','']
(OUT/'p39b-jdstatus-audit.md').write_text('\n'.join(md))
print(json.dumps(result,ensure_ascii=False,indent=2))
