#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
DISPATCHER = ROOT / 'testmod/ZONCore/ZONFeatureDispatcher.m'
COORD_H = ROOT / 'testmod/ZONServices/ZONLocalFilesCoordinator.h'
COORD_M = ROOT / 'testmod/ZONServices/ZONLocalFilesCoordinator.m'

for required in (PBX, DISPATCHER, COORD_H, COORD_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B74000112F7B740100C0FFEE'
file_id = 'B74000122F7B740100C0FFEE'
name = 'ZONLocalFilesCoordinator.m'
path = 'testmod/ZONServices/ZONLocalFilesCoordinator.m'
build_anchor = '\t\tB73000112F7B730100C0FFEE /* ZONRuntimeDirectoryService.m in Sources */ = {isa = PBXBuildFile; fileRef = B73000122F7B730100C0FFEE /* ZONRuntimeDirectoryService.m */; };'
file_anchor = '\t\tB73000122F7B730100C0FFEE /* ZONRuntimeDirectoryService.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONRuntimeDirectoryService.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB73000112F7B730100C0FFEE /* ZONRuntimeDirectoryService.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P73 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P73 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P73 source anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

d = DISPATCHER.read_text(encoding='utf-8')
d = d.replace('#import "SandboxBrowserVC.h"\n', '')
if '#import "../ZONServices/ZONLocalFilesCoordinator.h"' not in d:
    d = d.replace('#import "../ZONServices/ZONResetCoordinator.h"\n', '#import "../ZONServices/ZONResetCoordinator.h"\n#import "../ZONServices/ZONLocalFilesCoordinator.h"\n', 1)

old = '''            @"base.local-files": ^BOOL(UIViewController *host) {\n                SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];\n                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];\n                if (@available(iOS 13.0, *)) {\n                    nav.modalPresentationStyle = UIModalPresentationPageSheet;\n                } else {\n                    nav.modalPresentationStyle = UIModalPresentationFullScreen;\n                }\n                [host presentViewController:nav animated:YES completion:nil];\n                return YES;\n            },'''
new = '''            @"base.local-files": ^BOOL(UIViewController *host) {\n                return [[ZONLocalFilesCoordinator sharedCoordinator] presentLocalFilesFromViewController:host];\n            },'''
if old in d:
    d = d.replace(old, new, 1)
elif new not in d:
    raise SystemExit('local-files dispatcher block missing')
DISPATCHER.write_text(d, encoding='utf-8')

final_d = DISPATCHER.read_text(encoding='utf-8')
final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count('ZONLocalFilesCoordinator.m in Sources') != 2:
    raise SystemExit('P74 coordinator PBX invariant failed')
for marker in ['#import "../ZONServices/ZONLocalFilesCoordinator.h"', 'presentLocalFilesFromViewController:host']:
    if marker not in final_d: raise SystemExit(f'missing P74 dispatcher marker: {marker}')
for forbidden in ['SandboxBrowserVC', 'UINavigationController', 'UIModalPresentationPageSheet', 'UIModalPresentationFullScreen']:
    if forbidden in final_d: raise SystemExit(f'dispatcher still owns local-files presentation: {forbidden}')
print('P74 local files coordinator migration applied successfully')
