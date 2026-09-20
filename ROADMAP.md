# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task.

## Current promoted runtime baseline
- Device-verified version: `v1_p63a`.
- Promoted runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- Promoted CI Run `35483209464`: **success**.
- Six-button real-device regression: **PASS, explicitly reported by user**.
- Architectures: `arm64 + arm64e`.
- P63A remains the rollback/device baseline until P63B passes CI and scoped device validation.

## P63A — Six Button Service Boundary — COMPLETED / DEVICE PASSED
- Added `ZONSixButtonActionService` as the explicit boundary for remote download, VIP cloud save, backup, restore, clear game data and clear authorization.
- `ZONFeatureDispatcher` no longer directly owns the six legacy action implementations.
- Clear authorization reaches the existing `ZONAuthorizationResetService` behind the boundary.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Device regression: PASS.

## P63B — Clear Game Data Dedicated Service — IN PROGRESS
### Work branch
- `work/p63b-clear-game-data-service`
- `VERSION`: `v1_p63b`
- Baseline: promoted `v1_p63a`.

### Product definition
“清除游戏数据” means resetting the primary app data container toward a first-launch/reinstall-like state:
- clear contents of `Documents`;
- clear contents of `Library`;
- clear contents of `tmp`;
- clear the app `NSUserDefaults` persistent domain;
- do **not** clear Keychain/authorization storage;
- do **not** clear App Group containers;
- do **not** delete iCloud/CloudKit remote data.

### Intentional behavior changes approved for P63B
- Remove the historical fixed 5-second delay before cleanup.
- Remove the historical fixed 5-second exit timer.
- Perform filesystem cleanup on a background queue.
- Show real cleanup stages instead of a generic waiting period:
  1. preparing;
  2. game save/Documents;
  3. temporary files;
  4. local settings;
  5. Library/game data;
  6. verification;
  7. completed/exiting.
- Exit immediately after the reset service reports complete success.
- If any critical cleanup/verification step fails, do not exit; show the failure and keep diagnostic error information.

### Structural goals
- Add pure Foundation `ZONGameDataResetService` with no UIKit/SVProgressHUD dependency.
- Keep confirmation/progress UI and process exit orchestration in `ZONSixButtonActionService`.
- Replace duplicated Documents/Library remove-then-enumerate logic with one reusable directory-content cleaner.
- Replace silent `error:nil` destructive operations inside the reset engine with explicit `NSError` propagation.
- Preserve the other five button engines unchanged.

### Verification gates
- Registry identifiers/tags unchanged.
- Six-button Dispatcher boundary preserved.
- `ZONGameDataResetService` PBX membership verified.
- No 5-second clear-game-data delay remains.
- Reset engine does not depend on UIKit, SVProgressHUD, authorization-reset classes, `getKeychain`, or `ZONKeychain`.
- P62/P63A authorization reset contract remains unchanged.
- A_customer build/link/output: required.
- B_debug build/link/output: required.
- `arm64 + arm64e`: required.
- Scoped real-device test required before promotion:
  - staged progress is visible;
  - cleanup completes without fixed wait;
  - app exits after completion;
  - relaunch behaves like fresh local game state;
  - authorization remains intact unless the separate authorization button is used;
  - cleanup failure must not force exit.

## Follow-on stages
- P63C — Backup engine extraction from `daochucd`.
- P63D — Restore engine extraction from `YYYPicker`.
- P63E — Remote Download engine extraction from `PubgLoad`.
- P63F — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface.
2. Preserve commit history; do not rewrite published stage history.
3. Existing release policy/semantics must not be changed outside the scoped stage.
4. CI success does not equal device promotion.
5. Every runtime candidate requires A_customer + B_debug `arm64 + arm64e` validation.
6. Keep `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json`, and `KNOWN_ISSUES.md` synchronized at each stage transition.

# Next Task
Complete P63B implementation, deterministic PBX migration and P63B behavior contract, then run A_customer/B_debug CI. Do not promote P63B until the user explicitly passes the scoped real-device clear-game-data regression.
