# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p38`.
- Runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Audit Run `34840224717`: success.
- CI Run `34840451436`: success.
- Real-device regression: user explicitly reported p38 passed.
- Because p38 `testmod/`, Xcode project and A_customer dylib are byte-identical to p36/p37 runtime, this device pass also covers the p36-p38 runtime lineage, including the Zonoe-to-web UDID fallback.

## P38 completed — Canonical Product Source Finalization
- All **76** PBX product Sources resolve under `testmod/`; root product source count is **0**.
- Removed the remaining root `Bsphp/`, `菜单/`, `导入导出/`, and `视图菜单/` mirrors after proving they contained no root-only files.
- Canonical product source surface is now **`testmod/` only**.
- All nine active product features remain verified.
- P38 A_customer SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`.

## Next development phase — v1_p39
Status: `planned`.

### Goal
Audit the active 76-source target inside canonical `testmod/` only and remove obsolete helpers/dependency units without changing verified product behavior.

### Audit rules
1. Do not delete files merely because ordinary textual call sites are zero.
2. Protect Objective-C `+load`, constructors, swizzles, fishhook/rebind, `dlopen`, runtime hook, authorization, UDID, file, cloud-save, backup/restore and menu-entry paths until explicit proof permits deletion.
3. Audit third-party stacks as dependency units rather than deleting isolated source files.
4. Re-check AFNetworking, MBProgressHUD, SCLAlertView, JDStatusBarNotification and similar helper/vendor groups for actual build/runtime reachability.
5. Preserve all nine verified menu features.
6. Every accepted deletion batch must pass contracts, Registry smoke, Module ABI, A_customer and B_debug full builds before device testing.

## Later backlog
- After P39 active-target slimming stabilizes, start directory/naming cleanup.
- Continue moving implementation-heavy headers into `.m` files only where it reduces coupling without adding unnecessary abstraction.
- Keep the rule: delete when possible, merge when appropriate, add interfaces only when a real extension boundary exists.

## Next task
Start P39 with a fresh active-target reachability/dependency audit of the 76 compiled sources under `testmod/`, produce a deletion candidate list with evidence, then apply only proven-safe removals.
