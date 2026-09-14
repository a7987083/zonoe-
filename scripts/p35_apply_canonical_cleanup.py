#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

P34_BASELINE = "cd9a0ab78158de11f1d51cda7461dbc6dd60f956"

ROOT_RETIRED_PATHS = [
    "AppStore/SomeOtherFile.h",
    "AppStore/SomeOtherFile.m",
    "JRMemory.framework",
    "category/LRKeychain.h",
    "category/LRKeychain.m",
    "category/TFJGVGLGKFTVCSV.h",
    "category/TFJGVGLGKFTVCSV.m",
    "category/UIWindow+DLGMemUI.h",
    "category/UIWindow+DLGMemUI.m",
    "category/lz4.h",
    "category/lz4.c",
    "category/mem.h",
    "category/mem.c",
    "category/mem_utils.h",
    "category/mem_utils.c",
    "category/search_result.h",
    "category/search_result.c",
    "category/search_result_def.h",
    "工具箱/MemScan.h",
    "工具箱/jianghu.h",
    "工具箱/jianghu.mm",
    "菜单/Localize.h",
    "菜单/Localize.m",
    "菜单/TDAlternateIconCell.h",
    "菜单/TDAlternateIconCell.m",
    "菜单/菜单UI/NSObject+Menu.h",
    "菜单/菜单UI/NSObject+Menu.mm",
    "视图菜单/HeeeNoScreenShotView.h",
    "视图菜单/HeeeNoScreenShotView.m",
    "视图菜单/NSObject+Plist.h",
    "视图菜单/NSObject+Plist.m",
    "视图菜单/WMDragView.h",
    "视图菜单/WMDragView.m",
]

ACTIVE_FEATURE_IDS = [
    "base.remote-download",
    "base.cloud-save",
    "base.local-files",
    "data.backup-save",
    "data.restore-save",
    "data.clear-game-data",
    "auth.clear-records",
    "runtime.iap-noads",
    "runtime.ad-speed",
]


def run(*args: str) -> None:
    subprocess.check_call(args)


