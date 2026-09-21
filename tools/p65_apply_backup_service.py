#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONBackupService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONBackupService.m'
POLICY_H = ROOT / 'testmod/ZONServices/ZONBackupPolicy.h'
POLICY_M = ROOT / 'testmod/ZONServices/ZONBackupPolicy.m'

entries = [
    {
        'build_id': 'B65000112F7B400100C0FFEE',
        'file_id': 'B65000122F7B400100C0FFEE',
        'name': 'ZONBackupService.m',
        'path': 'testmod/ZONServices/ZONBackupService.m',
    },
    {
        'build_id': 'B65000212F7B400100C0FFEE',
        'file_id': 'B65000222F7B400100C0FFEE',
        'name': 'ZONBackupPolicy.m',
        'path': 'testmod/ZONServices/ZONBackupPolicy.m',
    },
]

build_anchor = '\t\tB63B00012F7B300100C0FFEE /* ZONGameDataResetService.m in Sources */ = {isa = PBXBuildFile; fileRef = B63B00022F7B300100C0FFEE /* ZONGameDataResetService.m */; };'
file_anchor = '\t\tB63B00022F7B300100C0FFEE /* ZONGameDataResetService.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONGameDataResetService.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB63B00012F7B300100C0FFEE /* ZONGameDataResetService.m in Sources */,'
target_prefix_anchor = '\t\t\t\tGCC_PREFIX_HEADER = "testmod/testmod-Prefix.pch";'
service_header_search = (
    '\t\t\t\tHEADER_SEARCH_PATHS = (\n'
    '\t\t\t\t\t"$(inherited)",\n'
    '\t\t\t\t\t"$(SRCROOT)/testmod/ZONServices",\n'
    '\t\t\t\t);'
)

for required in (PBX, SERVICE_H, SERVICE_M, POLICY_H, POLICY_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')

for entry in entries:
    build_marker = f"{entry['name']} in Sources"
    build_line = f"\t\t{entry['build_id']} /* {build_marker} */ = {{isa = PBXBuildFile; fileRef = {entry['file_id']} /* {entry['name']} */; }};"
    file_line = f"\t\t{entry['file_id']} /* {entry['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = \"{entry['path']}\"; sourceTree = SOURCE_ROOT; }};"
    source_line = f"\t\t\t\t{entry['build_id']} /* {build_marker} */,"

    if build_line not in pbx:
        if build_anchor not in pbx:
            raise SystemExit('P63B PBX build anchor missing')
        pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
        build_anchor = build_line

    if file_line not in pbx:
        if file_anchor not in pbx:
            raise SystemExit('P63B PBX file-reference anchor missing')
        pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
        file_anchor = file_line

    if source_line not in pbx:
        if source_anchor not in pbx:
            raise SystemExit('P63B PBX sources anchor missing')
        pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
        source_anchor = source_line

# ZONBackupService.h / ZONBackupPolicy.h are target-private headers. They do not need
# to be exported in PBXHeadersBuildPhase, but daochucd.m lives in another directory,
# so the native target must explicitly expose ZONServices to quoted includes.
if '"$(SRCROOT)/testmod/ZONServices"' not in pbx:
    anchor_count = pbx.count(target_prefix_anchor)
    if anchor_count != 2:
        raise SystemExit(f'unexpected target prefix-header anchor count: {anchor_count}')
    pbx = pbx.replace(
        target_prefix_anchor,
        target_prefix_anchor + '\n' + service_header_search,
    )

PBX.write_text(pbx, encoding='utf-8')
final_pbx = PBX.read_text(encoding='utf-8')

for entry in entries:
    marker = f"{entry['name']} in Sources"
    if final_pbx.count(marker) != 2:
        raise SystemExit(f'unexpected marker count for {entry["name"]}: {final_pbx.count(marker)}')

header_search_marker = '"$(SRCROOT)/testmod/ZONServices"'
if final_pbx.count(header_search_marker) != 2:
    raise SystemExit(
        f'unexpected ZONServices header-search marker count: {final_pbx.count(header_search_marker)}'
    )

print('P65 backup service PBX migration applied successfully')
