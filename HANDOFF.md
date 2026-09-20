# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped stage plan/tests.

## Promoted rollback/device baseline
- Version: `v1_p62`.
- Source: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Real-device validation: passed, explicitly reported by user.
- P62 remains the promoted rollback baseline until P63A receives explicit real-device PASS.

## Current candidate — v1_p63a
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Candidate source built by CI: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: **success**.
- Candidate status: **CI passed / awaiting six-button real-device validation**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10596866163`, digest `sha256:4770559f4d15706349e558e6b36c709e4242e0de8ae505ec9934b913d96822ae`.
- A_customer dylib SHA256: `2c90fed5247de6af6fe91bb6d1c57562621ff10542ae36b355924f5b78d7583b`.
- B_debug artifact: `10596501583`, digest `sha256:c5cfe082bb2294a5eee0fc871226ee3ad9744ca3558d1d5ae5581c77ec631099`.
- B_debug dylib SHA256: `3063dbd4060767948686990772333f4fa2ecaa8c648252fc6d02641149e8ee6b`.

## P63A architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → existing engine`

Six scoped routes:
- `base.remote-download` / tag 1 → service → `PubgLoad::yuanchengdwon`.
- `base.cloud-save` / tag 2 → service → tmp invariant → `PubgLoad::checkCloudSaveStatus`.
- `data.backup-save` / tag 100 → service → `daochucd::backupasd`.
- `data.restore-save` / tag 101 → service → `YYYPicker::addBtnAction`.
- `data.clear-game-data` / tag 102 → service-bound destructive implementation preserving P62 semantics.
- `auth.clear-records` / tag 103 → service → `ZONAuthorizationResetService`.

`ZONFeatureDispatcher` no longer directly imports/calls `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for these six actions. Historical C helper functions remain as compatibility forwarders.

## P62 behavior/state still protected
- `SFHFKeychainUtils` active usage is replaced by `ZONKeychain`; legacy SFHF files remain removed.
- `ZONAuthorizationResetService` owns the authorization clear set.
- Reset still clears the preserved NSUserDefaults authorization keys, legacy keychain keys (`SJUSERID`, `ShiSanGeDZKM`, `rjyyz`, `DZUDID`), UDID bridge cache and `ZONKeychain` `UDID/com.china.TestKeyChain` item.
- Legacy `getKeychain` migration is a separate storage concern and is not part of P63A.

## Frozen operating rules
- Registry/Dispatcher remains the menu execution boundary.
- P63A is behavior-preserving; any visible difference from P62 in the six scoped actions is a regression.
- Do not deep-rewrite `PubgLoad`, `daochucd`, `YYYPicker`, or unrelated `WX_NongShiFu123.mm` logic during P63A validation/fixes.
- Preserve menu identifiers, legacy tags, titles, download URL semantics, ZIP behavior, backup staging/layout, restore overwrite/skip behavior, clear-game-data semantics and authorization reset clear set.
- CI success does not equal real-device promotion.
- Existing release/CI semantics must not be changed outside scoped necessity.
- Keep all five long-project state files synchronized at every stage transition.

## Immediate Next Task — Real-device P63A gate
Test both launch stability and the six scoped actions. Required PASS:
1. Remote download opens/accepts input and follows the existing download/ZIP flow.
2. VIP cloud save follows the existing entitlement/check/download behavior.
3. Backup save preserves filename/default naming, large-item decision, ZIP output and share behavior.
4. Restore save preserves picker/import/unzip/restore behavior.
5. Clear game data shows the same confirmation, clears with the same semantics, exits and can relaunch normally.
6. Clear authorization shows the same confirmation, clears P62 authorization state, exits after the existing delay and requires normal reauthorization after relaunch.

Do not promote P63A or start P63B until the user explicitly reports this gate passed.

## Follow-on order after P63A promotion
- P63B: clear-game-data dedicated-service cleanup/hardening and error-model work.
- P63C: backup engine extraction.
- P63D: restore engine extraction.
- P63E: remote-download engine extraction.
- P63F: cloud-save engine extraction.
