# CHANGELOG_DEV

## 2026-09-21 — v1_p63b Clear Game Data Dedicated Service — IN PROGRESS
- Work branch: `work/p63b-clear-game-data-service`.
- Baseline: promoted/device-passed `v1_p63a` runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- `VERSION`: `v1_p63b`.
- User-approved behavior change: remove both historical 5-second clear-game-data timers; cleanup completion now controls exit.
- Added `testmod/ZONServices/ZONGameDataResetService.h/.m` as a pure Foundation reset engine.
- Reset scope is primary app-local data only: `Documents/*`, `Library/*`, `tmp/*`, and the app `NSUserDefaults` persistent domain.
- Keychain/authorization storage, App Group containers, and iCloud/CloudKit remote data are explicitly out of scope.
- Removed the old duplicated pattern of deleting whole Documents/Library and then enumerating the same paths again.
- Added explicit filesystem preparation, cleanup, verification and `NSError` propagation instead of silent destructive `error:nil` handling inside the reset engine.
- Added one final verification sweep for files recreated while the process is still alive.
- `ZONSixButtonActionService` now runs reset work on `QOS_CLASS_USER_INITIATED` instead of the main queue.
- Added staged progress UI: preparing → game save/Documents → temporary files → local settings → Library/game data → verification → completed/exiting.
- Success path exits immediately after reset completion; failure path does not exit and surfaces the error.
- The other five button engines and authorization reset clear set are intentionally unchanged.
- Added deterministic `tools/p63b_apply_game_data_reset_service.py` PBX migration.
- Added `Tests/p63b_game_data_reset_contract.py` locking six-button routing, no fixed 5-second clear delay, staged/background reset semantics, authorization isolation and PBX membership.
- Added dedicated `.github/workflows/p63b-clear-game-data-service-build.yml`; CI/device validation still pending.

## 2026-09-20 — v1_p63a Six Button Service Boundary — DEVICE PASSED
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Candidate/runtime source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- `VERSION`: `v1_p63a`.
- CI Run `35483209464`: **success**.
- Added `testmod/ZONServices/ZONSixButtonActionService.h/.m` as the explicit service boundary for remote download, VIP cloud save, backup save, restore save, clear game data and clear authorization records.
- `ZONFeatureDispatcher` now routes all six scoped actions through `ZONSixButtonActionService` and no longer directly imports/calls the legacy six-button implementation classes for those actions.
- Preserved historical C dispatcher helper symbols as compatibility forwarders.
- Remote download still enters the existing `PubgLoad::yuanchengdwon` engine behind the boundary.
- VIP cloud save still ensures the tmp directory then enters `PubgLoad::checkCloudSaveStatus` behind the boundary.
- Backup still enters `daochucd::backupasd` behind the boundary.
- Restore still enters `YYYPicker::addBtnAction` behind the boundary.
- Clear-authorization now reaches `ZONAuthorizationResetService` through the new boundary rather than routing the button through the legacy `WX_NongShiFu123::deletekm` entry.
- Added deterministic PBX source registration, behavior/service-boundary contracts and exact migrated-SHA CI pinning.
- A_customer and B_debug `arm64 + arm64e` build/link/output: PASS.
- User explicitly reported all six scoped buttons normal on device.
- **P63A is promoted/device-passed and is the baseline for P63B.**

## 2026-09-20 — v1_p62 Authorization Reset Service — DEVICE PASSED / SUPERSEDED
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Product source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: **success**.
- Extracted authorization reset behavior into `ZONAuthorizationResetService`.
- Preserved the effective P62 UserDefaults, legacy `getKeychain`, bridge-cache and `ZONKeychain` clear behavior.
- A_customer and B_debug build/link/output verification: PASS.
- User explicitly reported the produced dylib tests fully normal on device.
- Superseded as current runtime baseline by P63A.

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
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- User explicitly reported all required P51-B real-device tests normal.

## Earlier architecture cleanup
- P51 Feature Execution Refactor: CI verified.
- P50 Refactor Stabilization / Architecture Freeze: completed.
- P49 Active Target / Dead Code / Dependency Audit: device passed.
- P48.1 StoreKit residual cleanup: device passed.
- P47 Repository Hygiene: CI passed.
- P46 Startup Side-Effect Instrumentation & Launch Contract: CI passed.
- P45 Legacy UDID Web/Profile Fallback Adapter Boundary: CI passed.
- P44 Authorization Orchestration Boundary: device passed.
- P43 architecture audit: CI passed.
- P42 Zonoe UDID API Boundary: device passed.
- P41 UDID Bridge Boundary: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P57 diagnostic stage: abandoned/reverted after server-side cause was confirmed.
- P58 download lifecycle hardening: device passed.
- P59 automatic UDID retry UX: superseded/not promoted.
- P60 UDID acquisition progress/manual retry: device passed.
- P61 offline authorization retry: CI passed; superseded by P62.
