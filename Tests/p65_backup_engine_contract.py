#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = ROOT / 'VERSION'
ACTION = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
LEGACY = ROOT / 'testmod/导入导出/daochucd.m'
COORD = ROOT / 'testmod/ZONServices/ZONBackupCoordinator.m'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONBackupService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONBackupService.m'
POLICY_H = ROOT / 'testmod/ZONServices/ZONBackupPolicy.h'
POLICY_M = ROOT / 'testmod/ZONServices/ZONBackupPolicy.m'
RESTORE = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

for path in (VERSION, ACTION, LEGACY, COORD, SERVICE_H, SERVICE_M, POLICY_H, POLICY_M, RESTORE, PBX):
    if not path.exists():
        raise SystemExit(f'missing required file: {path.relative_to(ROOT)}')

version = VERSION.read_text(encoding='utf-8').strip()
action = ACTION.read_text(encoding='utf-8')
legacy = LEGACY.read_text(encoding='utf-8')
coord = COORD.read_text(encoding='utf-8')
service_h = SERVICE_H.read_text(encoding='utf-8')
service_m = SERVICE_M.read_text(encoding='utf-8')
policy_h = POLICY_H.read_text(encoding='utf-8')
policy_m = POLICY_M.read_text(encoding='utf-8')
restore = RESTORE.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')

if version not in {'v1_p65', 'v1_p66', 'v1_p67', 'v1_p67a', 'v1_p68', 'v1_p69', 'v1_p70', 'v1_p71', 'v1_p72', 'v1_p73'}:
    raise SystemExit(f'unexpected VERSION: {version}')

for marker in (
    'ZONBackupStagePreparing', 'ZONBackupStageScanning', 'ZONBackupStageCopyingDocuments',
    'ZONBackupStageCopyingLibrary', 'ZONBackupStageArchiving', 'ZONBackupStageCompleted',
    'createBackupNamed:', 'largeItemDecision:', 'progress:', 'completion:',
):
    if marker not in service_h:
        raise SystemExit(f'missing backup API marker: {marker}')

for marker in (
    'ZONBackupManifestItem', 'manifestForRootName:', 'copyManifest:', 'tmp/zonoe',
    '@"Documents"', '@"Library"', 'SSZipArchive createZipFileAtPath:',
    'contentsOfDirectoryAtURL:', 'copyItemAtURL:',
):
    if marker not in service_m:
        raise SystemExit(f'missing backup engine marker: {marker}')

for forbidden in ('#import <UIKit/UIKit.h>', 'SVProgressHUD', 'UIAlertController', 'UIDocumentInteractionController', 'JHPP'):
    if forbidden in service_m or forbidden in policy_m:
        raise SystemExit(f'presentation dependency leaked into backup engine/policy: {forbidden}')

for marker in (
    '50ULL * 1024ULL * 1024ULL', '@"Documents/zonoe"', '@"Library/HeimdallrBU"',
    '@"Library/Caches"', '@"Library/UnityCache"', 'shouldExcludeContentsAtRelativePath:',
):
    if marker not in policy_m and marker not in policy_h:
        raise SystemExit(f'missing backup policy marker: {marker}')

if version in {'v1_p70', 'v1_p71', 'v1_p72', 'v1_p73'}:
    for marker in ('#import "ZONBackupCoordinator.h"', '[ZONBackupCoordinator sharedCoordinator]', 'presentBackupFromViewController:hostViewController'):
        if marker not in action:
            raise SystemExit(f'P70+ backup route missing: {marker}')
    for marker in ('#import "ZONBackupService.h"', 'createBackupNamed:', 'requestBackupDecisionForRelativePath:', 'shareArchiveAtURL:'):
        if marker not in coord:
            raise SystemExit(f'P70+ coordinator missing inherited backup UI behavior: {marker}')
    for forbidden in ('ZONBackupService', 'SVProgressHUD', 'UIDocumentInteractionController', 'cleanupBackupArtifacts', 'requestBackupDecisionForRelativePath:'):
        if forbidden in legacy:
            raise SystemExit(f'legacy daochucd still owns backup orchestration: {forbidden}')
else:
    for marker in ('#import "daochucd.h"', '[[daochucd alloc] backupasd]'):
        if marker not in action:
            raise SystemExit(f'legacy backup route changed unexpectedly: {marker}')

for forbidden in ('#import "SSZipArchive.h"', 'folderSizeAtPath:', 'copyBackupItems:', 'copyBackupTopLevelFrom:', 'copyContentsFrom:', 'clearDirectory:', 'ensureDirectoryExists:', 'createZipFileAtPath:'):
    if forbidden in legacy:
        raise SystemExit(f'legacy backup engine logic still present in daochucd: {forbidden}')

for name in ('ZONBackupService.m', 'ZONBackupPolicy.m'):
    marker = f'{name} in Sources'
    if pbx.count(marker) != 2:
        raise SystemExit(f'expected exactly 2 PBX markers for {name}, found {pbx.count(marker)}')

if version in {'v1_p70', 'v1_p71', 'v1_p72', 'v1_p73'} and pbx.count('ZONBackupCoordinator.m in Sources') != 2:
    raise SystemExit('ZONBackupCoordinator.m is not registered exactly once in PBX sources')

header_search_marker = '"$(SRCROOT)/testmod/ZONServices"'
if pbx.count(header_search_marker) != 2:
    raise SystemExit(f'expected ZONServices target header-search path in Release+Debug, found {pbx.count(header_search_marker)}')

print('P65 backup engine contract: PASS')
