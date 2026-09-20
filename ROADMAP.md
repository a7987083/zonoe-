# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p63a`.
- Promoted runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Six-button real-device regression: PASS, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- P63A remains the rollback/device baseline until P63B passes scoped device validation.

## P63A — Six Button Service Boundary — COMPLETED / DEVICE PASSED
- Added `ZONSixButtonActionService` as the six-action boundary.
- Dispatcher no longer directly owns the six legacy action implementations.
- Clear authorization reaches `ZONAuthorizationResetService` behind the boundary.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Device regression: PASS.

## P63B — Clear Game Data Dedicated Service — CI PASSED / DEVICE PENDING
### Candidate
- Work branch: `work/p63b-clear-game-data-service`.
- Version: `v1_p63b`.
- Actual migrated/build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- A_customer artifact `10608536720`, digest `sha256:18e6378aa6251eee08f2aaa7a377d6e9d82239ddbd706c24c4c209044bcaa605`.
- A_customer dylib SHA256 `7c39c585dc32688ecf78613a178feabb4ea72de0944d7ff35c4f6f8eb3e7e46b`.
- B_debug artifact `10609151564`, digest `sha256:6488e35a58ee36a1c4ca3906c69580997674d112dc226dd022db8b0bed1e87a6`.
- B_debug dylib SHA256 `53e0ada0b3141e93ce70a001791c42fd57b4c440634188b15db13a33c8a1caab`.
- Device status: pending.

### Product definition
“清除游戏数据” resets the primary app-local data toward a first-launch/reinstall-like state:
- clear `Documents/*`;
- clear `Library/*`;
- clear `tmp/*`;
- clear the app `NSUserDefaults` persistent domain;
- preserve top-level container directories;
- do not explicitly clear Keychain storage;
- do not touch App Group containers;
- do not delete iCloud/CloudKit remote data.

Important: P63B does not call the authorization-reset service or Keychain APIs, but resetting the whole app `NSUserDefaults` domain can still affect authorization/session state that is stored or mirrored there. Device validation must observe the real relaunch behavior rather than assume authorization is unchanged.

### Intentional behavior changes approved for P63B
- Removed the fixed 5-second pre-clean delay.
- Removed the fixed 5-second exit timer.
- Cleanup runs on a background queue.
- Staged progress is shown:
  1. preparing;
  2. game save/Documents;
  3. temporary files;
  4. local settings;
  5. Library/game data;
  6. verification;
  7. completed/exiting.
- Success exits immediately after reset completion.
- Critical cleanup/verification failure does not force exit and surfaces an error.

### Structural result
- Added pure Foundation `ZONGameDataResetService` with no UIKit/SVProgressHUD dependency.
- Confirmation/progress/exit orchestration remains in `ZONSixButtonActionService`.
- Replaced duplicate whole-directory delete + re-enumeration with one reusable directory-content cleaner.
- Destructive filesystem operations in the reset engine now propagate `NSError`.
- Added a final verification sweep for files recreated while the process is alive.
- Other five button engines remain unchanged.

### Verification completed
- Registry identifiers/tags unchanged: PASS.
- Six-button Dispatcher boundary: PASS.
- `ZONGameDataResetService` PBX membership: PASS.
- P63B behavior/architecture contract: PASS.
- No fixed 5-second clear-game-data timing remains: PASS.
- Reset engine has no UIKit/SVProgressHUD/auth-reset/Keychain dependency: PASS.
- Existing authorization-reset clear-set contract: PASS.
- A_customer xcodebuild/link/output: PASS.
- B_debug xcodebuild/link/output: PASS.
- `arm64 + arm64e` output verification: PASS.

### Promotion gate remaining
Scoped real-device P63B test:
- staged progress appears;
- no artificial 5-second wait;
- local game data is cleared;
- app exits when real cleanup completes;
- relaunch resembles fresh local state;
- observe actual authorization/session behavior after the app defaults domain reset;
- no regression in the other five button routes.

## Follow-on stages
- P63C — Backup engine extraction from `daochucd`.
- P63D — Restore engine extraction from `YYYPicker`.
- P63E — Remote Download engine extraction from `PubgLoad`.
- P63F — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history.
3. Do not change release policy outside scoped necessity.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.

# Next Task
Real-device validate `v1_p63b`. Do not promote P63B or begin P63C until the user explicitly reports the scoped clear-game-data regression passed.
