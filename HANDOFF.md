# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped stage plan/tests.

## Current promoted runtime baseline — v1_p63a
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Runtime source built by CI: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: **success**.
- Real-device validation: **passed, explicitly reported by user for all six scoped buttons**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10596866163`, digest `sha256:4770559f4d15706349e558e6b36c709e4242e0de8ae505ec9934b913d96822ae`.
- A_customer dylib SHA256: `2c90fed5247de6af6fe91bb6d1c57562621ff10542ae36b355924f5b78d7583b`.
- B_debug artifact: `10596501583`, digest `sha256:c5cfe082bb2294a5eee0fc871226ee3ad9744ca3558d1d5ae5581c77ec631099`.
- B_debug dylib SHA256: `3063dbd4060767948686990772333f4fa2ecaa8c648252fc6d02641149e8ee6b`.
- P63A is the promoted comparison/rollback baseline for P63B.

## P63A architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → existing engine`

Six scoped routes:
- `base.remote-download` / tag 1 → service → `PubgLoad::yuanchengdwon`.
- `base.cloud-save` / tag 2 → service → tmp invariant → `PubgLoad::checkCloudSaveStatus`.
- `data.backup-save` / tag 100 → service → `daochucd::backupasd`.
- `data.restore-save` / tag 101 → service → `YYYPicker::addBtnAction`.
- `data.clear-game-data` / tag 102 → service-bound destructive implementation preserving P63A behavior.
- `auth.clear-records` / tag 103 → service → `ZONAuthorizationResetService`.

`ZONFeatureDispatcher` no longer directly imports/calls `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for these six actions. Historical C helper functions remain as compatibility forwarders.

## Behavior that P63B must preserve initially
Clear-game-data currently:
- shows the existing destructive confirmation UI;
- shows `SVProgressHUD` processing state;
- schedules destructive work after the existing 5-second delay;
- clears tmp children while preserving/recreating the tmp directory;
- removes Documents and Library using the current P63A semantics;
- clears the app UserDefaults persistent domain;
- retains the current exit timing/behavior.

P63B may improve internal implementation only after behavior-equivalence is locked. In particular, redundant remove/enumerate operations and silent `error:nil` calls may be replaced with a dedicated service and explicit error model, but the promoted P63A behavior is the comparison baseline.

## Protected state from earlier stages
- `SFHFKeychainUtils` active usage remains replaced by `ZONKeychain`.
- `ZONAuthorizationResetService` owns the authorization clear set.
- Legacy `getKeychain` migration is a separate storage concern and must not be folded into P63B.
- Startup/bootstrap, UDID, authorization retry and module loading behavior remain out of scope.

## Frozen operating rules
- Registry/Dispatcher remains the menu execution boundary.
- Do not recouple Dispatcher to legacy implementation classes.
- Preserve menu identifiers, legacy tags and user-facing semantics.
- Existing release/CI semantics must not be changed outside scoped necessity.
- A_customer + B_debug `arm64 + arm64e` builds are required for runtime candidates.
- CI success does not equal device promotion.
- Keep all five long-project state files synchronized at every stage transition.

## Immediate Next Task — P63B Clear Game Data Dedicated Service
Create a dedicated clear-game-data service behind `ZONSixButtonActionService`.

Required sequence:
1. Lock current P63A clear-game-data behavior as the comparison contract.
2. Move destructive implementation out of `ZONSixButtonActionService` into the dedicated service.
3. Preserve confirmation UI and existing external timing/exit behavior.
4. Remove redundant filesystem operations only with behavior-equivalence evidence.
5. Replace silent filesystem failures with explicit result/error propagation where it does not change the promoted UX contract.
6. Add PBX/behavior contracts.
7. Build A_customer + B_debug for `arm64 + arm64e`.
8. Perform scoped real-device destructive-data regression before promotion.

## Follow-on order after P63B
- P63C: backup engine extraction.
- P63D: restore engine extraction.
- P63E: remote-download engine extraction.
- P63F: cloud-save engine extraction.
