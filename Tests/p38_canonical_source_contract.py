#!/usr/bin/env python3
from pathlib import Path
import subprocess

P36_RUNTIME='c85a6a235daf3287b70c13fbe69be455a3aecce2'
ROOTS=['Bsphp','菜单','导入导出','视图菜单']
ACTIVE=[
 'base.remote-download','base.cloud-save','base.local-files',
 'data.backup-save','data.restore-save','data.clear-game-data',
 'auth.clear-records','runtime.iap-noads','runtime.ad-speed',
]

def out(*args): return subprocess.check_output(args,text=True).strip()
def tree(ref,path): return out('git','rev-parse',f'{ref}:{path}')
def fail(msg): raise SystemExit('p38-canonical-source-contract: FAIL: '+msg)

if Path('VERSION').read_text().strip()!='v1_p38': fail('VERSION must be v1_p38')
if tree('HEAD','testmod') != tree(P36_RUNTIME,'testmod'): fail('testmod tree changed from p36 runtime')
if tree('HEAD','testmod.xcodeproj') != tree(P36_RUNTIME,'testmod.xcodeproj'): fail('Xcode project changed from p36 runtime')
for root in ROOTS:
    if Path(root).exists(): fail(f'root mirror still exists: {root}')
    if not Path('testmod',root).exists(): fail(f'canonical tree missing: testmod/{root}')
registry=Path('testmod/ZONCore/ZONFeatureRegistry.m').read_text()
for ident in ACTIVE:
    if f'@"{ident}"' not in registry: fail(f'active feature missing: {ident}')
if 'runtime.placeholder-203' in registry: fail('placeholder 203 reappeared')
bridge=Path('testmod/ZONServices/ZONUDIDBridge.h').read_text()
ui=Path('testmod/视图菜单/NSObject+UI.m').read_text()
for marker in ['ZONUDIDBridgeRequestIfNeededWithUnavailableHandler','unable to open zonoe://udid; using web fallback']:
    if marker not in bridge: fail(f'UDID bridge marker missing: {marker}')
for marker in ['ZonoeStartLegacyWebUDIDFallback','ZONUDIDBridgeStoreUDID(udid);']:
    if marker not in ui: fail(f'UDID UI wiring missing: {marker}')
print('p38-canonical-source-contract: PASS')
