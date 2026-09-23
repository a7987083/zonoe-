#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SAVE = ROOT / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'

for required in (PBX, SAVE):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B77000112F7B770100C0FFEE'
file_id = 'B77000122F7B770100C0FFEE'
name = 'ZONRemoteRestoreCoordinator.m'
path = 'testmod/ZONServices/ZONRemoteRestoreCoordinator.m'
build_anchor = '\t\tB76000112F7B760100C0FFEE /* ZONAuthorizationEntryRouter.m in Sources */ = {isa = PBXBuildFile; fileRef = B76000122F7B760100C0FFEE /* ZONAuthorizationEntryRouter.m */; };'
file_anchor = '\t\tB76000122F7B760100C0FFEE /* ZONAuthorizationEntryRouter.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONAuthorizationEntryRouter.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB76000112F7B760100C0FFEE /* ZONAuthorizationEntryRouter.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P76 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P76 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P76 source anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

s = SAVE.read_text(encoding='utf-8')
s = s.replace('#import "ZONRemoteDownloadService.h"\n', '')
if '#import "ZONRemoteRestoreCoordinator.h"' not in s:
    s = s.replace('#import "ZONSaveTransferCoordinator.h"\n', '#import "ZONSaveTransferCoordinator.h"\n#import "ZONRemoteRestoreCoordinator.h"\n', 1)

pattern = re.compile(
    r'- \(void\)presentRemoteDownloadProgressReceived:\(int64_t\)received expected:\(int64_t\)expected\n\{.*?\n\}\n\n'
    r'- \(void\)startArchiveDownloadWithURL:\(NSURL \*\)url\n\{.*?\n\}\n\n',
    re.S,
)
s, count = pattern.subn('', s, count=1)
if count == 0 and ('presentRemoteDownloadProgressReceived:' in s or 'downloadArchiveFromURL:' in s):
    raise SystemExit('could not remove legacy remote restore orchestration block')

s = s.replace('[self startArchiveDownloadWithURL:[NSURL URLWithString:text]];',
              '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:[NSURL URLWithString:text]];')
s = s.replace('[self startArchiveDownloadWithURL:downloadURL];',
              '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:downloadURL];')
SAVE.write_text(s, encoding='utf-8')

final_s = SAVE.read_text(encoding='utf-8')
final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count('ZONRemoteRestoreCoordinator.m in Sources') != 2:
    raise SystemExit('P77 coordinator PBX invariant failed')
for marker in [
    '#import "ZONRemoteRestoreCoordinator.h"',
    '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:[NSURL URLWithString:text]];',
    '[[ZONRemoteRestoreCoordinator sharedCoordinator] startArchiveDownloadWithURL:downloadURL];',
]:
    if marker not in final_s:
        raise SystemExit(f'missing P77 save-transfer route marker: {marker}')
for forbidden in [
    '#import "ZONRemoteDownloadService.h"',
    'downloadArchiveFromURL:',
    'presentRemoteDownloadProgressReceived:',
    '- (void)startArchiveDownloadWithURL:',
]:
    if forbidden in final_s:
        raise SystemExit(f'P77 save-transfer still owns remote restore orchestration: {forbidden}')
print('P77 remote restore coordinator migration applied successfully')
