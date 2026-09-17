#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
header = ROOT / "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.h"
impl = ROOT / "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m"
version = ROOT / "VERSION"

h = header.read_text()
old_import = '#import <StoreKit/StoreKit.h> // 导入 StoreKit 框架\n\n'
old_iface = '@interface YYYPicker : UIViewController <SKStoreProductViewControllerDelegate>\n- (void)showAppStoreProductPage;\n\n'
if h.count(old_import) != 1:
    raise SystemExit('YYYPicker.h StoreKit import marker mismatch')
if h.count(old_iface) != 1:
    raise SystemExit('YYYPicker.h StoreKit interface marker mismatch')
h = h.replace(old_import, '', 1)
h = h.replace(old_iface, '@interface YYYPicker : UIViewController\n', 1)
header.write_text(h)

m = impl.read_text()
start_marker = '- (void)showAppStoreProductPage {'
if m.count(start_marker) != 1:
    raise SystemExit('YYYPicker.m App Store method marker mismatch')
start = m.index(start_marker)
end = m.rfind('@end')
if end <= start:
    raise SystemExit('YYYPicker.m final @end not found after App Store block')
residual = m[start:end]
required = [
    'SKStoreProductViewController',
    'SKStoreProductParameterITunesItemIdentifier',
    '游戏版本ID',
    'productViewControllerDidFinish:',
]
for token in required:
    if token not in residual:
        raise SystemExit(f'expected App Store token missing before cleanup: {token}')
m = m[:start].rstrip() + '\n@end\n'
impl.write_text(m)

version.write_text('v1_p48_1\n')

for path in (header, impl):
    text = path.read_text()
    forbidden = [
        'StoreKit',
        'SKStoreProductViewController',
        'SKStoreProductParameterITunesItemIdentifier',
        'showAppStoreProductPage',
        'productViewControllerDidFinish',
        '游戏版本ID',
        'App Store product page',
    ]
    for token in forbidden:
        if token in text:
            raise SystemExit(f'residual token {token!r} in {path}')

print('P48.1 StoreKit residual cleanup applied')
