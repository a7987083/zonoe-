# CHANGELOG_DEV

## 2026-09-20 — v1_p63a Six Button Service Boundary — CI PASSED / DEVICE PENDING
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Candidate source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- `VERSION`: `v1_p63a`.
- CI Run `35483209464`: **success**.
- Added `testmod/ZONServices/ZONSixButtonActionService.h/.m` as the explicit service boundary for remote download, VIP cloud save, backup save, restore save, clear game data and clear authorization records.
- `ZONFeatureDispatcher` now routes all six scoped actions through `ZONSixButtonActionService` and no longer directly imports/calls the legacy six-button implementation classes for those actions.
- Preserved historical C dispatcher helper symbols as compatibility forwarders.
- Remote download still enters the existing `PubgLoad::yuanchengdwon` engine behind the boundary.
- VIP cloud save still ensures the tmp directory then enters `PubgLoad::checkCloudSaveStatus` behind the boundary.
- Backup still enters `daochucd::backupasd` behind the boundary.
- Restore still enters `YYYPicker::addBtnAction` behind the boundary.
- Clear-game-data behavior was moved behind the boundary while preserving the current 5-second timing, tmp preservation/recreation, Documents/Library/default-domain deletion and exit behavior; cleanup/hardening is deferred.
- Clear-authorization now reaches `ZONAuthorizationResetService` through the new boundary rather than routing the button through the legacy `WX_NongShiFu123::deletekm` entry.
- Added `tools/p63a_apply_six_button_service_boundary.py` for deterministic PBX source registration.
- Added `Tests/p63a_six_button_service_boundary_contract.py` to lock identifiers/tags, service routing, P62 reset contract and PBX membership.
- Added `.github/workflows/p63a-six-button-service-build.yml` with exact migrated-SHA pinning and A_customer/B_debug builds.
- Registry/service/PBX contract: PASS.
- A_customer `arm64 + arm64e` build/link/output: PASS.
- B_debug `arm64 + arm64e` build/link/output: PASS.
- A_customer artifact ID `10596866163`, digest `sha256:4770559f4d15706349e558e6b36c709e4242e0de8ae505ec9934b913d96822ae`, dylib SHA256 `2c90fed5247de6af6fe91bb6d1c57562621ff10542ae36b355924f5b78d7583b`.
- B_debug artifact ID `10596501583`, digest `sha256:c5cfe082bb2294a5eee0fc871226ee3ad9744ca3558d1d5ae5581c77ec631099`, dylib SHA256 `3063dbd4060767948686990772333f4fa2ecaa8c648252fc6d02641149e8ee6b`.
- P63A is **not promoted yet**; explicit six-button real-device PASS is still required.

## 2026-09-20 — v1_p62 Authorization Reset Service — DEVICE PASSED
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Product source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: **success**.
- Extracted the authorization reset clear set into `testmod/ZONServices/ZONAuthorizationResetService.h/.m`.
- `WX_NongShiFu123::deletekm` now forwards to the reset service rather than owning the clear implementation.
- Preserved the effective P62 UserDefaults, legacy `getKeychain`, `DZUDID`, bridge-cache and `ZONKeychain` clear behavior.
- Removed reset implementation ownership from the authorization coordinator while preserving compatibility startup behavior.
- Fixed deterministic reset-service PBX migration and exact migrated-revision CI pinning.
- A_customer and B_debug build/link/output verification: PASS.
- User explicitly reported the produced dylib tests fully normal on device.
- **P62 Authorization Reset Service is promoted/device-passed.**

## 2026-09-20 — v1_p62 ZONKeychain Migration — VERIFIED IN P62 LINE
- Replaced the active `SFHFKeychainUtils` UDID path with `ZONKeychain`.
- Removed `SFHFKeychainUtils.h/.m` from the active project surface and PBX references.
- Preserved the existing `UDID` / `com.china.TestKeyChain` identity semantics.
- Legacy `getKeychain` remains active for other historical keys and is outside the current six-button program.

## 2026-09-18 — v1_p51b Backup Refactor — DEVICE PASSED
- Work branch: `work/zonoemenu-v1-p51b-backup-refactor`.
- Product source commit: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`.
- CI Run `35255286856`: success.
- Refactored duplicated Documents/Library backup loops into a shared backup helper without changing the backup entry or output contract.
- Preserved the 50 MiB confirmation threshold, Skip/Backup choices, staging layout, cleanup paths, ZIP destination and share flow.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- User explicitly reported all required P51-B real-device tests normal.
- P51-B was promoted and later superseded.

## 2026-09-18 — v1_p51 Feature Execution Refactor — CI VERIFIED
- Standardized nine feature execution routing and de-duplicated runtime-toggle persistence.
- CI Run `35253980287`: success.
- Device behavior is covered by later promoted baselines.

## 2026-09-18 — v1_p50 Refactor Stabilization / Architecture Freeze
- Work branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- Runtime baseline remained P49 commit `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- Added architecture freeze contract, final status matrix and CI guardrails.

## Earlier architecture cleanup
- P49 Active Target / Dead Code / Dependency Audit: device passed.
- P48.1 StoreKit residual cleanup: device passed.
- P47 Repository Hygiene: CI passed.
- P46 Startup Side-Effect Instrumentation & Launch Contract: CI passed.
- P45 Legacy UDID Web/Profile Fallback Adapter Boundary: CI passed.
- P44 Authorization Orchestration Boundary: CI passed; device passed.
- P43 architecture audit: CI passed.
- P42 Zonoe UDID API Boundary: CI passed; device passed.
- P41 UDID Bridge Boundary: CI passed; device passed.

## Later corrective stages retained in project state
- P56 PubgLoad temp-boundary cleanup: device passed.
- P57 diagnostic stage: abandoned/reverted after server-side cause was confirmed.
- P58 download lifecycle hardening: device passed.
- P59 automatic UDID retry UX: superseded/not promoted.
- P60 UDID acquisition progress/manual retry: device passed.
- P61 offline authorization retry: CI passed; working line superseded by P62.
