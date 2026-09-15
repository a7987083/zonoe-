# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task. Do not rely on chat history for sequencing decisions.

## Current promoted baseline
- Device-verified version: `v1_p42`.
- Runtime/source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Baseline work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Baseline test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- CI Run `34995566144`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **77**.
- Architectures: `arm64 + arm64e`.
- P42/P41 exported symbol sets and linked load-library sets are identical.
- P42 remains the mandatory rollback/device baseline until a later runtime candidate explicitly passes its real-device gate.

## Current development phase
- Phase: **P43 — Architecture State Refresh & Remaining Ownership Audit**.
- Work branch: `work/zonoemenu-v1-p43-architecture-audit`.
- Test branch: `test/zonoemenu-v1-p43-architecture-audit`.
- Audit head: `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`.
- CI Run `35001000784`: **success**.
- Product runtime/PBX versus P42: **identical**.
- Active Sources: **77**.
- Device test: **not required**, because P43 changes only audit/tests/docs and the canonical runtime tree is unchanged.
- Detailed evidence: `P43_ARCHITECTURE_AUDIT.md`.

## Refactor operating rules
1. One architectural concern per version. Never combine ownership cleanup with behavior, timing, threading, protocol, persistence, UI, or feature changes.
2. Every source-moving phase needs a mechanical/equivalence contract where practical.
3. Every phase must define protected files/symbols/state machines before source changes begin.
4. CI success is not device promotion. A runtime-affecting version becomes the new baseline only after explicit real-device PASS.
5. A failed candidate does not modify the promoted fallback baseline.
6. Preserve `testmod/` + `testmod.xcodeproj` as the canonical runtime/product surface. PBX membership decides whether code is active.
7. Do not delete legacy code until active-target reachability and runtime consumers are proven absent.
8. Do not change `+load`, main-queue sequencing, callback timing, socket retry timing, URL schemes, persistence keys, or authorization continuation as part of structural cleanup.
9. Every completed runtime development version must record branch, product commit, CI run/status, A_customer artifact, architectures, SHA256, device status, and rollback baseline. Audit-only phases must record branch, audit head, CI run and runtime-equivalence proof.
10. `CHANGELOG_DEV.md` records what actually changed; `HANDOFF.md` records context/risks; `PROJECT_STATE.json` is machine-readable state; `KNOWN_ISSUES.md` tracks open risks.

## Completed foundation
### P41 — UDID Bridge Compilation Boundary — COMPLETED / DEVICE PASSED
- Source: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI: `34959813770` / success.
- `ZONUDIDBridge.h` became declaration-only; implementation moved to `ZONUDIDBridge.m`.
- Active Sources: 75 → 76.
- Device validation: passed; superseded by P42.

