#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
registry = (root / 'testmod/ZONCore/ZONFeatureRegistry.m').read_text(errors='replace')
dispatcher = (root / 'testmod/ZONCore/ZONFeatureDispatcher.m').read_text(errors='replace')
version = (root / 'VERSION').read_text().strip()

expected = {
    'base.remote-download': 1,
    'base.cloud-save': 2,
    'base.local-files': 3,
    'data.backup-save': 100,
    'data.restore-save': 101,
    'data.clear-game-data': 102,
    'auth.clear-records': 103,
    'runtime.iap-noads': 201,
    'runtime.ad-speed': 202,
}

for identifier, tag in expected.items():
    if f'@"{identifier}"' not in registry:
        raise SystemExit(f'missing registry identifier: {identifier}')
    if not re.search(rf'@"{re.escape(identifier)}".*?ZONFeatureLegacyTagKey:@{tag}\b', registry):
        raise SystemExit(f'registry tag mismatch for {identifier}: expected {tag}')

registry_identifiers = re.findall(r'ZONFeatureIdentifierKey:@"([^"]+)"', registry)
if registry_identifiers != list(expected.keys()):
    raise SystemExit(f'registry order/contents changed: {registry_identifiers}')
if len(set(registry_identifiers)) != 9:
    raise SystemExit('registry identifiers are not exactly nine unique built-ins')

action_ids = re.findall(r'@"((?:base|data|auth)\.[^"]+)": \^BOOL', dispatcher)
toggle_ids = re.findall(r'@"(runtime\.[^"]+)": \^BOOL', dispatcher)
if action_ids != list(expected.keys())[:7]:
    raise SystemExit(f'action route drift: {action_ids}')
if toggle_ids != list(expected.keys())[7:]:
    raise SystemExit(f'toggle route drift: {toggle_ids}')

required_behavior_markers = [
    '[[PubgLoad alloc] yuanchengdwon]',
    'ZONEnsureTmpDirectory();\n                [[PubgLoad alloc] checkCloudSaveStatus]',
    '[[SandboxBrowserVC alloc] init]',
    '[[daochucd alloc] backupasd]',
    '[[YYYPicker alloc] addBtnAction]',
    'ZONPresentClearGameDataConfirmation(host)',
    'ZONPresentClearAuthorizationConfirmation(host)',
    '[[WX_NongShiFu123 alloc] deletekm]',
    '(int64_t)(5 * NSEC_PER_SEC)',
    '(int64_t)(3 * NSEC_PER_SEC)',
    '@"NNGG", @"NNGGNNGG"',
    '[ImgTool share].NeiGou = on',
    '@"AADD", @"AADDAADD"',
    '[ImgTool share].ADSpeed = on',
    '[defaults synchronize]',
]
for marker in required_behavior_markers:
    if marker not in dispatcher:
        raise SystemExit(f'behavior marker missing: {marker}')

if version != 'v1_p51':
    raise SystemExit(f'expected VERSION v1_p51, got {version}')

print('P51_NINE_FEATURE_BEHAVIOR_CONTRACT=PASS')
print('REGISTERED_FEATURES=9')
print('ACTION_ROUTES=7')
print('TOGGLE_ROUTES=2')
print('PROMOTED_SELECTORS_AND_KEYS_PRESERVED=true')
