#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

REMOVE_PATHS = [
    'testmod/AppStore/SomeOtherFile.h',
    'testmod/AppStore/SomeOtherFile.m',
    'testmod/category/LRKeychain.h',
    'testmod/category/LRKeychain.m',
    'testmod/views/AESUtility.h',
    'testmod/views/AESUtility.m',
    'testmod/视图菜单/NSObject+Plist.h',
    'testmod/视图菜单/NSObject+Plist.m',
    'testmod/菜单/菜单UI/NSObject+Menu.h',
    'testmod/菜单/菜单UI/NSObject+Menu.mm',
    'testmod/菜单/Localize.h',
    'testmod/菜单/Localize.m',
    'testmod/菜单/TDAlternateIconCell.h',
    'testmod/菜单/TDAlternateIconCell.m',
    'testmod/视图菜单/WMDragView.h',
    'testmod/视图菜单/WMDragView.m',
    'testmod/category/TFJGVGLGKFTVCSV.h',
    'testmod/category/TFJGVGLGKFTVCSV.m',
    'testmod/视图菜单/HeeeNoScreenShotView.h',
    'testmod/视图菜单/HeeeNoScreenShotView.m',
    'testmod/category/UIWindow+DLGMemUI.h',
    'testmod/category/UIWindow+DLGMemUI.m',
    'testmod/category/lz4.h',
    'testmod/category/lz4.c',
    'testmod/category/mem.h',
    'testmod/category/mem.c',
    'testmod/category/mem_utils.h',
    'testmod/category/mem_utils.c',
    'testmod/category/search_result.h',
    'testmod/category/search_result.c',
    'testmod/category/search_result_def.h',
    'testmod/views/DLGMem.h',
    'testmod/views/DLGMem.m',
    'testmod/views/DLGMemUI.h',
    'testmod/views/DLGMemUI.m',
    'testmod/views/DLGMemUIView.h',
    'testmod/views/DLGMemUIView.m',
    'testmod/views/DLGMemUIViewCell.h',
    'testmod/views/DLGMemUIViewCell.m',
    'testmod/views/DLGMemUIViewDelegate.h',
    'testmod/工具箱/MemScan.h',
    'testmod/工具箱/jianghu.h',
    'testmod/工具箱/jianghu.mm',
    'testmod/JRMemory.framework',
]

NOISE_PATHS = [
    'Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.deb',
    'Bsphp/WX_NongShiFu123_副本.txt',
    'testmod/Bsphp/WX_NongShiFu123_副本.txt',
    'testmod.xcodeproj/project.xcworkspace/xcuserdata',
    'testmod.xcodeproj/xcuserdata',
]

PBX_NAMES = sorted({Path(p).name for p in REMOVE_PATHS if not p.endswith('.framework')}) + ['JRMemory.framework']

IMPORT_EDITS = {
    'testmod/Bsphp/WX_NongShiFu123.mm': [
        '#import "jianghu.h"\n',
        '#import "NSObject+Menu.h"\n',
    ],
    'testmod/菜单/PubgLoad.mm': [
        '#import "jianghu.h"\n',
    ],
    'testmod/导入导出/fuhzu.m': [
        '#import "SomeOtherFile.h"\n',
    ],
}


def run(*args: str) -> None:
    subprocess.check_call(args)


def tracked(path: str) -> bool:
    return subprocess.call(
        ['git', 'ls-files', '--error-unmatch', path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ) == 0


def main() -> None:
    for file_name, removals in IMPORT_EDITS.items():
        p = Path(file_name)
        text = p.read_text()
        for item in removals:
            if text.count(item) != 1:
                raise SystemExit(f'{file_name}: expected exactly one {item.strip()!r}, found {text.count(item)}')
            text = text.replace(item, '', 1)
        p.write_text(text)

    fuzhu = Path('testmod/导入导出/fuzhu.h')
    text = fuzhu.read_text()
    old = '- (void)onConsoleButtonTapped;\n'
    if text.count(old) != 1:
        raise SystemExit(f'fuzhu.h onConsoleButtonTapped declaration count={text.count(old)}')
    fuzhu.write_text(text.replace(old, '', 1))

    # Every PBX line that names a retired file is metadata for that file:
    # PBXBuildFile, PBXFileReference, PBXGroup child, Sources/Headers/Frameworks phase.
    # Remove all of those lines by the exact PBX comment prefix. This avoids leaving
    # header-phase entries such as "AESUtility.h in Headers" behind.
    pbx = Path('testmod.xcodeproj/project.pbxproj')
    lines = pbx.read_text().splitlines(True)
    kept = []
    removed_lines = []
    for line in lines:
        if any(f'/* {name}' in line for name in PBX_NAMES):
            removed_lines.append(line)
        else:
            kept.append(line)
    if not removed_lines:
        raise SystemExit('PBX prune removed no lines')
    pbx.write_text(''.join(kept))

    for path in REMOVE_PATHS + NOISE_PATHS:
        if Path(path).exists() or tracked(path):
            run('git', 'rm', '-r', '--ignore-unmatch', '--', path)

    Path('VERSION').write_text('v1_p34\n')

    required = [
        'testmod/ZONCore/ZONFeatureRegistry.m',
        'testmod/ZONCore/ZONFeatureDispatcher.m',
        'testmod/工具箱/Hook/JiangHuHook.m',
        'testmod/工具箱/变速器/HookClass.m',
        'testmod/工具箱/变速器/ImgTool.m',
        'testmod/菜单/PubgLoad.mm',
        'testmod/菜单/SandboxBrowserVC.m',
        'testmod/导入导出/daochucd.m',
        'testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m',
        'testmod/Bsphp/WX_NongShiFu123.mm',
        'testmod/Bsphp/main.m',
    ]
    for path in required:
        if not Path(path).is_file():
            raise SystemExit(f'required active file missing: {path}')

    pbx_text = pbx.read_text()
    for name in PBX_NAMES:
        if name in pbx_text:
            raise SystemExit(f'stale PBX reference: {name}')

    active_patterns = [
        'jianghu.h', 'NSObject+Menu.h', 'SomeOtherFile.h', 'DLGMem',
        'TDAlternateIconCell', 'WMDragView', 'HeeeNoScreenShotView',
        'TFJGVGLGKFTVCSV', 'LRKeychain', 'AESUtility'
    ]
    for pattern in active_patterns:
        proc = subprocess.run(
            ['git', 'grep', '-n', '--', pattern, '--', 'testmod'],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        for line in proc.stdout.splitlines():
            body = line.split(':', 2)[-1].strip()
            if body.startswith('#import') or body.startswith('#include'):
                raise SystemExit(f'stale active import for {pattern}: {line}')

    run('git', 'diff', '--check')
    print(f'PBX lines removed: {len(removed_lines)}')
    print(f'Product/noise paths scheduled for removal: {len(REMOVE_PATHS) + len(NOISE_PATHS)}')
    print('p34 cleanup application: PASS')


if __name__ == '__main__':
    main()
