# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p62`.
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Runtime/source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: **success**.
- A_customer: build/link/output verification **PASS**.
- B_debug: build/link/output verification **PASS**.
- Real-device regression: **passed and explicitly reported by user**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10595647289`.
- A_customer dylib SHA256: `71f14901e140fd19cf175c0092e1cfdf46c7aefc04d2ba73b03baf83359f6962`.
- B_debug artifact: `10595652401`.
- B_debug dylib SHA256: `34cbcd9695c7eaad9096c606341fed008dce4e78094df1433243dd5cb9391c59`.

## P62 — ZONKeychain + Authorization Reset Service — COMPLETED / DEVICE PASSED
### Delivered
- Replaced the active `SFHFKeychainUtils` UDID path with `ZONKeychain`.
- Removed `SFHFKeychainUtils.h/.m` from the active project surface.
- Extracted authorization reset behavior into `ZONAuthorizationResetService`.
- Preserved the effective P62 clear set for NSUserDefaults, legacy `getKeychain`, UDID bridge cache and `ZONKeychain`.
- Removed coordinator runtime reset ownership while keeping compatibility startup behavior.
- Fixed deterministic PBX migration for `ZONAuthorizationResetService.m`.
- Fixed CI revision pinning so A_customer/B_debug build the exact migrated revision.

### Verification
- CI Run `35480732207`: PASS.
- A_customer: PASS.
- B_debug: PASS.
- Real-device behavior: user reported all required tests normal.
- Authorization reset behavior is promoted and can be used as rollback evidence for the next stage.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface.
2. UI changes must consume `ZONFeatureRegistry` / `ZONFeatureDispatcher` rather than directly recoupling to legacy feature implementations.
3. Startup, authorization, UDID, module-loading order, persistence semantics and destructive-data behavior require dedicated stages if changed.
4. Active source/framework additions or deletions require explicit dependency/reachability evidence and normal promotion gates.
5. Preserve commit history; do not rewrite published stage history.
6. Every runtime candidate must build A_customer + B_debug for `arm64 + arm64e` and pass its scoped real-device gate before promotion.
7. CI success does not equal device promotion.
8. Existing CI/release semantics must not be changed unless the stage explicitly requires it.

## Completed foundation
- P41 — UDID Bridge Compilation Boundary: completed/device passed, superseded.
- P42 — ZonoeUDIDAPI Service Boundary: completed/device passed, superseded.
- P43 — Architecture State Refresh & Ownership Audit: completed/runtime unchanged.
- P44 — Authorization Orchestration Boundary: completed/device passed, superseded.
- P45 — Legacy UDID Web/Profile Fallback Adapter Boundary: CI verified; covered by later promoted baselines.
- P46 — Startup Side-Effect Instrumentation & Launch Contract: CI verified; covered by later promoted baselines.
- P47 — Repository Hygiene: completed/runtime unchanged.
- P48 — Legacy App Store checker removal: completed/device passed.
- P48.1 — StoreKit residual cleanup: completed/device passed.
- P49 — Active target/dependency audit: completed/device passed.
- P50 — Refactor stabilization/architecture freeze: completed/runtime unchanged.
- P51/P51-B — Feature routing and backup refactor: completed/device passed.
- P56 — PubgLoad temp-boundary cleanup: completed/device passed.
- P58 — Download lifecycle hardening: completed/device passed.
- P60 — UDID acquisition progress/retry UX: completed/device passed.
- P61 — Offline authorization retry behavior: CI verified; superseded by the P62 working line.
- P62 — ZONKeychain + authorization reset service: completed/device passed/current runtime baseline.

# Next Program — Six Button Service Refactor
Scope is limited to the six existing button actions:
1. Remote download (`base.remote-download`).
2. VIP cloud save (`base.cloud-save`).
3. Backup save (`data.backup-save`).
4. Restore save (`data.restore-save`).
5. Clear game data (`data.clear-game-data`).
6. Clear authorization records (`auth.clear-records`).

## P63A — Six Button Service Boundary
### Goal
Introduce an explicit service boundary between `ZONFeatureDispatcher` and the six existing legacy implementations without changing user-visible behavior.

### Allowed scope
- Add service/adapter entry points for the six actions.
- Route `ZONFeatureDispatcher` through those services.
- Keep legacy engines internally intact for this stage.
- Reuse `ZONAuthorizationResetService`; do not reimplement authorization deletion.
- Add behavior-contract tests that verify identifiers/tags and service routing rather than hard-coding legacy class names into Dispatcher.

### Forbidden scope
- No deep rewrite of `PubgLoad`, `daochucd`, `YYYPicker` or `WX_NongShiFu123.mm` in P63A.
- No change to download URL semantics, ZIP format, backup layout, restore overwrite rules, authorization clear set, delay/exit behavior, or menu labels/tags.
- No unrelated cleanup.

### Verification gates
- Static route/contract checks.
- PBX membership checks for any new source files.
- A_customer build: PASS.
- B_debug build: PASS.
- `arm64 + arm64e` dylib output verification.
- Real-device smoke test for all six buttons before promotion.

## Planned follow-on stages
- P63B — Clear Game Data service implementation extraction.
- P63C — Backup engine extraction from `daochucd`.
- P63D — Restore engine extraction from `YYYPicker`.
- P63E — Remote Download engine extraction from `PubgLoad`.
- P63F — Cloud Save engine extraction from `PubgLoad`.

# Next Task
Implement **P63A Six Button Service Boundary** from the promoted P62 baseline. Update all five long-project state files with each stage transition and do not mark the stage promoted until CI and explicit device validation both pass.