def replace_exact(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one replacement target, found {count}: {old!r}")
    p.write_text(text.replace(old, new, 1))


def tracked(path: str) -> bool:
    return subprocess.call(
        ["git", "ls-files", "--error-unmatch", path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ) == 0


def main() -> None:
    if subprocess.call(["git", "merge-base", "--is-ancestor", P34_BASELINE, "HEAD"]) != 0:
        raise SystemExit(f"p34 device baseline {P34_BASELINE} is not an ancestor of HEAD")
    staged_diff = subprocess.check_output(
        ["git", "diff", "--name-only", f"{P34_BASELINE}..HEAD"], text=True
    ).splitlines()
    unexpected = [p for p in staged_diff if p != "scripts/p35_apply_canonical_cleanup.py"]
    if unexpected:
        raise SystemExit(f"unexpected pre-cleanup changes above p34 baseline: {unexpected}")

    # 1) Remove the retired tag-203 placeholder from the canonical registry.
    replace_exact(
        "testmod/ZONCore/ZONFeatureRegistry.m",
        '            @{ ZONFeatureIdentifierKey:@"runtime.placeholder-203", ZONFeatureTitleKey:@"暂无", ZONFeatureSectionKey:@"其他功能", ZONFeatureLegacyTagKey:@203, ZONFeatureKindKey:@(ZONFeatureKindPlaceholder), ZONFeatureRiskKey:@(ZONFeatureRiskLow), ZONFeatureMigratedKey:@YES },\n',
        "",
    )
    replace_exact(
        "testmod/ZONCore/ZONFeatureRegistry.m",
        'ZONSectionDetailKey:@"1 / 2 / 3"',
        'ZONSectionDetailKey:@"内购 / 广告加速"',
    )

    # 2) Remove the placeholder renderer branch, not just the menu metadata.
    replace_exact(
        "testmod/ZONCore/ZONFeatureRenderer.m",
        '        } else if ([identifier isEqualToString:@"runtime.placeholder-203"]) {\n            [contentView addSubview:ZONRenderSwitchRow(feature, 200, panelWidth, target, switchAction)];\n',
        "",
    )

    # 3) Remove the placeholder dispatch behavior and correct stale comments.
    replace_exact(
        "testmod/ZONCore/ZONFeatureDispatcher.m",
        "/// Routes registry-owned actions. All ten built-in features have completed staged\n/// migration, so PopupMenuVC no longer carries per-tag compatibility fallbacks.\n",
        "/// Routes registry-owned actions. All active built-in features are registry-owned,\n/// so PopupMenuVC no longer carries per-tag compatibility fallbacks.\n",
    )
    replace_exact(
        "testmod/ZONCore/ZONFeatureDispatcher.m",
        "/// Toggle/placeholder dispatch for registry-owned runtime controls. This preserves\n/// the exact UserDefaults keys and ImgTool side effects previously used by PopupMenuVC.\n",
        "/// Toggle dispatch for registry-owned runtime controls. This preserves the exact\n/// UserDefaults keys and ImgTool side effects previously used by PopupMenuVC.\n",
    )
    replace_exact(
        "testmod/ZONCore/ZONFeatureDispatcher.m",
        '    if ([identifier isEqualToString:@"runtime.placeholder-203"]) {\n        NSLog(@"人物血量");\n        return YES;\n    }\n\n',
        "",
    )

    # 4) Tighten tests to prove there are exactly nine product features and tag 203 is gone.
    replace_exact(
        "Tests/feature_registry_smoke.m",
        '        require(features.count == 10, @"expected 10 legacy-visible features");\n',
        '        require(features.count == 9, @"expected 9 active product features");\n',
    )
    replace_exact(
        "Tests/feature_registry_smoke.m",
        '            @103:@"auth.clear-records", @201:@"runtime.iap-noads", @202:@"runtime.ad-speed",\n            @203:@"runtime.placeholder-203",\n',
        '            @103:@"auth.clear-records", @201:@"runtime.iap-noads", @202:@"runtime.ad-speed",\n',
    )
    replace_exact(
        "Tests/feature_registry_smoke.m",
        '        require(migratedCount == 10, @"v1_p25 must keep all ten features registry-owned");\n',
        '        require(migratedCount == 9, @"all nine active features must remain registry-owned");\n',
    )
    replace_exact(
        "Tests/feature_registry_smoke.m",
        '        requireSection(@"其他功能", @[@201, @202, @203]);\n',
        '        requireSection(@"其他功能", @[@201, @202]);\n        require(ZONFeatureMetadataForLegacyTag(203) == nil, @"retired legacy tag 203 must not resolve");\n',
    )
    replace_exact(
        "Tests/feature_registry_smoke.m",
        '        NSLog(@"feature registry smoke passed (v1_p25, 10 features, 3 registry-driven sections)");\n',
        '        NSLog(@"feature registry smoke passed (v1_p35, 9 features, 3 registry-driven sections)");\n',
    )
    replace_exact(
        "Tests/dispatcher_contract_smoke.py",
        "    'forKey:@\"AADD\"', 'forKey:@\"AADDAADD\"', '[ImgTool share].ADSpeed = on;',\n    '@\"runtime.placeholder-203\"', 'NSLog(@\"人物血量\");',\n",
        "    'forKey:@\"AADD\"', 'forKey:@\"AADDAADD\"', '[ImgTool share].ADSpeed = on;',\n",
    )
    with Path("Tests/dispatcher_contract_smoke.py").open("a") as f:
        f.write('\nif "runtime.placeholder-203" in IMPL or "人物血量" in IMPL:\n    fail("retired tag-203 placeholder dispatch still present")\n')

    # 5) Remove root-only copies of stacks already retired from canonical testmod in p34.
    for path in ROOT_RETIRED_PATHS:
        if Path(path).exists() or tracked(path):
            run("git", "rm", "-r", "--ignore-unmatch", "--", path)

    Path("VERSION").write_text("v1_p35\n")

    # Safety: preserve all nine user-approved product features and their runtime foundations.
    registry = Path("testmod/ZONCore/ZONFeatureRegistry.m").read_text()
    for identifier in ACTIVE_FEATURE_IDS:
        if f'@"{identifier}"' not in registry:
            raise SystemExit(f"active product feature missing after cleanup: {identifier}")
    if "runtime.placeholder-203" in registry or "@203" in registry:
        raise SystemExit("retired tag 203 still present in registry")

    required_paths = [
        "testmod/Bsphp/main.m",
        "testmod/Bsphp/WX_NongShiFu123.mm",
        "testmod/菜单/PubgLoad.mm",
        "testmod/菜单/SandboxBrowserVC.m",
        "testmod/导入导出/daochucd.m",
        "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m",
        "testmod/工具箱/Hook/JiangHuHook.m",
        "testmod/工具箱/变速器/HookClass.m",
        "testmod/工具箱/变速器/ImgTool.m",
        "testmod/ZONCore/ZONFeatureDispatcher.m",
        "testmod/ZONCore/ZONFeatureRenderer.m",
        "testmod/ZONCore/ZONFeatureRegistry.m",
    ]
    for path in required_paths:
        if not Path(path).is_file():
            raise SystemExit(f"required product path missing: {path}")

    for path in ROOT_RETIRED_PATHS:
        if Path(path).exists():
            raise SystemExit(f"retired root duplicate still exists: {path}")

    run("git", "diff", "--check")
    print(f"retired root paths removed/verified absent: {len(ROOT_RETIRED_PATHS)}")
    print("active feature count target: 9")
    print("p35 canonical cleanup application: PASS")


if __name__ == "__main__":
    main()