### P42 — ZonoeUDIDAPI Service Boundary — COMPLETED / CURRENT DEVICE BASELINE
- Source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI: `34995566144` / success.
- Existing `ZonoeUDIDAPI` implementation moved mechanically from `testmod/视图菜单/NSObject+UI.m` to `testmod/ZONServices/ZonoeUDIDAPI.m`.
- Active Sources: 76 → 77; sole source addition `ZonoeUDIDAPI.m`.
- A_customer artifact: `10407391591`, digest `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- B_debug artifact: `10406554164`, digest `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.
- A_customer dylib SHA256: `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- Device validation: passed.

### P43 — Architecture State Refresh & Remaining Ownership Audit — COMPLETED / RUNTIME UNCHANGED
- Work branch: `work/zonoemenu-v1-p43-architecture-audit`.
- Test branch: `test/zonoemenu-v1-p43-architecture-audit`.
- Audit head: `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`.
- CI Run `35001000784`: **success**.
- Added `P43_ARCHITECTURE_AUDIT.md` and `Tests/p43_architecture_audit.py`.
- Contract proves `testmod/` + `testmod.xcodeproj` are unchanged from P42 product commit.
- Contract proves active Sources remain exactly **77** and the audited legacy units remain active.
- `WX_NongShiFu123.mm` remains a high-risk legacy implementation and is explicitly excluded from direct P44 rewriting.
- P44 target selected: authorization orchestration/reset glue currently implemented as static helpers in `testmod/Bsphp/main.m`.
- Planned P44 boundary: `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m`.
- P42 remains the rollback/device baseline.

# Planned refactor stages

## P44 — Authorization Orchestration Boundary
**Status:** `NEXT / planned from P43 evidence`

### Goal
Separate customer authorization orchestration/reset glue from startup-host ownership without changing the existing authorization sequence.

### Exact selected scope
Mechanically extract the current `main.m` helper block that owns:
- original `deletekm` IMP storage;
- `ZONClearStoredUDIDState`;
- `ZONDeleteKMAndUDID`;
- `ZONInstallAuthorizationResetExtension`;
- `ZONShowCustomerStatus`;
- `ZONContinueCustomerAuthorization`;
- `ZONStartCustomerAuthorization`.

Preferred new boundary:
- `testmod/ZONServices/ZONAuthorizationCoordinator.h`
- `testmod/ZONServices/ZONAuthorizationCoordinator.m`

`main.m` remains the `+load` startup host and calls the new boundary at the same positions/order.

### Protected behavior
- `main.m +load` execution timing.
- authorization-reset compatibility hook installation before `ZONBootstrapStart`.
- original `deletekm` IMP call-through before UDID-state clearing.
- removal of `DZUDID` and the exact four Zonoe bridge-default keys.
- AppLovinSDK/UnityFramework preflight order.
- A_customer vs B_debug compile-time branch behavior.
- cached `DZUDID` fast path.
- `ZonoeCurrentUDID()` bridge-cache path.
- first request order: status -> callback registration -> `ZonoeRequestUDIDIfNeeded`.
- callback validation/write-back verification and `[auth loada]` continuation.
- all current queues, delays, status text/durations, persistence keys and network semantics.
- `WX_NongShiFu123.mm` implementation remains unchanged.

### Forbidden
- No async/sync changes.
- No queue changes.
- No retry/timeout changes.
- No API endpoint/payload changes.
- No UI redesign.
- No rewrite/split of `WX_NongShiFu123.mm`.
- No startup/preflight reordering.

### Verification gate
- Exact/mechanical extraction contract from the P42/P43 `main.m` helper block.
- Protected-source identity for `WX_NongShiFu123.mm`, Zonoe UDID bridge/API implementation and unrelated runtime surfaces.
- New translation unit independently compiles with warnings-as-errors where feasible.
- PBX active Sources expected **77 → 78**, with the sole new active source `ZONAuthorizationCoordinator.m`.
- Full A_customer + B_debug iPhoneOS builds for `arm64 + arm64e`.
- Exported-symbol and linked-library comparison against P42.
- A_customer artifact/digest/dylib SHA256 recorded.
- Real-device promotion gate: startup, cached UDID, fresh Zonoe callback, fallback path, authorization continuation and menu smoke.

### Rollback
`v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3` remains the rollback baseline until P44 explicitly passes device validation.

---

## P45 — Legacy UDID Web/Profile Fallback Adapter Boundary
**Status:** `planned / conditional on P44 device pass`

### Goal
Isolate the legacy `WX_NongShiFu123 getUDID:` fallback behind a narrow adapter so modern `ZonoeUDIDAPI` no longer directly owns legacy class details.

### Scope
- Wrap the existing fallback entry/callback only.
- Preserve `DZUDID` keychain lookup and `ZONUDIDBridgeStoreUDID` continuation exactly.
- Preserve one-in-flight guard and main-queue behavior.

### Forbidden
- No rewrite of the legacy profile/web acquisition implementation.
- No change to fallback trigger conditions.
- No change to callback semantics, keychain key, validation rules or logging-dependent behavior.

### Verification gate
- Exact fallback call/continuation contract.
- Full builds and ABI/load-library check.
- Real-device test with normal Zonoe path plus forced/unavailable fallback path.

---

## P46 — Startup Side-Effect Instrumentation & Launch Contract
**Status:** `planned`

### Goal
Measure and lock startup ordering before any later attempt to simplify global startup side effects.

### Scope
- Add non-functional timing/signpost/log instrumentation around `+load`, authorization-reset hook install, framework preflight, Bootstrap ready callback, authorization start/ready, module scan/load and first floating entry/menu presentation.
- Produce a startup-order contract/document from device/CI evidence.

### Forbidden
- Do not move work off-main/on-main.
- Do not remove `+load`.
- Do not reorder preflight/bootstrap/auth/module loading.
- Do not optimize timeouts or delays in this phase.

### Verification gate
- A/B builds.
- No semantic product-path diff beyond instrumentation.
- Real-device startup sequence captured at least once on A_customer.

---

## P47 — Repository Hygiene / Generated Artifact Cleanup
**Status:** `planned`

### Goal
Reduce repository noise without changing runtime or build outputs.

### Scope
- Audit generated/package binaries, user-specific Xcode state, reproducible artifacts and stale non-runtime material.
- Extend `.gitignore` where safe.
- Remove only files proven not to be build/release/runtime inputs.

### Verification gate
- Before/after active PBX source set identical.
- Build scripts and dependency bootstrap succeed.
- Binaries byte-identical where deterministic; otherwise exports/load libraries/source inputs match.
- Device test required only if runtime binary equivalence cannot be proved.

---

## P48 — Legacy God-Object Split #1
**Status:** `planned / target chosen from audit evidence`

### Goal
Split exactly one large legacy unit with the best risk/reward ratio. Candidate list includes `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m`; target must be selected from live call/state evidence.

### Verification gate
- One responsibility only.
- Mechanical move before cleanup/renaming.
- Target-specific invariant contract.
- Full A/B builds and relevant real-device path.

---

## P49 — Active Target / Dead Code / Dependency Audit
**Status:** `planned`

### Goal
Recompute the active runtime surface after boundary work and remove only proven-unused code/dependencies.

### Verification gate
- Explicit removal proof per file/dependency.
- Full A/B build.
- Export/load-library comparison.
- Real-device smoke for any runtime-linked removal.

---

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `planned`

### Goal
Consolidate the proven architecture after P43–P49, update documentation/contracts, and stop structural churn unless a concrete maintenance or feature need justifies more change.

### Verification gate
- Full architecture audit and source/dependency inventory.
- Full CI, A/B arm64+arm64e artifacts, ABI/load-library review.
- Full real-device regression.
- Promote only after explicit user PASS.

# Protected behavior across all planned stages
Until a stage explicitly says otherwise and proves the change independently, keep unchanged:
- `main.m +load` timing and Bootstrap/authorization sequencing.
- authorization-reset compatibility behavior.
- Zonoe callback scheme/host, nonce generation/validation, callback parsing and storage keys.
- localhost bridge port, socket timeout, retry count/delay, pending-request age and request throttle.
- `zonoe://udid` preferred path and legacy web/profile fallback.
- `DZUDID` keychain semantics.
- floating entry/menu stack and active features.
- cloud save, local files, backup/restore, clear-data and clear-auth paths.
- module discovery directories, containment checks, ABI checks and `dlopen` behavior.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime behavior.

# Universal promotion checklist
For each runtime-affecting candidate:
1. Product diff is limited to the phase-declared scope.
2. Contract/static tests pass.
3. New translation units independently compile where applicable.
4. A_customer and B_debug build successfully for `arm64 + arm64e`.
5. Export surface and linked libraries are compared against the promoted baseline.
6. A_customer artifact ID/digest and dylib SHA256 are recorded.
7. Required real-device checklist passes.
8. Only then update `last_device_verified_*` and promote the version.

# Next Task
Start **P44 — Authorization Orchestration Boundary** from the P42 device baseline and the P43 audit decision. Create `ZONAuthorizationCoordinator.h/.m`, mechanically extract only the selected authorization/reset helper block from `testmod/Bsphp/main.m`, keep `main.m +load` and `WX_NongShiFu123.mm` behavior unchanged, add equivalence/protected-source contracts, then run full A_customer/B_debug arm64+arm64e CI before requesting device validation.
