# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p62`.
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Runtime/source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Architectures: `arm64 + arm64e`.
- P62 remains the rollback/device baseline until P63A receives explicit device PASS.

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

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface.
2. UI changes must consume `ZONFeatureRegistry` / `ZONFeatureDispatcher` rather than directly recoupling to legacy feature implementations.
3. Startup, authorization, UDID, module-loading order, persistence semantics and destructive-data behavior require dedicated stages if changed.
4. Active source/framework additions or deletions require explicit dependency/reachability evidence and normal promotion gates.
5. Preserve commit history; do not rewrite published stage history.
6. Every runtime candidate must build A_customer + B_debug for `arm64 + arm64e` and pass its scoped real-device gate before promotion.
7. CI success does not equal device promotion.
8. Existing CI/release semantics must not be changed unless the stage explicitly requires it.
9. Every stage transition must keep the five long-project state files synchronized.

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
- P62 — ZONKeychain + authorization reset service: completed/device passed/current promoted runtime baseline.

# Six Button Service Refactor
Scope is limited to the six existing button actions:
1. Remote download (`base.remote-download`).
2. VIP cloud save (`base.cloud-save`).
3. Backup save (`data.backup-save`).
4. Restore save (`data.restore-save`).
5. Clear game data (`data.clear-game-data`).
6. Clear authorization records (`auth.clear-records`).

## P63A — Six Button Service Boundary — CI PASSED / DEVICE PENDING
### Candidate
- Version: `v1_p63a`.
- Candidate source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: **success**.
- A_customer artifact: `10596866163`, digest `sha256:4770559f4d15706349e558e6b36c709e4242e0de8ae505ec9934b913d96822ae`.
- A_customer dylib SHA256: `2c90fed5247de6af6fe91bb6d1c57562621ff10542ae36b355924f5b78d7583b`.
- B_debug artifact: `10596501583`, digest `sha256:c5cfe082bb2294a5eee0fc871226ee3ad9744ca3558d1d5ae5581c77ec631099`.
- B_debug dylib SHA256: `3063dbd4060767948686990772333f4fa2ecaa8c648252fc6d02641149e8ee6b`.
- Real-device status: **pending**.

### Delivered
- Added `ZONSixButtonActionService` as the explicit service/adapter boundary for all six scoped actions.
- `ZONFeatureDispatcher` now routes the six actions through the service boundary instead of directly importing/calling `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for those actions.
- Historical C helper functions in `ZONFeatureDispatcher` remain as compatibility forwarding symbols.
- Remote download, cloud save, backup and restore retain their current legacy engines internally.
- Clear-game-data implementation moved behind the service boundary without intentional semantic cleanup; its existing timing/deletion behavior is preserved for P63A.
- Clear-authorization button now calls the already device-verified `ZONAuthorizationResetService` through the P63A boundary rather than crossing the legacy `deletekm` entry.
- Added deterministic PBX migration and P63A behavior/service-boundary contract tests.

### Verification completed
- Registry identifiers/tags unchanged: PASS.
- Service route contract: PASS.
- Legacy direct six-button dependencies removed from Dispatcher: PASS.
- P62 reset clear-set contract preserved: PASS.
- PBX source membership: PASS.
- Exact build revision pinning: PASS.
- A_customer xcodebuild: PASS.
- B_debug xcodebuild: PASS.
- `arm64 + arm64e` dylib output verification: PASS.

### Promotion gate remaining
Real-device smoke/regression of all six buttons. Any visible behavior difference from P62 is a regression for P63A.

## Planned follow-on stages after P63A device promotion
- P63B — Clear Game Data dedicated-service cleanup/hardening and error-model work; current P63A behavior remains the comparison baseline.
- P63C — Backup engine extraction from `daochucd`.
- P63D — Restore engine extraction from `YYYPicker`.
- P63E — Remote Download engine extraction from `PubgLoad`.
- P63F — Cloud Save engine extraction from `PubgLoad`.

# Next Task
Real-device validate **v1_p63a** using all six scoped buttons. Do not promote P63A or start P63B until the user explicitly reports the six-button regression test passed.
