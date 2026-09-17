# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task. Do not rely on chat history for sequencing decisions.

## Current promoted baseline
- Device-verified version: `v1_p48_1`.
- Runtime/source commit: `71eddfa0600112aa56a8bef45013d73f4673794a`.
- CI Run `35180342515`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- A_customer dylib SHA256: `36bbe4c32882d98b274fb7cfb40bf62f727502b4867765bee1f747c0e5fbe90d`.
- P48.1 is now the mandatory rollback/device baseline until a later candidate explicitly passes its device gate.

## P48.1 — StoreKit Residual Cleanup — COMPLETED / DEVICE PASSED
### Scope
- Removed the remaining StoreKit/App Store presentation surface from `YYYPicker`.
- Preserved the restore-save/import behavior.
- PBX membership did not change.

### Verification
- Contract: PASS.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Exported symbols versus P48: identical.
- Load libraries versus P48: identical except the deliberate removal of `StoreKit.framework`.
- CI Run `35180342515`: PASS.
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
- P47 — Repository Hygiene / Generated Artifact Cleanup: completed; runtime unchanged from P46.
- P48 — Legacy cleanup/refactor stage: completed/device passed before P48.1 maintenance cleanup.
- P48.1 — StoreKit Residual Cleanup: completed/device passed/current promoted baseline.

## P49 — Active Target / Dead Code / Dependency Audit
**Status:** `next planned`

### Goal
Recompute the active target, source, framework and dependency surface from the P48.1 promoted baseline, then remove only items proven unused.

### Required evidence before deletion
- PBX membership and build-phase reachability.
- Direct and transitive imports/callers.
- Runtime lookup/dlopen/NSClassFromString/selectors where relevant.
- Symbol and load-command evidence.
- Build scripts/workflows/package consumers.
- A_customer/B_debug regression against P48.1.

### Forbidden scope
- No behavioral cleanup mixed into dead-code removal.
- No changes to startup timing, authorization, UDID, save restore, menu semantics, hooks or persistence.
- Do not remove historical CI/audit material merely because it is old.

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `planned`
- Consolidate verified boundaries/contracts/inventories and stop structural churn without a concrete need.

# Universal promotion checklist
1. Product diff is limited to the declared scope.
2. Contract/static tests pass.
3. New translation units or probes compile where applicable.
4. A_customer + B_debug build for `arm64 + arm64e`.
5. Export surface and load libraries are compared against the immediate promoted runtime predecessor.
6. A_customer artifact/digest/dylib SHA256 are recorded.
7. Required real-device checklist passes.
8. Only then update `last_device_verified_*` and promote.

# Next Task
Define and execute **P49 — Active Target / Dead Code / Dependency Audit** from the P48.1 promoted baseline. Start with evidence collection; do not delete anything until reachability is proven.
