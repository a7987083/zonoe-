# CHANGELOG_DEV

## 2026-09-21 — v1_p63b Clear Game Data Dedicated Service — CI PASSED / DEVICE PENDING
- Work branch: `work/p63b-clear-game-data-service`.
- Baseline: promoted/device-passed `v1_p63a` runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- `VERSION`: `v1_p63b`.
- Actual migrated/build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: **success**.
- User-approved behavior change: removed both historical 5-second clear-game-data timers; cleanup completion now controls exit.
- Added `testmod/ZONServices/ZONGameDataResetService.h/.m` as a pure Foundation reset engine.
- Reset scope: `Documents/*`, `Library/*`, `tmp/*`, and the app `NSUserDefaults` persistent domain.
- The reset engine does not call Keychain, `getKeychain`, `ZONKeychain`, or `ZONAuthorizationResetService`; App Group and iCloud/CloudKit remote data are also out of scope.
- Because the complete app `NSUserDefaults` domain is reset, authorization/session behavior after relaunch is not assumed and must be observed on device.
- Removed the old duplicate whole-directory delete followed by re-enumeration.
- Added explicit filesystem preparation, cleanup, final verification and `NSError` propagation.
- Added one final verification sweep for files recreated while the process is still alive.
- `ZONSixButtonActionService` runs reset work on `QOS_CLASS_USER_INITIATED` rather than the main queue.
- Added stage display: preparing → game save/Documents → temporary files → local settings → Library/game data → verification → completed/exiting.
- Success exits immediately after reset completion; failure does not exit and surfaces the error.
- Other five button engines and the existing authorization-reset implementation are unchanged.
- Added deterministic `tools/p63b_apply_game_data_reset_service.py` PBX migration.
- Added `Tests/p63b_game_data_reset_contract.py` covering routing, PBX membership, no fixed 5-second clear delay, background/staged reset, failure behavior, and authorization-storage isolation.
- Added `.github/workflows/p63b-clear-game-data-service-build.yml` with exact migrated-SHA pinning.
- P63B contract/PBX migration: PASS.
- A_customer `arm64 + arm64e` build/link/output: PASS.
- B_debug `arm64 + arm64e` build/link/output: PASS.
- A_customer artifact ID `10608536720`, digest `sha256:18e6378aa6251eee08f2aaa7a377d6e9d82239ddbd706c24c4c209044bcaa605`, dylib SHA256 `7c39c585dc32688ecf78613a178feabb4ea72de0944d7ff35c4f6f8eb3e7e46b`.
- B_debug artifact ID `10609151564`, digest `sha256:6488e35a58ee36a1c4ca3906c69580997674d112dc226dd022db8b0bed1e87a6`, dylib SHA256 `53e0ada0b3141e93ce70a001791c42fd57b4c440634188b15db13a33c8a1caab`.
- **P63B is not promoted yet; scoped real-device validation remains required.**

## 2026-09-20 — v1_p63a Six Button Service Boundary — DEVICE PASSED
- Runtime source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Added `ZONSixButtonActionService` and routed all six scoped actions through it.
- A_customer and B_debug `arm64 + arm64e`: PASS.
- User explicitly reported all six scoped buttons normal on device.
- **P63A is promoted/device-passed and remains rollback baseline for P63B.**

## 2026-09-20 — v1_p62 Authorization Reset Service — DEVICE PASSED / SUPERSEDED
- Source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Authorization reset extracted into `ZONAuthorizationResetService`.
- Device validation passed; superseded by P63A.

## Earlier architecture cleanup
- P62 ZONKeychain migration: verified.
- P60 UDID acquisition progress/manual retry: device passed.
- P58 download lifecycle hardening: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P51/P51-B feature routing and backup refactor: device passed.
- P50 architecture freeze: completed.
- P49 active-target/dependency audit: device passed.
- P48.1 StoreKit residual cleanup: device passed.
- P41-P47 architecture/UDID/startup/repository stages retained as historical evidence.
