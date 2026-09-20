# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped stage tests/workflow.

## Promoted rollback/device baseline — v1_p63a
- Runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Six-button real-device validation: passed.
- P63A remains promoted until P63B passes its scoped device gate.

## Current candidate — v1_p63b
- Branch: `work/p63b-clear-game-data-service`.
- Actual migrated/build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: **success**.
- Status: **CI passed / awaiting scoped real-device validation**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact `10608536720`, dylib SHA256 `7c39c585dc32688ecf78613a178feabb4ea72de0944d7ff35c4f6f8eb3e7e46b`.
- B_debug artifact `10609151564`, dylib SHA256 `53e0ada0b3141e93ce70a001791c42fd57b4c440634188b15db13a33c8a1caab`.

## P63B architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONGameDataResetService → Foundation filesystem/UserDefaults`

Responsibilities:
- `ZONFeatureDispatcher`: routing only.
- `ZONSixButtonActionService`: confirmation, progress/HUD, background scheduling, success/failure UI, process exit.
- `ZONGameDataResetService`: pure Foundation cleanup/verification/error propagation; no UIKit/SVProgressHUD and no Keychain/auth-reset API calls.

## Clear-game-data behavior in P63B
- clear `Documents/*`;
- clear `Library/*`;
- clear `tmp/*`;
- remove the entire app `NSUserDefaults` persistent domain;
- preserve top-level container directories;
- no fixed 5-second pre-clean wait;
- no fixed 5-second exit timer;
- success exits immediately when cleanup/verification finishes;
- failure does not force exit.

The service does **not explicitly clear Keychain authorization storage**, App Group containers, or iCloud/CloudKit remote data. However, because the complete app `NSUserDefaults` domain is cleared, authorization/session behavior after relaunch may still change depending on which state is mirrored in defaults. Do not assume either outcome; verify on device.

## Stage display
1. `正在准备清理…`
2. `正在清理游戏存档…`
3. `正在清理临时文件…`
4. `正在重置本地设置…`
5. `正在清理游戏数据…`
6. `正在检查清理结果…`
7. `清理完成，正在退出…`

## CI verification already passed
- deterministic prerequisite/P63B PBX migrations;
- P63B behavior/architecture contract;
- exact migrated-SHA pinning;
- A_customer Xcode build/link/output;
- B_debug Xcode build/link/output;
- `arm64 + arm64e` dylib output checks.

## Immediate Next Task — P63B device gate
Test the supplied `v1_p63b` candidate and confirm:
1. confirmation UI opens normally;
2. stage display is visible and changes during cleanup;
3. there is no artificial five-second wait;
4. local game data is actually reset;
5. app exits after cleanup completes;
6. relaunch resembles fresh local game state;
7. observe whether authorization/session persists, rehydrates, or requires normal authorization after defaults reset;
8. remote download, cloud save, backup, restore and clear-authorization routes still open normally.

Do not promote P63B or start P63C until the user explicitly reports the scoped device gate passed.

## Follow-on order
- P63C: backup engine extraction.
- P63D: restore engine extraction.
- P63E: remote-download engine extraction.
- P63F: cloud-save engine extraction.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
