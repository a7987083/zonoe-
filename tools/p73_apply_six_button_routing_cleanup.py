#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SIX = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
DISPATCHER = ROOT / 'testmod/ZONCore/ZONFeatureDispatcher.m'
TRANSFER = ROOT / 'testmod/ZONServices/ZONSaveTransferCoordinator.m'
RUNTIME_H = ROOT / 'testmod/ZONServices/ZONRuntimeDirectoryService.h'
RUNTIME_M = ROOT / 'testmod/ZONServices/ZONRuntimeDirectoryService.m'

for required in (PBX, SIX, DISPATCHER, TRANSFER, RUNTIME_H, RUNTIME_M):
    if not required.exists():
        raise SystemExit(f'missing required file: {required.relative_to(ROOT)}')

pbx = PBX.read_text(encoding='utf-8')
build_id = 'B73000112F7B730100C0FFEE'
file_id = 'B73000122F7B730100C0FFEE'
name = 'ZONRuntimeDirectoryService.m'
path = 'testmod/ZONServices/ZONRuntimeDirectoryService.m'
build_anchor = '\t\tB72000112F7B720100C0FFEE /* ZONResetCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = B72000122F7B720100C0FFEE /* ZONResetCoordinator.m */; };'
file_anchor = '\t\tB72000122F7B720100C0FFEE /* ZONResetCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONResetCoordinator.m"; sourceTree = SOURCE_ROOT; };'
source_anchor = '\t\t\t\tB72000112F7B720100C0FFEE /* ZONResetCoordinator.m in Sources */,'
build_line = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
file_line = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
source_line = f'\t\t\t\t{build_id} /* {name} in Sources */,'

if build_line not in pbx:
    if build_anchor not in pbx: raise SystemExit('P72 build anchor missing')
    pbx = pbx.replace(build_anchor, build_anchor + '\n' + build_line, 1)
if file_line not in pbx:
    if file_anchor not in pbx: raise SystemExit('P72 file anchor missing')
    pbx = pbx.replace(file_anchor, file_anchor + '\n' + file_line, 1)
if source_line not in pbx:
    if source_anchor not in pbx: raise SystemExit('P72 source anchor missing')
    pbx = pbx.replace(source_anchor, source_anchor + '\n' + source_line, 1)
PBX.write_text(pbx, encoding='utf-8')

six = SIX.read_text(encoding='utf-8')
if '#import "ZONRuntimeDirectoryService.h"' not in six:
    six = six.replace('#import "ZONResetCoordinator.h"\n', '#import "ZONResetCoordinator.h"\n#import "ZONRuntimeDirectoryService.h"\n', 1)

six = re.sub(
    r'\+ \(NSString \*\)temporaryDirectoryPath\n\{.*?\n\}\n',
    '+ (NSString *)temporaryDirectoryPath\n{\n    return [ZONRuntimeDirectoryService temporaryDirectoryPath];\n}\n',
    six, count=1, flags=re.S)
six = re.sub(
    r'\+ \(BOOL\)ensureTemporaryDirectory\n\{.*?\n\}\n',
    '+ (BOOL)ensureTemporaryDirectory\n{\n    return [ZONRuntimeDirectoryService ensureTemporaryDirectory];\n}\n',
    six, count=1, flags=re.S)
six = six.replace('    [self ensureTemporaryDirectory];\n    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:hostViewController];',
                  '    [[ZONSaveTransferCoordinator sharedCoordinator] presentCloudSaveFromViewController:hostViewController];', 1)
SIX.write_text(six, encoding='utf-8')

dispatcher = DISPATCHER.read_text(encoding='utf-8')
if '#import "../ZONServices/ZONRuntimeDirectoryService.h"' not in dispatcher:
    dispatcher = dispatcher.replace('#import "../ZONServices/ZONSixButtonActionService.h"\n',
                                    '#import "../ZONServices/ZONSixButtonActionService.h"\n#import "../ZONServices/ZONRuntimeDirectoryService.h"\n#import "../ZONServices/ZONResetCoordinator.h"\n', 1)
dispatcher = dispatcher.replace('return [ZONSixButtonActionService temporaryDirectoryPath];',
                                'return [ZONRuntimeDirectoryService temporaryDirectoryPath];', 1)
dispatcher = dispatcher.replace('return [ZONSixButtonActionService ensureTemporaryDirectory];',
                                'return [ZONRuntimeDirectoryService ensureTemporaryDirectory];', 1)
dispatcher = dispatcher.replace('[ZONSixButtonActionService clearGameDataPreservingTemporaryDirectory];',
                                '[[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];', 1)
dispatcher = dispatcher.replace('[ZONSixButtonActionService performClearGameDataFromViewController:hostViewController];',
                                '[[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];', 1)
dispatcher = dispatcher.replace('[ZONSixButtonActionService performClearAuthorizationFromViewController:hostViewController];',
                                '[[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];', 1)
DISPATCHER.write_text(dispatcher, encoding='utf-8')

transfer = TRANSFER.read_text(encoding='utf-8')
if '#import "ZONRuntimeDirectoryService.h"' not in transfer:
    transfer = transfer.replace('#import "ZONCloudSaveService.h"\n', '#import "ZONCloudSaveService.h"\n#import "ZONRuntimeDirectoryService.h"\n', 1)
needle = '- (void)presentCloudSaveFromViewController:(UIViewController *)hostViewController\n{\n    if (!hostViewController) return;\n'
replacement = needle + '    [ZONRuntimeDirectoryService ensureTemporaryDirectory];\n'
if needle in transfer and '[ZONRuntimeDirectoryService ensureTemporaryDirectory];' not in transfer:
    transfer = transfer.replace(needle, replacement, 1)
TRANSFER.write_text(transfer, encoding='utf-8')

final_six = SIX.read_text(encoding='utf-8')
final_dispatcher = DISPATCHER.read_text(encoding='utf-8')
final_transfer = TRANSFER.read_text(encoding='utf-8')
final_pbx = PBX.read_text(encoding='utf-8')

if final_pbx.count('ZONRuntimeDirectoryService.m in Sources') != 2:
    raise SystemExit('P73 runtime directory PBX marker invariant failed')
for forbidden in ('NSFileManager', 'NSHomeDirectory()', 'createDirectoryAtPath:', 'stringByAppendingPathComponent:@"tmp"'):
    if forbidden in final_six:
        raise SystemExit(f'SixButton still owns filesystem behavior: {forbidden}')
for marker in ('[ZONRuntimeDirectoryService temporaryDirectoryPath]', '[ZONRuntimeDirectoryService ensureTemporaryDirectory]'):
    if marker not in final_dispatcher:
        raise SystemExit(f'dispatcher compatibility route missing: {marker}')
for marker in ('#import "ZONRuntimeDirectoryService.h"', '[ZONRuntimeDirectoryService ensureTemporaryDirectory];'):
    if marker not in final_transfer:
        raise SystemExit(f'cloud transfer tmp preparation missing: {marker}')
print('P73 six-button routing cleanup migration applied successfully')
