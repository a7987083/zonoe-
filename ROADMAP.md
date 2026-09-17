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
### P45 — Legacy UDID Web/Profile Fallback Adapter Boundary — CI VERIFIED / DEVICE PENDING
- Product source: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`.
- CI head: `ae57fdd5f61a0901f559083a95d0f984a6f2da84`.
- CI Run `35036655523`: **success**.
- Active Sources: **79**.
- P45/P44 exports and load libraries: **identical**.
- Device status: **pending**. P45 has not been promoted separately.

### P46 — Startup Side-Effect Instrumentation & Launch Contract — CI VERIFIED / DEVICE PENDING
- Work branch: `work/zonoemenu-v1-p46-launch-contract`.
- Test branch: `test/zonoemenu-v1-p46-launch-contract-build`.
- Product source commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- Successful CI head: `4cb21f21c76b359fbf7ad13e7d514df39ce83645`.
- CI Run `35167182449`: **success**.
- Active PBX Sources: **79**, unchanged from P45.
- Instrumentation implementation: header-only `testmod/ZONServices/ZONLaunchTrace.h`; not registered in PBX.
- A_customer artifact: `10475352058`, digest `sha256:79c34fd78c0071ed2a865ee24082806f6289e5a6615a0d022446dc6aa84ad0e1`.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- B_debug artifact: `10475337852`, digest `sha256:7cf081e2956a0a293f6deafbea20c680350dbf5356f87edfdc4affba915fb6dd`.
- Both artifacts contain `arm64 + arm64e`.
- P46/P45 exported symbols and load libraries: **identical**.
- P46-specific contract proves that removing trace imports/calls restores each touched runtime file exactly to P45 content and that PBX remains byte-identical to P45.
- Device status: **pending**. Because P46 contains the still-unpromoted P45 runtime, P46 device validation must cover both P45 fallback behavior and P46 launch instrumentation before promotion.

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
CI passed; separate device promotion is still pending. Its runtime behavior is inherited by P46 and therefore must be covered by the P46 device gate if P46 is promoted directly.

---

## P46 — Startup Side-Effect Instrumentation & Launch Contract
### Goal
Measure and lock the existing startup order before any later startup optimization or simplification is considered.

### Implemented scope
Header-only `ZONLaunchTrace.h` records monotonic uptime, main-thread flag and legacy `os_signpost` events for:
- `main.m +load` entry and auth-reset installation;
- Bootstrap entry/preflight/ready scheduling;
- AppLovinSDK and UnityFramework preflight completion;
- A_customer authorization entry, cached/bridge/fresh UDID paths and authorization continuation;
- legacy fallback begin/invalid/store;
- module scan/load begin/end;
- floating-entry request/attach;
- menu presentation request/dispatched.

### Protected behavior
- No new dispatch, delay, timer, retry or timeout logic in the trace layer.
- No PBX source membership changes.
- No changes to endpoints, storage keys, auth/UDID semantics, fallback conditions, module discovery, menu behavior or hooks.
- Removing trace imports/calls from the six touched runtime files must reproduce P45 byte-for-byte.

### Verification gate
- P46 observational contract: PASS.
- iPhoneOS trace probe compile with `-Wall -Wextra -Werror`: PASS.
- A_customer + B_debug arm64/arm64e builds: PASS.
- P46/P45 exported symbols: identical.
- P46/P45 load libraries: identical.
- Real-device launch trace + fallback/auth/menu smoke: **pending**.

### Rollback
`v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561` remains the rollback baseline until P46 passes the combined device gate.

---

## P47 — Repository Hygiene / Generated Artifact Cleanup
**Status:** `planned / blocked on P46 device promotion`
- Audit generated/package binaries, user-specific Xcode state and stale reproducible material.
- Remove only files proven not to be PBX/script/release/runtime inputs.
- No runtime feature/refactor work in this phase.

## P48 — Legacy God-Object Split #1
**Status:** `planned`
- Split exactly one responsibility from one audited active legacy unit; mechanical move first.

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
**Real-device validate P46 A_customer.** Because P45 never received a separate device PASS, the P46 device gate must also cover the inherited P45 legacy fallback path: normal Zonoe path, fallback only when unavailable, no duplicate fallback, valid `DZUDID` continuation, authorization continuation, foreground return, launch-trace ordering, floating entry and menu smoke. Keep P44 promoted until explicit PASS. After P46 promotion, begin P47 repository hygiene only.