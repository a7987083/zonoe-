#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
VERSION = ROOT / 'VERSION'
ACTION = ROOT / 'testmod/ZONServices/ZONSixButtonActionService.m'
BACKUP_UI = ROOT / 'testmod/导入导出/daochucd.m'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONBackupService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONBackupService.m'
POLICY_H = ROOT / 'testmod/ZONServices/ZONBackupPolicy.h'
POLICY_M = ROOT / 'testmod/ZONServices/ZONBackupPolicy.m'
RESTORE = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'

for path in (VERSION, ACTION, BACKUP_UI, SERVICE_H, SERVICE_M, POLICY_H, POLICY_M, RESTORE, PBX):
    if not path.exists():
        raise SystemExit(f'missing required file: {path.relative_to(ROOT)}')

version = VERSION.read_text(encoding='utf-8').strip()
action = ACTION.read_text(encoding='utf-8')
ui = BACKUP_UI.read_text(encoding='utf-8')
service_h = SERVICE_H.read_text(encoding='utf-8')
service_m = SERVICE_M.read_text(encoding='utf-8')
policy_h = POLICY_H.read_text(encoding='utf-8')
policy_m = POLICY_M.read_text(encoding='utf-8')
restore = RESTORE.read_text(encoding='utf-8')
pbx = PBX.read_text(encoding='utf-8')

if version != 'v1_p65':
    raise SystemExit(f'unexpected VERSION: {version}')

# Existing six-button route remains externally stable during P65.
for marker in ('#import "daochucd.h"', '[[daochucd alloc] backupasd]'):
    if marker not in action:
        raise SystemExit(f'backup button route changed unexpectedly: {marker}')

# Public service contract and stages.
for marker in (
    'ZONBackupStagePreparing',
    'ZONBackupStageScanning',
    'ZONBackupStageCopyingDocuments',
    'ZONBackupStageCopyingLibrary',
    'ZONBackupStageArchiving',
    'ZONBackupStageCompleted',
    'createBackupNamed:',
    'largeItemDecision:',
    'progress:',
    'completion:',
):
    if marker not in service_h:
        raise SystemExit(f'missing backup API marker: {marker}')

# Engine owns manifest/scanning/copy/staging/archive, not presentation.
for marker in (
    'ZONBackupManifestItem',
    'manifestForRootName:',
    'copyManifest:',
    'tmp/zonoe',
    '@"Documents"',
    '@"Library"',
    'SSZipArchive createZipFileAtPath:',
    'contentsOfDirectoryAtURL:',
    'copyItemAtURL:',
):
    if marker not in service_m:
        raise SystemExit(f'missing backup engine marker: {marker}')

for forbidden in (
    '#import <UIKit/UIKit.h>',
    'SVProgressHUD',
    'UIAlertController',
    'UIDocumentInteractionController',
    'JHPP',
):
    if forbidden in service_m or forbidden in policy_m:
        raise SystemExit(f'presentation dependency leaked into backup engine/policy: {forbidden}')

# Policy owns the legacy exclusions and 50 MB rule.
for marker in (
    '50ULL * 1024ULL * 1024ULL',
    '@"Documents/zonoe"',
    '@"Library/HeimdallrBU"',
    '@"Library/Caches"',
    '@"Library/UnityCache"',
    'shouldExcludeContentsAtRelativePath:',
):
    if marker not in policy_m and marker not in policy_h:
        raise SystemExit(f'missing backup policy marker: {marker}')

# daochucd is now a UI adapter and must no longer own the legacy backup engine helpers.
for marker in (
    '#import "ZONBackupService.h"',
    'createBackupNamed:',
    'requestBackupDecisionForRelativePath:',
    'shareArchiveAtURL:',
):
    if marker not in ui:
        raise SystemExit(f'missing backup UI-adapter marker: {marker}')

for forbidden in (
    '#import "SSZipArchive.h"',
    'folderSizeAtPath:',
    'copyBackupItems:',
    'copyBackupTopLevelFrom:',
    'copyContentsFrom:',
    'clearDirectory:',
    'ensureDirectoryExists:',
    'createZipFileAtPath:',
):
    if forbidden in ui:
        raise SystemExit(f'legacy backup engine logic still present in daochucd: {forbidden}')

# Restore compatibility: current restore path still discovers Documents / Library recursively.
for marker in (
    'findTargetDir:@"Documents"',
    'findTargetDir:@"Library"',
    '@"__MACOSX"',
    '@".DS_Store"',
    '@"Preferences"',
    'unzipFileAtPath:',
):
    if marker not in restore:
        raise SystemExit(f'restore compatibility marker missing: {marker}')

# PBX source membership for both new implementation files.
for name in ('ZONBackupService.m', 'ZONBackupPolicy.m'):
    marker = f'{name} in Sources'
    if pbx.count(marker) != 2:
        raise SystemExit(f'expected exactly 2 PBX markers for {name}, found {pbx.count(marker)}')

print('P65_BACKUP_ENGINE_CONTRACT=PASS')
print('VERSION=v1_p65')
print('BACKUP_BUTTON_ROUTE_PRESERVED=true')
print('BACKUP_ENGINE_UI_FREE=true')
print('DUPLICATE_DAOCHUCD_COPY_ENGINE_REMOVED=true')
print('POLICY_CENTRALIZED=true')
print('RESTORE_DOCUMENTS_LIBRARY_COMPATIBILITY_LOCKED=true')
