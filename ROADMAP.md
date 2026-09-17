# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p49`.
- Runtime/source commit: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- CI Run `35195152912`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10485344383`.
- A_customer dylib SHA256: `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- P49 remains the rollback/device runtime baseline because P50 intentionally has zero runtime drift.

## P49 — Active Target / Dead Code / Dependency Audit — COMPLETED / DEVICE PASSED
- Recomputed active target/dependency surface.
- Removed proven-unused `Network.framework` from PBX only.
- Active Sources remained 78.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Exported symbols versus P48.1: identical.
- Load libraries versus P48.1: identical except deliberate removal of `Network.framework`.
- CI Run `35195152912`: PASS.
- Real-device validation: PASS.

## P50 — Refactor Stabilization / Architecture Freeze — COMPLETED
### Goal achieved
- Consolidated the verified architecture ownership boundaries.
- Added a zero-runtime-drift gate against promoted P49.
- Added a frozen architecture contract and final status matrix.
- Defined which future changes may proceed within existing boundaries and which require a new explicitly scoped stage.

### Canonical P50 documents
- `P50_ARCHITECTURE_FREEZE.md`
- `P50_FINAL_STATUS_MATRIX.md`
- `Tests/p50_architecture_freeze_contract.py`
- `.github/workflows/p50-architecture-freeze.yml`

### Runtime result
- No changes to `testmod/` or `testmod.xcodeproj` versus P49.
- Active Sources: 78.
- `Network.framework`: absent.
- `StoreKit.framework`: absent.
- Runtime/device baseline remains P49.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface.
2. UI changes must consume `ZONFeatureRegistry` / `ZONFeatureDispatcher` rather than directly recoupling to legacy feature implementations.
3. Startup, authorization, UDID, module-loading order, persistence semantics and destructive-data behavior require dedicated stages if changed.
4. Active source/framework additions or deletions require explicit dependency/reachability evidence and normal promotion gates.
5. Structural merge/split/move of frozen core classes is not justified by style alone.
6. Every future runtime candidate must build A_customer + B_debug for arm64 + arm64e and pass its scoped real-device gate before promotion.

## Completed foundation
- P41 — UDID Bridge Compilation Boundary: completed/device passed, superseded.
- P42 — ZonoeUDIDAPI Service Boundary: completed/device passed, superseded.
- P43 — Architecture State Refresh & Ownership Audit: completed/runtime unchanged.
- P44 — Authorization Orchestration Boundary: completed/device passed, superseded.
- P45 — Legacy UDID Web/Profile Fallback Adapter Boundary: CI verified; covered by later promoted baselines.
- P46 — Startup Side-Effect Instrumentation & Launch Contract: CI verified; covered by later promoted baselines.
- P47 — Repository Hygiene: completed/runtime unchanged.
- P48 — Legacy App Store checker removal: completed/device passed.
- P48.1 — StoreKit residual cleanup: completed/device passed, superseded by P49.
- P49 — Active target/dependency audit: completed/device passed/current runtime baseline.
- P50 — Refactor stabilization/architecture freeze: completed/runtime unchanged from P49.

# Future work policy
The architecture-refactor program is closed after P50. Future work should start from P49/P50 and be named by product concern, for example a UI-only stage, cloud-save stage, storage stage, authorization stage, or targeted bug-fix stage. Do not continue structural churn without a measured defect or concrete requirement.

# Next Task
No automatic P51 refactor stage is planned. Open the next stage only for a concrete product requirement. A menu redesign should be created as a **UI-only stage** that keeps Registry/Dispatcher and all frozen runtime boundaries intact.
