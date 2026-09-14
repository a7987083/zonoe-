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

## Current development phase — P39-B JDStatusBarNotification dependency audit
Status: `audit_next`.

Audit `JDStatusBarNotification` as one complete dependency unit. The group contains 8 active source files and must not be slimmed file-by-file.

Required evidence before any deletion decision:
1. Enumerate all eight PBX-active implementation files and associated public/private/umbrella headers.
2. Map every product import and every public API call site under canonical `testmod/`.
3. Search dynamic/runtime use: `NSClassFromString`, selectors, categories, notification names, swizzles, `+load`, constructors, and indirect UI helpers.
4. Identify which current feature path reaches the dependency, if any.
5. Decide one of three outcomes only after evidence: keep whole group, replace whole dependency boundary, or remove whole group.
6. If removal is proven safe, use a guarded script and require contract tests, 9-feature Registry smoke, Module ABI, A_customer/B_debug builds, arm64/arm64e, exported-symbol/ObjC metadata diff, then real-device test.

## Protected units
Keep protected until explicit proof says otherwise:
- Floating window/menu entry: `NSObject+UI`, `JHDragView`, `PopupMenuVC`, coordinator/renderer/event bridge/dispatcher.
- Authorization and UDID acquisition paths.
- Remote download, VIP cloud save, local-file browser, backup/restore, clear-data, clear-auth.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind and other runtime hook paths.
- AFNetworking, MBProgressHUD, SCLAlertView, SSZipArchive/minizip, SVProgressHUD remain retained based on active dependency evidence.

## Later backlog
- After P39-B dependency audit stabilizes, continue active-target vendor/helper unit audits one complete unit at a time.
- Then start directory/naming cleanup inside canonical `testmod/`.
- Continue splitting implementation-heavy headers only where it reduces coupling without adding unnecessary abstraction.
- Keep the rule: delete when possible, merge when appropriate, add interfaces only when a real extension boundary exists.

## Next task
Execute **P39-B audit only** for `JDStatusBarNotification`. Do not delete anything until exact imports, API calls, runtime use, and feature-path reachability are proven.
