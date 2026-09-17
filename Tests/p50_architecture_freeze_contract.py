#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
pbx = (root / 'testmod.xcodeproj' / 'project.pbxproj').read_text(errors='replace')
freeze = (root / 'P50_ARCHITECTURE_FREEZE.md').read_text(errors='replace')
matrix = (root / 'P50_FINAL_STATUS_MATRIX.md').read_text(errors='replace')

# Count only PBXSourcesBuildPhase membership lines, matching the P49 CI contract.
active_sources = len(re.findall(r'/\* .* in Sources \*/,\s*$', pbx, flags=re.MULTILINE))
if active_sources != 78:
    raise SystemExit(f'expected 78 active Sources entries, got {active_sources}')

for forbidden in ('Network.framework', 'StoreKit.framework'):
    if forbidden in pbx:
        raise SystemExit(f'forbidden removed framework returned to PBX: {forbidden}')

required_paths = [
    'testmod/ZONBootstrap/ZONBootstrap.m',
    'testmod/ZONCore/ZONFeatureRegistry.m',
    'testmod/ZONCore/ZONFeatureDispatcher.m',
    'testmod/ZONCore/ZONModuleLoader.m',
    'testmod/ZONServices/ZONAuthorizationCoordinator.m',
    'testmod/ZONServices/ZONUDIDBridge.m',
    'testmod/ZONServices/ZonoeUDIDAPI.m',
    'testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m',
]
for rel in required_paths:
    if not (root / rel).is_file():
        raise SystemExit(f'missing frozen boundary source: {rel}')

required_markers = [
    'v1_p49',
    '4cebe094ad7a4dd554e8266af34dcf3abe04902a',
    '35195152912',
    '4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac',
    'Registry/Dispatcher',
]
for marker in required_markers:
    if marker not in freeze:
        raise SystemExit(f'freeze document missing marker: {marker}')
    if marker not in matrix:
        raise SystemExit(f'final matrix missing marker: {marker}')

matrix_markers = [
    'Architecture ownership matrix',
    'Allowed post-P50 changes',
    'Changes that require an explicitly named new stage',
    'Mandatory gates for future runtime stages',
    'P41-P49 structural work is considered closed',
]
for marker in matrix_markers:
    if marker not in matrix:
        raise SystemExit(f'final matrix missing policy marker: {marker}')

print('P50_ARCHITECTURE_FREEZE_CONTRACT=PASS')
print('P50_FINAL_STATUS_MATRIX=PASS')
print('ACTIVE_SOURCES=78')
print('NETWORK_FRAMEWORK_ABSENT=true')
print('STOREKIT_FRAMEWORK_ABSENT=true')
