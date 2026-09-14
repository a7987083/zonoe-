#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

P38_SOURCE='43c632d4ce6d04e51f9c8cc033292f9d98b134ff'
ACTIVE=[
 'base.remote-download','base.cloud-save','base.local-files',
 'data.backup-save','data.restore-save','data.clear-game-data',
 'auth.clear-records','runtime.iap-noads','runtime.ad-speed',
]
PROTECTED=[
 'testmod/Bsphp/main.m','testmod/Bsphp/WX_NongShiFu123.mm',
 'testmod/视图菜单/NSObject+UI.m','testmod/菜单/JHDragView.m',
 'testmod/菜单/PopupMenuVC.m','testmod/菜单/PubgLoad.mm',
 'testmod/菜单/SandboxBrowserVC.m','testmod/导入导出/daochucd.m',
 'testmod/导入导出/fuhzu.m','testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m',
 'testmod/工具箱/Hook/JiangHuHook.m','testmod/工具箱/变速器/HookClass.m',
 'testmod/工具箱/变速器/ImgTool.m','testmod/工具箱/变速器/fishhook/fishhook.c',
 'testmod/工具箱/UISlider+VDTrackHeight.m',
]

def out(*args): return subprocess.check_output(args,text=True,errors='replace').strip()
def fail(msg): raise SystemExit('p39-active-target-cleanup-contract: FAIL: '+msg)

if Path('VERSION').read_text().strip()!='v1_p39': fail('VERSION must be v1_p39')
for p in ['testmod/category/NSString+Tools.m','testmod/category/NSString+Tools.h']:
    if Path(p).exists(): fail(f'retired category still exists: {p}')
for p in PROTECTED:
    if not Path(p).exists(): fail(f'protected product source missing: {p}')

pbx=Path('testmod.xcodeproj/project.pbxproj').read_text(errors='replace')
if 'NSString+Tools.m' in pbx or 'NSString+Tools.h' in pbx: fail('stale NSString+Tools PBX reference')
names=[]
for name in re.findall(r'/\* ([^*/\n]+?) in Sources \*/',pbx):
    if name not in names: names.append(name)
if len(names)!=75: fail(f'expected 75 PBX active sources, got {len(names)}')

changed=set(out('git','diff','--name-only',P38_SOURCE,'--','testmod','testmod.xcodeproj').splitlines())
expected={'testmod/category/NSString+Tools.m','testmod/category/NSString+Tools.h','testmod.xcodeproj/project.pbxproj'}
if changed!=expected: fail(f'unexpected product diff vs p38: {sorted(changed)}')

registry=Path('testmod/ZONCore/ZONFeatureRegistry.m').read_text()
for ident in ACTIVE:
    if f'@"{ident}"' not in registry: fail(f'active feature missing: {ident}')
if 'runtime.placeholder-203' in registry: fail('placeholder 203 reappeared')

bridge=Path('testmod/ZONServices/ZONUDIDBridge.h').read_text()
ui=Path('testmod/视图菜单/NSObject+UI.m').read_text()
for marker in ['ZONUDIDBridgeRequestIfNeededWithUnavailableHandler','unable to open zonoe://udid; using web fallback']:
    if marker not in bridge: fail(f'UDID bridge marker missing: {marker}')
for marker in ['ZonoeStartLegacyWebUDIDFallback','ZONUDIDBridgeStoreUDID(udid);']:
    if marker not in ui: fail(f'UDID UI marker missing: {marker}')

print('p39-active-target-cleanup-contract: PASS (75 sources, NSString+Tools retired)')
