# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, scope, forbidden changes, verification gates, status, and Next Task. Do not rely on chat history for sequencing decisions.

## Current promoted baseline
- Device-verified version: `v1_p42`.
- Runtime/source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI Run `34995566144`: **success**.
- Real-device regression: **passed**.
- Active PBX Sources: **77**.
- Architectures: `arm64 + arm64e`.
- P42 remains the mandatory rollback/device baseline until a later runtime candidate explicitly passes its real-device gate.

## Current development phase
### P44 — Authorization Orchestration Boundary — CI VERIFIED / DEVICE PENDING
- Work branch: `work/zonoemenu-v1-p44-authorization-orchestration-boundary`.
- Test branch: `test/zonoemenu-v1-p44-authorization-orchestration-boundary-build`.
- Product source commit: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- Successful CI head: `d6a110befbbc8c96dfffcae1f942c94b6011fe2d`.
- CI Run `35020232205`: **success**.
- Active PBX Sources: **77 → 78**; sole new active source is `testmod/ZONServices/ZONAuthorizationCoordinator.m`.
- A_customer artifact: `10417242852`, digest `sha256:d9ce3432727b1c2ce5302ad4e732237ac7c45261ebd65cc3e7eda291ae2c71b8`.
- A_customer dylib SHA256: `f8d33f888ea5466217938af1cd338765252effb2cc4eda039a871579346e0435`.
- B_debug artifact: `10417212790`, digest `sha256:2979768f150373160bffd1bddaf45e5d1ba1ee6d9ed1c8cdc05149485abd4a78`.
- Both artifacts contain `arm64 + arm64e`.
- P44/P42 exported symbol sets: **identical**.
- P44/P42 linked load-library sets: **identical**.
- Device status: **pending**. Do not promote P44 until explicit real-device PASS.

## Refactor operating rules
1. One architectural concern per version. Never combine ownership cleanup with behavior, timing, threading, protocol, persistence, UI, or feature changes.
2. Every source-moving phase needs a mechanical/equivalence contract where practical.
3. Every phase must define protected files/symbols/state machines before source changes begin.
4. CI success is not device promotion. A runtime-affecting version becomes the new baseline only after explicit real-device PASS.
5. A failed or untested candidate does not modify the promoted fallback baseline.
6. Preserve `testmod/` + `testmod.xcodeproj` as the canonical runtime/product surface. PBX membership decides whether code is active.
7. Do not delete legacy code until active-target reachability and runtime consumers are proven absent.
8. Do not change `+load`, main-queue sequencing, callback timing, socket retry timing, URL schemes, persistence keys, or authorization continuation as part of structural cleanup.
9. Every runtime candidate records branch, product commit, CI run/status, A_customer artifact, architectures, SHA256, device status, and rollback baseline.
10. `CHANGELOG_DEV.md` records actual changes; `HANDOFF.md` records context/risks; `PROJECT_STATE.json` is machine-readable state; `KNOWN_ISSUES.md` tracks unresolved risks.

## Completed foundation
### P41 — UDID Bridge Compilation Boundary — COMPLETED / DEVICE PASSED
- Source `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`; CI `34959813770` success.
- `ZONUDIDBridge.h` became declaration-only; implementation moved to `ZONUDIDBridge.m`.
- Active Sources 75 → 76. Device passed; superseded by P42.

### P42 — ZonoeUDIDAPI Service Boundary — COMPLETED / CURRENT DEVICE BASELINE
- Source `e87b683a9c868e00d13582c8145bb9368878fee3`; CI `34995566144` success.
- `ZonoeUDIDAPI` moved mechanically from `NSObject+UI.m` to `ZONServices/ZonoeUDIDAPI.m`.
- Active Sources 76 → 77. Device passed.

### P43 — Architecture State Refresh & Remaining Ownership Audit — COMPLETED / RUNTIME UNCHANGED
- Work `work/zonoemenu-v1-p43-architecture-audit`; test `test/zonoemenu-v1-p43-architecture-audit`.
- Audit head `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`; CI `35001000784` success.
- Runtime/PBX remained identical to P42; device test not required.
- P44 target selected: authorization/reset orchestration in `testmod/Bsphp/main.m`.

## P44 implementation definition
### Goal
Separate customer authorization orchestration/reset glue from startup-host ownership without changing customer authorization behavior.

### Implemented scope
The following existing responsibilities were mechanically moved from `testmod/Bsphp/main.m` to `testmod/ZONServices/ZONAuthorizationCoordinator.m`:
- original `deletekm` IMP storage;
- `ZONClearStoredUDIDState`;
- `ZONDeleteKMAndUDID`;
- `ZONInstallAuthorizationResetExtension`;
- `ZONShowCustomerStatus`;
- `ZONContinueCustomerAuthorization`;
- `ZONStartCustomerAuthorization`.

`ZONAuthorizationCoordinator.h` exposes only the two entry points needed by `main.m`, with hidden visibility. `main.m` remains the `+load` startup host and calls those entry points at the original locations/order.

