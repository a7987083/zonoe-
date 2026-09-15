#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

P39 = "613882da7068795533c530d45775f7ae5f79ed56"
ACTIVE_FEATURES = [
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
JDSTATUS_SOURCES = [
    "JDSBNotificationAnimator.m",
    "JDSBNotificationStyleCache.m",
    "JDSBNotificationView.m",
    "JDSBNotificationViewController.m",
    "JDSBNotificationWindow.m",
    "JDStatusBarNotificationPresenter.m",
    "JDStatusBarNotificationStyle.m",
    "UIApplication+JDSB_MainWindow.m",
]
PROTECTED_UNCHANGED = [
    "testmod/Bsphp/main.m",
    "testmod/Bsphp/WX_NongShiFu123.mm",
    "testmod/ZONBootstrap/ZONBootstrap.m",
    "testmod/ZONCore/ZONModuleLoader.m",
    "testmod/ZONCore/ZONFeatureRegistry.m",
    "testmod/ZONCore/ZONMenuEventBridge.m",
    "testmod/ZONCore/ZONMenuCoordinator.m",
    "testmod/视图菜单/NSObject+UI.m",
    "testmod/菜单/PopupMenuVC.m",
    "testmod/菜单/JHDragView.m",
    "testmod/菜单/PubgLoad.mm",
    "testmod/菜单/SandboxBrowserVC.m",
    "testmod/导入导出/daochucd.m",
    "testmod/导入导出/fuhzu.m",
    "testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m",
    "testmod/工具箱/Hook/JiangHuHook.m",
    "testmod/工具箱/变速器/HookClass.m",
    "testmod/工具箱/变速器/ImgTool.m",
    "testmod/工具箱/变速器/fishhook/fishhook.c",
]


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True, errors="replace").strip()


def fail(message: str) -> None:
    raise SystemExit("p40-zero-behavior-refactor-contract: FAIL: " + message)


def show(ref: str, path: str) -> str:
    return subprocess.check_output(["git", "show", f"{ref}:{path}"], text=True, errors="replace")


def tree(ref: str, path: str) -> str:
    return out("git", "rev-parse", f"{ref}:{path}")


def active_source_names(pbx: str) -> list[str]:
    names: list[str] = []
    for name in re.findall(r"/\* ([^*/\n]+?) in Sources \*/", pbx):
        if name not in names:
            names.append(name)
    return names


if Path("VERSION").read_text().strip() != "v1_p40":
    fail("VERSION must be v1_p40")

expected_product_diff = {
    "VERSION",
    "testmod/ZONCore/ZONFeatureDispatcher.h",
    "testmod/ZONCore/ZONFeatureDispatcher.m",
    "testmod/导入导出/JDStatusBarNotification/Public/NotificationPresenter.swift",
    "testmod/导入导出/PreferenceManager.m",
}
actual_product_diff = set(
    filter(
        None,
        out(
            "git",
            "diff",
            "--name-only",
            P39,
            "HEAD",
            "--",
            "VERSION",
            "testmod",
            "testmod.xcodeproj",
        ).splitlines(),
    )
)
if actual_product_diff != expected_product_diff:
    fail(f"unexpected product diff vs p39: {sorted(actual_product_diff)}")

pbx = Path("testmod.xcodeproj/project.pbxproj").read_text(errors="replace")
if len(active_source_names(pbx)) != 75:
    fail("active PBX source count must remain 75")
for source in JDSTATUS_SOURCES:
    if pbx.count(f"{source} in Sources") < 1:
        fail(f"JDStatus active source missing from PBX: {source}")
if "NotificationPresenter.swift" in pbx:
    fail("uncompiled Swift wrapper unexpectedly has a PBX reference")
if Path("testmod/导入导出/JDStatusBarNotification/Public/NotificationPresenter.swift").exists():
    fail("uncompiled NotificationPresenter.swift should be retired")

pref_path = Path("testmod/导入导出/PreferenceManager.m")
pref = pref_path.read_text(errors="replace")
if '#import "JDStatusBarNotification.h"' in pref:
    fail("PreferenceManager still imports unused JDStatus header")
