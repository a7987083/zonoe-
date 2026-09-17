# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task. Do not rely on chat history for sequencing decisions.

## Current promoted baseline
- Device-verified version: `v1_p44`.
- Runtime/source commit: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- CI Run `35020232205`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- P44 remains the mandatory rollback/device baseline until a later candidate explicitly passes its device gate.

## Current development state
### P45 — Legacy UDID Web/Profile Fallback Adapter Boundary — CI VERIFIED / NOT SEPARATELY PROMOTED
- Product source: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`.
- CI Run `35036655523`: **success**.
- Active Sources: **79**.
- Device status: not separately promoted; behavior is inherited by P46/P47 device gate.

### P46 — Startup Side-Effect Instrumentation & Launch Contract — CI VERIFIED / DEVICE PENDING
- Runtime source commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- CI Run `35167182449`: **success**.
- Active PBX Sources: **79**.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- P46/P45 exports and load libraries: identical.
- Device status: **pending**; combined gate must cover inherited P45 fallback behavior plus P46 launch instrumentation.

### P47 — Repository Hygiene / Generated Artifact Cleanup — CI VERIFIED / PROMOTION BLOCKED ON INHERITED DEVICE GATE
- Work branch: `work/zonoemenu-v1-p47-repository-hygiene`.
- Test branch: `test/zonoemenu-v1-p47-repository-hygiene-build`.
- Repository candidate commit: `64f8575966d62695123b9f8444f89dbc98e796df`.
- Runtime source remains P46: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- Successful CI head: `eed8c8aca74a8c6e6985848a11c76d5a52cc2f40`.
- CI Run `35169166129`: **success**.
- Canonical product trees `testmod/` and `testmod.xcodeproj/`: **byte-identical to P46**.
- Active PBX Sources: **79**.
- Removed tracked generated artifact: `Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip`.
- Added narrow ignore rule: `Packages/*.zip`.
- Historical phase scripts/tests/workflows retained deliberately as reproducibility evidence.
- A_customer artifact: `10476362290`, digest `sha256:f913b210dd80e2438af1bfc13b8b8b3aafe3ab3837c8d4507935abb10adfdfe5`.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- P47 A_customer dylib is **byte-identical to P46 A_customer**.
- B_debug artifact: `10476157646`, digest `sha256:d2f57b2f041b533a40dcfdec43e691c274822b97214deeeb5acaac3e115a7bcd`.
- P47/P46 exported symbols and load libraries: **identical**.
- Device status: P47 adds no runtime surface, but promotion is blocked until the inherited P46 combined device gate explicitly passes.

## Refactor operating rules
1. One architectural concern per version. Never combine ownership cleanup with behavior, timing, threading, protocol, persistence, UI, or feature changes.
2. Source-moving phases require mechanical/equivalence contracts where practical.
3. Instrumentation phases must prove that removing instrumentation restores the prior candidate exactly.
4. CI success is not device promotion.
5. A failed or untested candidate never changes the promoted rollback baseline.
6. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface; PBX membership defines active product code.
7. Do not delete legacy code without PBX/caller/runtime reachability proof.
8. Do not change `+load`, queues, callback ordering, retry/timeout behavior, URL schemes, persistence keys, authorization continuation or module loading timing during structural cleanup.
9. Every runtime candidate records branch, product commit, CI run/status, artifact IDs/digests, architectures, dylib SHA256, device status and rollback baseline.
10. `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json`, `KNOWN_ISSUES.md`, and `DEVICE_TEST_MATRIX.md` must remain synchronized with this file.

## Completed foundation
- P41 — UDID Bridge Compilation Boundary: completed/device passed, later superseded.
- P42 — ZonoeUDIDAPI Service Boundary: completed/device passed, later superseded.
- P43 — Architecture State Refresh & Ownership Audit: completed/runtime unchanged.
- P44 — Authorization Orchestration Boundary: completed/device passed/current promoted baseline.

## P45 — Legacy UDID Web/Profile Fallback Adapter Boundary
### Goal
Hide the existing `WX_NongShiFu123 getUDID:` fallback behind a narrow adapter without changing fallback trigger conditions or continuation semantics.

### Implemented scope
- Added `ZONLegacyUDIDFallbackAdapter.h/.m`.
- Mechanically moved one-in-flight state, main-queue dispatch, legacy `getUDID:` invocation, `DZUDID` read/validation and `ZONUDIDBridgeStoreUDID` continuation out of `ZonoeUDIDAPI.m`.
- `WX_NongShiFu123.mm` itself remains unchanged.

### Gate
CI passed; separate device promotion was not recorded. Its runtime behavior is inherited by P46/P47 and therefore must be covered by the combined device gate before promotion.

---

## P46 — Startup Side-Effect Instrumentation & Launch Contract
### Goal
Measure and lock the existing startup order before any later startup optimization or simplification is considered.

### Implemented scope
Header-only `ZONLaunchTrace.h` records monotonic uptime, main-thread flag and legacy `os_signpost` events for startup/auth/UDID/fallback/module/floating-entry/menu milestones.

### Protected behavior
- No new dispatch, delay, timer, retry or timeout logic in the trace layer.
- No PBX source membership changes.
- No changes to endpoints, storage keys, auth/UDID semantics, fallback conditions, module discovery, menu behavior or hooks.
- Removing trace imports/calls from the touched runtime files reproduces P45 exactly.

### Verification gate
- P46 observational contract: PASS.
- iPhoneOS trace probe compile with `-Wall -Wextra -Werror`: PASS.
- A_customer + B_debug arm64/arm64e builds: PASS.
- P46/P45 exported symbols and load libraries: identical.
- Real-device combined launch/fallback/auth/menu gate: **pending**.

---

## P47 — Repository Hygiene / Generated Artifact Cleanup
### Goal
Remove only proven generated/package debris and harden repository ignore boundaries without touching runtime/product source.

### Implemented scope
- Audited tracked generated/package binaries and user/build state.
- Proved `Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip` has no repository references and is not a PBX/script/workflow/runtime input.
- Removed that tracked ZIP.
- Added `Packages/*.zip` to `.gitignore`.
- Retained historical phase scripts/tests/workflows because they are reproducibility evidence, not generated runtime debris.
- Added `P47_REPOSITORY_HYGIENE_AUDIT.md` and a CI contract.

### Verification gate
- `testmod/` tree SHA equals P46: PASS.
- `testmod.xcodeproj/` tree SHA equals P46: PASS.
- Active PBX Sources = 79: PASS.
- P46 launch contract inherited check: PASS.
- A_customer + B_debug arm64/arm64e builds: PASS.
- P47/P46 exported symbols: identical.
- P47/P46 load libraries: identical.
- P47 A_customer dylib SHA equals P46 exactly: PASS.
- CI Run `35169166129`: PASS.
- Device gate: **inherits P46 combined gate; pending**.

### Promotion rule
P47 itself adds no new runtime behavior. One explicit real-device PASS on the P47 A_customer candidate can satisfy the inherited P46/P45 combined gate because the P47 A_customer dylib is byte-identical to P46. Until that explicit PASS, P44 remains the promoted rollback baseline.

---

## P48 — Legacy God-Object Split #1
**Status:** `blocked until P46/P47 promotion`
- Select exactly one responsibility from one audited active legacy unit based on P43/current reachability evidence.
- Mechanical ownership split first; no behavior/timing/protocol changes.

## P49 — Active Target / Dead Code / Dependency Audit
**Status:** `planned`
- Recompute active source/dependency surface and remove only proven-unused inputs.

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `planned`
- Consolidate verified boundaries/contracts/inventories and stop structural churn without a concrete need.

# Universal promotion checklist
1. Product diff is limited to the declared scope.
2. Contract/static tests pass.
3. New translation units or probes compile where applicable.
4. A_customer + B_debug build for `arm64 + arm64e`.
5. Export surface and load libraries are compared against the immediate runtime predecessor.
6. A_customer artifact/digest/dylib SHA256 are recorded.
7. Required real-device checklist passes.
8. Only then update `last_device_verified_*` and promote.

# Next Task
**Real-device validate the P47 A_customer candidate using the inherited P46 combined device gate.** Validate existing-DZUDID startup, fresh Zonoe acquisition/return, legacy fallback where practical, no duplicate fallback, authorization continuation, foreground return, launch-trace presence/order, floating entry and menu smoke. Because P47 A_customer is byte-identical to P46, this one explicit PASS covers the pending P46 runtime gate while P47 itself adds no runtime surface. Keep P44 promoted until explicit PASS. After promotion, define P48 from current P43/reachability evidence rather than guessing a god-object target.
