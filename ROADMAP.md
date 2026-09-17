# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted baseline
- Device-verified version: `v1_p49`.
- Runtime/source commit: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- CI Run `35195152912`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10485344383`.
- A_customer dylib SHA256: `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- P49 is the mandatory rollback/device baseline until a later runtime candidate explicitly passes its device gate.

## P49 — Active Target / Dead Code / Dependency Audit — COMPLETED / DEVICE PASSED
### Scope
- Recomputed active PBX/source/framework/dependency surface from P48.1.
- Proved `Network.framework` had zero source consumers.
- Removed `Network.framework` from PBX only.
- No business source changes.

### Verification
- Active PBX Sources: **78**.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Exported symbols versus P48.1: identical.
- Load libraries versus P48.1: identical except deliberate removal of `Network.framework`.
- CI Run `35195152912`: PASS.
- Real-device validation: PASS, explicitly reported by user.

## Refactor operating rules
1. One architectural concern per version.
2. CI success is not device promotion.
3. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface; PBX membership defines active product code.
4. Do not delete legacy code without PBX/caller/runtime reachability proof.
5. Do not change `+load`, queues, callback ordering, retry/timeout behavior, URL schemes, persistence keys, authorization continuation or module loading timing during structural cleanup.
6. Every runtime candidate records branch, product commit, CI run/status, artifact IDs/digests, architectures, dylib SHA256, device status and rollback baseline.
7. `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json`, `KNOWN_ISSUES.md`, and `DEVICE_TEST_MATRIX.md` must remain synchronized with this file.

## Completed foundation
- P41 — UDID Bridge Compilation Boundary: completed/device passed, superseded.
- P42 — ZonoeUDIDAPI Service Boundary: completed/device passed, superseded.
- P43 — Architecture State Refresh & Ownership Audit: completed/runtime unchanged.
- P44 — Authorization Orchestration Boundary: completed/device passed, superseded.
- P45 — Legacy UDID Web/Profile Fallback Adapter Boundary: CI verified; behavior covered by later promoted baselines.
- P46 — Startup Side-Effect Instrumentation & Launch Contract: CI verified; behavior covered by later promoted baselines.
- P47 — Repository Hygiene / Generated Artifact Cleanup: completed; runtime unchanged.
- P48 — Legacy App Store checker removal: completed/device passed.
- P48.1 — StoreKit residual cleanup: completed/device passed, superseded by P49.
- P49 — Active target/dependency audit and unused `Network.framework` removal: completed/device passed/current promoted baseline.

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `in progress`

### Goal
Consolidate verified boundaries, contracts, inventories and promotion evidence, then stop structural churn without a concrete product need.

### Runtime policy
- P50 is **not** a behavior stage.
- Product/runtime surface must remain identical to promoted P49.
- `P50_ARCHITECTURE_FREEZE.md` defines the frozen ownership boundaries and change policy.
- CI must fail if `testmod/` or `testmod.xcodeproj` drifts from P49 during this stage.

### Allowed scope
- Documentation synchronization.
- Contract/static tests.
- CI freeze gates.
- Inventory/ownership documentation.
- Non-runtime diagnostics/observability that do not alter ordering or semantics.

### Forbidden scope
- No startup/auth/UDID/save/menu/hook behavior changes.
- No source/framework deletion.
- No class splitting/merging solely for style.
- No persistence key, URL, timeout, retry, callback-order or module-load-order changes.

# Universal promotion checklist
1. Product diff is limited to the declared scope.
2. Contract/static tests pass.
3. A_customer + B_debug build where runtime changed.
4. Export surface and load libraries are compared against the immediate promoted runtime predecessor where runtime changed.
5. Required real-device checklist passes for runtime candidates.
6. Only then update `last_device_verified_*` and promote.

# Next Task
Complete **P50 — Refactor Stabilization / Architecture Freeze** by enforcing zero runtime drift from P49, synchronizing canonical docs, and recording the final frozen architecture contract.