base_pref = show(P39, str(pref_path))
expected_pref = base_pref.replace('#import "JDStatusBarNotification.h"\n', "", 1)
if pref != expected_pref:
    fail("PreferenceManager changed beyond removal of the unused import")

dispatch_h_path = Path("testmod/ZONCore/ZONFeatureDispatcher.h")
dispatch_h = dispatch_h_path.read_text(errors="replace")
for leaked in [
    "ZONFeatureRegistry.h",
    "SandboxBrowserVC.h",
    "daochucd.h",
    "YYYPicker.h",
    "PubgLoad.h",
    "ImgTool.h",
    "SVProgressHUD.h",
    "WX_NongShiFu123.h",
]:
    if leaked in dispatch_h:
        fail(f"Dispatcher public header still leaks implementation dependency: {leaked}")
for api in [
    "ZONTmpDirectoryPath",
    "ZONEnsureTmpDirectory",
    "ZONClearGameDataPreservingTmp",
    "ZONPresentClearGameDataConfirmation",
    "ZONPresentClearAuthorizationConfirmation",
    "ZONDispatchMigratedActionForLegacyTag",
    "ZONDispatchMigratedToggleForLegacyTag",
]:
    if api not in dispatch_h:
        fail(f"Dispatcher public API disappeared: {api}")

dispatch_m_path = Path("testmod/ZONCore/ZONFeatureDispatcher.m")
dispatch_m = dispatch_m_path.read_text(errors="replace")
for dependency in [
    "ZONFeatureRegistry.h",
    "SandboxBrowserVC.h",
    "daochucd.h",
    "YYYPicker.h",
    "PubgLoad.h",
    "ImgTool.h",
    "SVProgressHUD.h",
    "WX_NongShiFu123.h",
]:
    if f'#import "{dependency}"' not in dispatch_m:
        fail(f"Dispatcher implementation dependency not localized in .m: {dependency}")
base_dispatch_m = show(P39, str(dispatch_m_path))
body_marker = "NSString *ZONTmpDirectoryPath(void)"
if body_marker not in base_dispatch_m or body_marker not in dispatch_m:
    fail("Dispatcher body marker missing")
if base_dispatch_m[base_dispatch_m.index(body_marker):] != dispatch_m[dispatch_m.index(body_marker):]:
    fail("Dispatcher executable body changed; p40 phase 1 must be import-only")

for path in PROTECTED_UNCHANGED:
    if tree(P39, path) != tree("HEAD", path):
        fail(f"protected runtime source changed: {path}")

registry = Path("testmod/ZONCore/ZONFeatureRegistry.m").read_text(errors="replace")
for identifier in ACTIVE_FEATURES:
    if f'@"{identifier}"' not in registry:
        fail(f"active feature missing from registry: {identifier}")
if "runtime.placeholder-203" in registry:
    fail("retired placeholder 203 reappeared")

main = Path("testmod/Bsphp/main.m").read_text(errors="replace")
if "+(void)load" not in main and "+ (void)load" not in main:
    fail("protected +load startup entry missing")
if "ZONBootstrapStart" not in main or "ZONStartCustomerAuthorization" not in main:
    fail("startup/authorization chain marker missing")

hook = Path("testmod/工具箱/Hook/JiangHuHook.m").read_text(errors="replace")
if "CHConstructor" not in hook:
    fail("protected CaptainHook constructor missing")

udid = Path("testmod/ZONServices/ZONUDIDBridge.h").read_text(errors="replace")
for marker in [
    "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
    "unable to open zonoe://udid; using web fallback",
    "ZONUDIDBridgeStoreUDID",
]:
    if marker not in udid:
        fail(f"UDID bridge marker missing: {marker}")

pubg = Path("testmod/菜单/PubgLoad.mm").read_text(errors="replace")
for marker in [
    "JDStatusBarNotificationPresenter sharedPresenter",
    "displayProgressBarWithPercentage:progress",
    "checkCloudSaveStatus",
]:
    if marker not in pubg:
        fail(f"cloud-save/notification behavior marker missing: {marker}")

print("p40-zero-behavior-refactor-contract: PASS (75 sources; product logic preserved)")
