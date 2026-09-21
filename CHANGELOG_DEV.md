# CHANGELOG_DEV

## 2026-09-21 — v1_p65 Backup Engine Refactor — DEVICE PASSED / PROMOTED
- Branch: `work/p65-backup-engine-refactor`.
- Actual build/runtime SHA: `60db9885c1c69ff7e658bd99949274884d898b32`.
- CI Run `35562076044`: success.
- A_customer `arm64 + arm64e`: PASS. Artifact `10622392644`, dylib SHA256 `83ab3e382d27e8c168a7428453e6b6da0f2acf0f5921877cb304e03485bde51e`.
- B_debug `arm64 + arm64e`: PASS. Artifact `10622696370`, dylib SHA256 `849760004323c613d63c58c1b516141a732ece72603f2e19927327bebcaf8839`.
- Introduced/registered the P65 backup service boundary and target-private header search path required by the service headers.
- Fixed the blocking compiler error `'ZONBackupService.h' file not found` without exporting private headers through the Headers build phase.
- Existing startup/menu and six-button behavior remained normal on device.
- Real-device backup creation completed normally.
- Backup output/share behavior remained normal.
- A backup produced by P65 restored successfully through the existing pre-P66 restore flow.
- Post-restore game/data behavior was reported normal.
- User explicitly reported the complete scoped P65 device validation as normal.
- **P65 is promoted/device-passed and becomes the rollback/runtime baseline for P66.**

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / SUPERSEDED
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Fixed P64 device failure where runtime `Library/Caches` behavior was incorrectly treated as fatal.
- User explicitly reported the P64a device regression normal.
- P64a was the baseline for P65 and is now superseded by promoted P65.

## 2026-09-21 — P64 Clear Game Data Dedicated Service — CI PASSED / DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; canonical stage is P64.
- Actual build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Device test exposed the `Library/Caches` runtime-directory verification defect.
- P64 was not promoted and was superseded by P64a.

## 2026-09-20 — P63 Six Button Service Boundary — DEVICE PASSED
- Historical built VERSION string: `v1_p63a`; canonical stage is P63.
- Runtime source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Added `ZONSixButtonActionService` and routed all six scoped actions through it.
- User explicitly reported all six scoped buttons normal on device.

## 2026-09-20 — P62 Authorization Reset Service — DEVICE PASSED / SUPERSEDED
- Source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Authorization reset extracted into `ZONAuthorizationResetService`.

## Version naming rule
- New stage increments the number: `P63 → P64 → P65 → P66`.
- Same-stage fixes use suffixes: `P64a → P64b → P64c`.
- Existing historical commits/artifacts are not rewritten.

## Next development stage — P66 Restore Engine Extraction
- Use promoted P65 runtime source `60db9885c1c69ff7e658bd99949274884d898b32` as the rollback baseline.
- Extract restore execution from `YYYPicker` behind a dedicated restore service.
- Preserve P65 backup-format compatibility and current user-visible restore behavior.
- Require A_customer + B_debug CI and real-device restore regression before promotion.
