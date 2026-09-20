#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONGameDataResetService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONGameDataResetService.m'
ACTION_M = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'

BUILD_ID = 'B63B00012F7B300100C0FFEE'
FILE_ID = 'B63B00022F7B300100C0FFEE'
BUILD_MARKER = 'ZONGameDataResetService.m in Sources'
FILE_MARKER = 'ZONGameDataResetService.m'

build_line = f'\t\t{BUILD_ID} /* {BUILD_MARKER} */ = {{isa = PBXBuildFile; fileRef = {FILE_ID} /* {FILE_MARKER} */; }};'
file_line = f'\t\t{FILE_ID} /* {FILE_MARKER} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONGameDataResetService.m"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{BUILD_ID} /* {BUILD_MARKER} */,'

build_anchor = '\t\tB63A00012F7B200100C0FFEE /* ZONSixButtonActionService.m in Sources */ = {isa = PBXBuildFile; fileRef = B63A00022F7B200100C0FFEE /* ZONSixButtonActionService.m */; };'
file_anchor = '\t\tB63A00022F7B200100C0FFEE /* ZONSixButtonActionService.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONSixButtonActionService.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB63A00012F7B200100C0FFEE /* ZONSixButtonActionService.m in Sources */,'

for required in (SERVICE_H, SERVICE_M, ACTION_M, PBX):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')

if build_line not in pbx:
    if build_anchor not in pbx:
        raise SystemExit('P63A PBX build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)

if file_line not in pbx:
    if file_anchor not in pbx:
        raise SystemExit('P63A PBX file-reference anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)

if source_line not in pbx:
    if source_anchor not in pbx:
        raise SystemExit('P63A PBX sources anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)

PBX.write_text(pbx, encoding='utf-8')

final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count(BUILD_MARKER) != 2:
    raise SystemExit(f'unexpected P63B source marker count: {final_pbx.count(BUILD_MARKER)}')
if build_line not in final_pbx:
    raise SystemExit('P63B PBXBuildFile declaration missing')
if file_line not in final_pbx:
    raise SystemExit('P63B PBXFileReference declaration missing')
if source_line not in final_pbx:
    raise SystemExit('P63B PBXSourcesBuildPhase membership missing')

print('P63B game data reset PBX migration applied successfully')
