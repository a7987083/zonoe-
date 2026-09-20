# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p63a`.
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Runtime/source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10596866163`, digest `sha256:4770559f4d15706349e558e6b36c709e4242e0de8ae505ec9934b913d96822ae`.
- A_customer dylib SHA256: `2c90fed5247de6af6fe91bb6d1c57562621ff10542ae36b355924f5b78d7583b`.
- B_debug artifact: `10596501583`, digest `sha256:c5cfe082bb2294a5eee0fc871226ee3ad9744ca3558d1d5ae5581c77ec631099`.
- B_debug dylib SHA256: `3063dbd4060767948686990772333f4fa2ecaa8c648252fc6d02641149e8ee6b`.

## P63A — Six Button Service Boundary — COMPLETED / DEVICE PASSED
### Delivered
- Added `ZONSixButtonActionService` as the explicit service/adapter boundary for all six scoped actions.
- `ZONFeatureDispatcher` routes remote download, VIP cloud save, backup save, restore save, clear game data and clear authorization through the service boundary.
- Dispatcher no longer directly imports/calls `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for those six action paths.
- Historical C helper functions remain as compatibility forwarders.
- Remote download, cloud save, backup and restore still use the previous legacy engines internally; P63A intentionally changed ownership/routing rather than underlying behavior.
- Clear-game-data behavior moved behind the service boundary without semantic cleanup.
- Clear-authorization now reaches `ZONAuthorizationResetService` through the service boundary.
- Added deterministic PBX migration and behavior/service/PBX contract checks.

### Verification
- Registry identifiers/tags unchanged: PASS.
- Service routing contract: PASS.
- P62 authorization reset contract preserved: PASS.
- PBX source membership: PASS.
- Exact build revision pinning: PASS.
- A_customer xcodebuild: PASS.
- B_debug xcodebuild: PASS.
- `arm64 + arm64e` output verification: PASS.
- Six-button real-device smoke/regression: **PASS, explicitly reported by user**.
- P63A is promoted and becomes the comparison/rollback baseline for P63B.

## P62 — ZONKeychain + Authorization Reset Service — COMPLETED / DEVICE PASSED / SUPERSEDED
- Replaced active `SFHFKeychainUtils` UDID usage with `ZONKeychain` and removed SFHF files from the active project.
- Extracted authorization reset behavior into `ZONAuthorizationResetService`.
- CI Run `35480732207`: PASS.
- Real-device behavior: PASS.
- Superseded as the current runtime baseline by device-verified P63A, but retained as historical rollback evidence.

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

## Six Button Refactor program
Completed:
- P63A — Six Button Service Boundary: completed/device passed/current promoted runtime baseline.

Planned follow-on stages:
- P63B — Clear Game Data dedicated-service extraction, cleanup/hardening and explicit error model.
- P63C — Backup engine extraction from `daochucd`.
- P63D — Restore engine extraction from `YYYPicker`.
- P63E — Remote Download engine extraction from `PubgLoad`.
- P63F — Cloud Save engine extraction from `PubgLoad`.

## P63B — Clear Game Data Dedicated Service — NEXT
### Goal
Move clear-game-data implementation out of `ZONSixButtonActionService` into a dedicated service while preserving the promoted P63A user-visible behavior first, then remove redundant destructive operations and replace silent `error:nil` filesystem handling with an explicit result/error contract.

### Required constraints
- P63A is the behavior baseline.
- No change to menu identifier/tag/title.
- No unrelated rewrite of remote download, cloud save, backup, restore or authorization reset.
- Keep tmp-directory preservation/recreation behavior unless a scoped change is separately justified and device-verified.
- Any removal of redundant Documents/Library deletion steps must be proven behavior-equivalent.
- Build A_customer + B_debug and run the scoped destructive-data device gate before promotion.

# Next Task
Implement **P63B Clear Game Data Dedicated Service** from the promoted `v1_p63a` baseline. Keep all five long-project state files synchronized throughout the stage.