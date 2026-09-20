# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped stage tests/workflow.

## Current promoted runtime baseline — v1_p63a
- Promoted runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Six-button real-device validation: passed, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- P63A remains rollback/device baseline until P63B is explicitly device-passed.

## Current work — v1_p63b
- Branch: `work/p63b-clear-game-data-service`.
- Phase: `P63B Clear Game Data Dedicated Service`.
- Status: implementation in progress; CI/device not yet promoted.
- User explicitly approved changing the clear-game-data external behavior: remove fixed 5-second waits and exit when real cleanup finishes.

## P63B target architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONGameDataResetService → Foundation filesystem/UserDefaults`

Responsibilities:
- `ZONFeatureDispatcher`: routing only.
- `ZONSixButtonActionService`: destructive confirmation, stage text/HUD, background scheduling, success/failure UI, process exit.
- `ZONGameDataResetService`: pure Foundation cleanup/verification/error propagation; no UIKit and no authorization storage.

## P63B clear-game-data definition
Reset the main app-local data toward a reinstall/first-launch state:
- clear `Documents/*`;
- clear `Library/*`;
- clear `tmp/*`;
- remove the app `NSUserDefaults` persistent domain;
- preserve top-level container directories;
- do not touch Keychain/authorization data;
- do not touch App Group containers;
- do not delete iCloud/CloudKit remote data.

## Approved stage display
1. `正在准备清理…`
2. `正在清理游戏存档…`
3. `正在清理临时文件…`
4. `正在重置本地设置…`
5. `正在清理游戏数据…`
6. `正在检查清理结果…`
7. `清理完成，正在退出…`

## P63B implementation rules
- No fixed 5-second pre-clean delay.
- No fixed 5-second exit timer.
- Filesystem cleanup runs off the main queue.
- Successful reset exits immediately after the service completes.
- Any critical cleanup or verification failure must not force exit.
- Remove old redundant whole-directory delete + second enumeration behavior.
- Use one reusable directory-content cleaner.
- Reset engine must return observable `NSError` details.
- One final verification sweep may remove files recreated during the still-running process.
- Authorization reset remains independently owned by `ZONAuthorizationResetService`; its historical 3-second exit behavior is outside P63B and must not be changed here.
- Remote download, cloud save, backup and restore engines remain untouched.

## New P63B files
- `testmod/ZONServices/ZONGameDataResetService.h`
- `testmod/ZONServices/ZONGameDataResetService.m`
- `tools/p63b_apply_game_data_reset_service.py`
- `Tests/p63b_game_data_reset_contract.py`
- `.github/workflows/p63b-clear-game-data-service-build.yml`

## Required verification before promotion
1. Deterministic PBX membership for `ZONGameDataResetService.m`.
2. P63B contract passes.
3. Six-button Dispatcher boundary remains intact.
4. Authorization reset clear set remains unchanged.
5. A_customer builds and links for `arm64 + arm64e`.
6. B_debug builds and links for `arm64 + arm64e`.
7. Dylib output validation passes.
8. User device test confirms:
   - stage display is visible;
   - no artificial 5-second wait;
   - local game data is cleared;
   - app exits after completion;
   - relaunch is fresh-local-state behavior;
   - authorization remains intact;
   - failure does not force exit.

## Follow-on order after P63B promotion
- P63C: backup engine extraction.
- P63D: restore engine extraction.
- P63E: remote-download engine extraction.
- P63F: cloud-save engine extraction.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy/semantics.
- CI success is not device promotion.
- Keep all five long-project state files synchronized at every stage transition.
