#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = '4c768a6b9717c9bbf07719623ef6bd742c9dce26'

header = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h'
impl = ROOT / 'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m'
pbx = ROOT / 'testmod.xcodeproj/project.pbxproj'
version = (ROOT / 'VERSION').read_text().strip()

if version != 'v1_p48_1':
    raise SystemExit(f'expected VERSION v1_p48_1, got {version!r}')

for path in (header, impl):
    text = path.read_text()
    for token in (
        'StoreKit',
        'SKStoreProductViewController',
        'SKStoreProductParameterITunesItemIdentifier',
        'showAppStoreProductPage',
        'productViewControllerDidFinish',
        '游戏版本ID',
        'App Store product page',
    ):
        if token in text:
            raise SystemExit(f'residual {token!r} in {path}')

h = header.read_text()
if '@interface YYYPicker : UIViewController\n' not in h:
    raise SystemExit('YYYPicker interface changed unexpectedly')
if '- (void)addBtnAction;' not in h or '-(void)yidongwenjian;' not in h:
    raise SystemExit('restore-save public API changed unexpectedly')

changed = subprocess.check_output(
    ['git','diff','--name-only',BASE,'HEAD','--','testmod'],
    cwd=ROOT, text=True
).splitlines()
expected = {
    'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h',
    'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m',
}
if set(changed) != expected:
    raise SystemExit(f'unexpected runtime scope: {changed}')

base_pbx = subprocess.check_output(['git','show',f'{BASE}:testmod.xcodeproj/project.pbxproj'], cwd=ROOT)
if base_pbx != pbx.read_bytes():
    raise SystemExit('PBX changed during StoreKit residual cleanup')

print('P48.1 StoreKit cleanup contract PASS')
