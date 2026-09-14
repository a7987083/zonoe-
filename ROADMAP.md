# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p39`.
- Runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Fixed verification Run `34891852090`: success.
- Real-device regression: user explicitly reported p39 passed.
- Active PBX Sources: **75**.
- All nine active product features remain verified.

## P39-A completed — Active Target Slimming
- Removed only `testmod/category/NSString+Tools.m` and `testmod/category/NSString+Tools.h` plus PBX references.
- PBX active Sources reduced **76 → 75**.
- No floating-window/menu, authorization, UDID, cloud/file, backup/restore, or runtime-hook code was changed.
- P38/P39 exported symbol sets are identical.
- The four unique `NSString(Tools)` selectors are present in P38 and absent in P39 as intended.
- Initial CI failure was verification-only: `grep -q` closed a pipeline early, `strings` received SIGPIPE 141 under `pipefail`. The fixed verification workflow does not change the runtime/source commit.
- P39 A_customer SHA256: `4e5f26da846bc4d9af0f9fce11f55dadf109074b49c9c8ab54f519fb2b89cdd2`.
- Real-device validation passed; P39 is promoted.

## P39-B completed — JDStatusBarNotification dependency audit
Status: `complete_keep_live_dependency`.

Audit evidence:
- Work branch: `work/zonoemenu-v1-p39b-jdstatus-audit`.
- CI Run `34894434619`: **success**.
- Artifact `p39b-jdstatus-audit` / ID `10368133245` / digest `sha256:5b46890e7594493ba4a2ee89e3c1b1a9e77dd66e09134d33577d49adf9ebf5ef`.
- Eight Objective-C implementation units are PBX-active.
- Eleven headers are present.
- `NotificationPresenter.swift` has zero PBX hits and is not compiled.
- Decision: **KEEP_LIVE_DEPENDENCY**.

Proven live product paths:
1. `testmod/菜单/PubgLoad.mm` — cloud-save/download status, download percentage/progress bar, success/failure/load messages.
2. `testmod/Bsphp/main.m` — startup/UDID acquisition, UDID write error/success and continuation status.
3. `testmod/Bsphp/WX_NongShiFu123.mm` — first activation, authorization query, software-source/ad-speed activation and completion status.

Two files import the umbrella header without any JDStatusBarNotification class/API use and are only later include-hygiene candidates:
- `testmod/导入导出/PreferenceManager.m`
- `testmod/工具箱/Hook/JiangHuHook.m`

The audit found no external dynamic JDStatus reference and no internal `+load`, constructor, swizzle, fishhook/rebind, or `dlopen` automatic entry. Those findings do not make the library removable because direct live calls already prove it is required.

## P39 active-target audit closure
All previously uncertain dependency units now have a decision:
- AFNetworking: keep — live dependency.
- MBProgressHUD: keep — live dependency.
- SCLAlertView: keep — live dependency.
- SSZipArchive/minizip: keep — live dependency.
- SVProgressHUD: keep — live dependency.
- JDStatusBarNotification: keep — live dependency.
- `NSString+Tools`: removed and device-verified in P39.

Therefore the active-target deletion audit is complete at **75 Sources**. Do not continue deleting vendor units without new evidence.

## Next development phase — v1_p40 source-layout and dependency hygiene
Start from the immutable, device-verified P39 runtime. P40 should begin with an audit, not a bulk rename/move.

Scope:
1. Inventory canonical `testmod/` directories and identify obsolete naming/layout debt, duplicate-purpose folders, stale headers/imports and implementation-heavy headers.
2. First low-risk include-hygiene candidates are the stale JDStatus imports in `PreferenceManager.m` and `JiangHuHook.m`; treat these as source-cleanliness changes, not evidence to remove the JDStatus library.
3. Avoid renaming/moving active sources until every PBX/header/import path is mapped and a guarded transformation can update them atomically.
4. Preserve the 75-source active target and all nine verified product features unless a new explicit audit proves a source removable.
5. Every runtime/source change still requires contracts, Registry smoke, Module ABI, A_customer/B_debug arm64+arm64e builds and device regression before promotion.

## Protected units
Keep protected until explicit proof says otherwise:
- Floating window/menu entry: `NSObject+UI`, `JHDragView`, `PopupMenuVC`, coordinator/renderer/event bridge/dispatcher.
- Authorization and UDID acquisition paths.
- Remote download, VIP cloud save, local-file browser, backup/restore, clear-data, clear-auth.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind and other runtime hook paths.
- All retained vendor units listed above.

## Next task
Begin **P40 audit only** for canonical source layout, naming and include/dependency hygiene. Do not bulk-move or rename product sources until the audit produces exact PBX/import dependency maps and a reversible cleanup plan.