### Protected behavior preserved by contract
- `main.m +load` timing and `ZONBootstrapStart` position.
- authorization-reset hook installed before Bootstrap.
- original `deletekm` IMP call-through before UDID state clearing.
- exact `DZUDID` key and four Zonoe bridge-default keys.
- AppLovinSDK/UnityFramework preflight order.
- A_customer/B_debug branch behavior.
- cached `DZUDID` fast path and `ZonoeCurrentUDID()` bridge-cache path.
- first request order: status → callback registration → `ZonoeRequestUDIDIfNeeded`.
- callback validation, keychain write/read verification and `[auth loada]` continuation.
- existing queues, status strings/durations and persistence semantics.
- `WX_NongShiFu123.mm`, `ZonoeUDIDAPI.m`, `ZONUDIDBridge.m`, Bootstrap, ModuleLoader, menu and Hook implementations remain protected.

### Verification evidence
- `Tests/p44_authorization_coordinator_contract.py`: PASS.
- New coordinator translation unit independently compiles against iPhoneOS SDK with `-Wall -Wextra -Werror`; only the pre-existing third-party JDStatusBarNotification unguarded-availability warning is suppressed for this isolated compile check.
- A_customer and B_debug full iPhoneOS builds: PASS.
- `arm64 + arm64e`: PASS.
- Exported-symbol equality vs P42: PASS.
- Linked-library equality vs P42: PASS.

### Device promotion gate
P44 must still pass real-device checks for:
1. Existing valid `DZUDID` startup → authorization continues normally.
2. Cleared auth/UDID → Zonoe request/callback → `DZUDID` writeback → authorization continuation.
3. `deletekm` reset still clears legacy `DZUDID` plus Zonoe bridge state.
4. Legacy fallback/foreground-return path does not loop, duplicate requests or crash.
5. Floating entry/menu basic smoke remains normal.

### Rollback
`v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3` remains the rollback baseline until P44 device PASS.

---

## P45 — Legacy UDID Web/Profile Fallback Adapter Boundary
**Status:** `planned / blocked on P44 device pass`

### Goal
Hide the legacy `WX_NongShiFu123 getUDID:` fallback behind a narrow adapter so `ZonoeUDIDAPI` no longer directly owns legacy class details.

### Scope
- Wrap existing fallback entry/callback only.
- Preserve `DZUDID` lookup, `ZONUDIDBridgeStoreUDID`, one-in-flight guard and main-queue continuation exactly.

### Forbidden
- No rewrite of legacy web/profile acquisition.
- No change to fallback trigger conditions, callback semantics, keychain keys or validation rules.

### Verification gate
- Exact fallback call/continuation contract.
- A/B arm64+arm64e builds and ABI/load-library comparison.
- Real-device normal Zonoe path plus forced/unavailable fallback path.

---

## P46 — Startup Side-Effect Instrumentation & Launch Contract
**Status:** `planned`
- Measure and lock ordering around `+load`, auth-reset hook, framework preflight, Bootstrap ready, authorization, module loading and floating entry.
- No queue/order/timeout optimization in this phase.

## P47 — Repository Hygiene / Generated Artifact Cleanup
**Status:** `planned`
- Remove only files proven not to be PBX/script/release/runtime inputs.
- Keep cleanup isolated from runtime refactors.

## P48 — Legacy God-Object Split #1
**Status:** `planned / target chosen from audit evidence`
- Split exactly one responsibility from one audited legacy unit; mechanical move first, cleanup later.

## P49 — Active Target / Dead Code / Dependency Audit
**Status:** `planned`
- Recompute active runtime/dependency surface and remove only proven-unused code/dependencies.

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `planned`
- Consolidate verified boundaries/inventories/contracts and stop structural churn without a concrete need.
- Full CI + full real-device regression required before final promotion.

# Protected behavior across all later stages
Unless a stage explicitly authorizes and independently proves a change, preserve:
- `main.m +load` timing and Bootstrap/authorization sequencing;
- authorization-reset compatibility behavior;
- Zonoe callback scheme/host/nonce/parser/storage semantics;
- localhost bridge port/timeouts/retries/delays/throttles;
- `zonoe://udid` preferred path and legacy fallback;
- `DZUDID` keychain semantics;
- floating/menu behavior and active features;
- cloud save/local files/backup/restore/clear-data/clear-auth paths;
- module discovery, containment, ABI and `dlopen` behavior;
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind behavior.

# Universal promotion checklist
1. Product diff limited to declared phase scope.
2. Contract/static tests pass.
3. New translation units independently compile where applicable.
4. A_customer + B_debug build for `arm64 + arm64e`.
5. Export surface and load libraries compared against promoted baseline.
6. A_customer artifact/digest/dylib SHA256 recorded.
7. Required real-device checklist passes.
8. Only then update `last_device_verified_*` and promote.

# Next Task
**Real-device validate P44 A_customer.** Do not begin P45 product work until P44 receives explicit device PASS. If P44 fails, diagnose against P42 and keep P42 as the promoted rollback baseline.
