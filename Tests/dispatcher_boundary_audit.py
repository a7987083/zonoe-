#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DISPATCHER = ROOT / "testmod/ZONCore/ZONFeatureDispatcher.h"
EVENT_BRIDGE = ROOT / "testmod/ZONCore/ZONMenuEventBridge.m"
PBX = ROOT / "testmod.xcodeproj/project.pbxproj"


def fail(message: str) -> None:
    print(f"dispatcher-audit: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def require_once(text: str, needle: str, label: str) -> None:
    count = text.count(needle)
    if count != 1:
        fail(f"expected one {label}, found {count}: {needle}")


def require_order(text: str, needles: list[str], label: str) -> None:
    positions = []
    for needle in needles:
        pos = text.find(needle)
        if pos < 0:
            fail(f"missing {label}: {needle}")
        positions.append(pos)
    if positions != sorted(positions):
        fail(f"unexpected {label} order")


dispatcher = DISPATCHER.read_text()
event_bridge = EVENT_BRIDGE.read_text()
pbx = PBX.read_text()

# Active compilation ownership: EventBridge is a target source; Dispatcher is still header-only.
require(pbx, "ZONMenuEventBridge.m in Sources", "EventBridge target source")
require(pbx, "ZONFeatureRegistry.m in Sources", "Registry target source")
if "ZONFeatureDispatcher.m" in pbx:
    fail("Dispatcher .m is already registered; audit assumptions are stale")
require_once(event_bridge, '#import "ZONFeatureDispatcher.h"', "EventBridge Dispatcher import")
require_once(event_bridge, "ZONDispatchMigratedActionForLegacyTag(legacyTag, presenter)", "action bridge call")
require_once(event_bridge, "ZONDispatchMigratedToggleForLegacyTag(legacyTag, enabled)", "toggle bridge call")

# Header-owned implementation inventory. These are the bodies that a later split must preserve.
for signature in [
    "static inline NSString *ZONTmpDirectoryPath(void)",
    "static inline BOOL ZONEnsureTmpDirectory(void)",
    "static inline void ZONClearGameDataPreservingTmp(void)",
    "static inline void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)",
    "static inline void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)",
    "static inline BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,",
    "static inline BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)",
]:
    require(dispatcher, signature, "Dispatcher inline function")

# Registry action routes and order must remain stable.
action_ids = [
    '@"base.remote-download"',
    '@"base.cloud-save"',
    '@"base.local-files"',
    '@"data.backup-save"',
    '@"data.restore-save"',
    '@"data.clear-game-data"',
    '@"auth.clear-records"',
]
require_order(dispatcher, action_ids, "action route")
for needle, label in [
    ("[[PubgLoad alloc] yuanchengdwon];", "remote-download handler"),
    ("[[PubgLoad alloc] checkCloudSaveStatus];", "cloud-save handler"),
    ("SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];", "local-files handler"),
    ("[[daochucd alloc] backupasd];", "backup handler"),
    ("[[YYYPicker alloc] addBtnAction];", "restore handler"),
    ("ZONPresentClearGameDataConfirmation(hostViewController);", "clear-game confirmation"),
    ("ZONPresentClearAuthorizationConfirmation(hostViewController);", "clear-authorization confirmation"),
]:
    require(dispatcher, needle, label)

# Protected destructive semantics: confirmation boundary, tmp invariant and delayed exits.
for needle, label in [
    ('alertControllerWithTitle:@"清除游戏数据"', "clear-game confirmation title"),
    ('alertControllerWithTitle:@"清除授权记录"', "clear-authorization confirmation title"),
    ("ZONClearGameDataPreservingTmp();", "clear-game destructive handoff"),
    ("[[WX_NongShiFu123 alloc] deletekm];", "authorization delete handoff"),
    ('stringByAppendingPathComponent:@"tmp"', "tmp path invariant"),
    ('stringByAppendingString:@"/Documents/"', "Documents deletion path"),
    ('stringByAppendingString:@"/Library/"', "Library deletion path"),
    ("removePersistentDomainForName:appDomain", "NSUserDefaults domain cleanup"),
]:
    require(dispatcher, needle, label)
if dispatcher.count("exit(0);") != 2:
    fail(f"expected two protected delayed exits, found {dispatcher.count('exit(0);')}")

# Runtime toggle routes, persistence keys and ImgTool side effects.
require_order(dispatcher, ['@"runtime.iap-noads"', '@"runtime.ad-speed"', '@"runtime.placeholder-203"'], "toggle route")
for needle, label in [
    ('forKey:@"NNGG"', "legacy NNGG integer key"),
    ('forKey:@"NNGGNNGG"', "IAP/no-ads enable key"),
    ("[ImgTool share].NeiGou = on;", "IAP/no-ads runtime side effect"),
    ('forKey:@"AADD"', "legacy AADD integer key"),
    ('forKey:@"AADDAADD"', "ad-speed enable key"),
    ("[ImgTool share].ADSpeed = on;", "ad-speed runtime side effect"),
    ('NSLog(@"人物血量");', "placeholder behavior"),
]:
    require(dispatcher, needle, label)

# EventBridge owns slider persistence/runtime synchronization; Dispatcher split must not absorb or alter it.
for needle, label in [
    ('@"NNGGNNGG"', "EventBridge IAP/no-ads sync key"),
    ('@"AADDAADD"', "EventBridge ad-speed enable sync key"),
    ('@"AADDssppeedd"', "EventBridge ad-speed numeric key"),
    ("[ImgTool share].NeiGou", "EventBridge NeiGou sync"),
    ("[ImgTool share].ADSpeed", "EventBridge ADSpeed sync"),
    ("[ImgTool share].ADBiansu", "EventBridge ADBiansu sync"),
]:
    require(event_bridge, needle, label)

print("dispatcher-audit: PASS")
print("active owner: testmod/ZONCore/ZONFeatureDispatcher.h (header-only via ZONMenuEventBridge.m)")
print("inline functions: 7")
print("action routes: 7")
print("toggle routes: 3")
print("protected destructive routes: clear-game-data, clear-authorization")
