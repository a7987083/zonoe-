# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped stage plan/tests.

## Current promoted runtime baseline
- Version: `v1_p62`.
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Product source: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Real-device validation: passed, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10595647289`.
- A_customer dylib SHA256: `71f14901e140fd19cf175c0092e1cfdf46c7aefc04d2ba73b03baf83359f6962`.
- B_debug artifact: `10595652401`.
- B_debug dylib SHA256: `34cbcd9695c7eaad9096c606341fed008dce4e78094df1433243dd5cb9391c59`.
- P62 Authorization Reset Service is the current rollback/device baseline for the next six-button stage.

## P62 behavior/state to preserve
- `SFHFKeychainUtils` active usage has been replaced by `ZONKeychain`; legacy SFHF files are removed from the active project.
- `ZONAuthorizationResetService` owns the effective authorization clear set.
- The reset service clears the preserved NSUserDefaults authorization keys, legacy keychain keys (`SJUSERID`, `ShiSanGeDZKM`, `rjyyz`, `DZUDID`), UDID bridge cache and `ZONKeychain` `UDID/com.china.TestKeyChain` item.
- `WX_NongShiFu123::deletekm` is only a compatibility/legacy entry and must not regain ownership of reset internals.
- P62 CI pins build jobs to the exact migrated source revision and validates PBX membership before xcodebuild.

## Six-button execution architecture observed at P62
`ZONFeatureRegistry` and `ZONFeatureDispatcher` are already the menu routing boundary. The six scoped actions currently route to these legacy implementations:
- `base.remote-download` / tag 1 → `PubgLoad::yuanchengdwon`.
- `base.cloud-save` / tag 2 → `PubgLoad::checkCloudSaveStatus`.
- `data.backup-save` / tag 100 → `daochucd::backupasd`.
- `data.restore-save` / tag 101 → `YYYPicker::addBtnAction`.
- `data.clear-game-data` / tag 102 → destructive game-data implementation currently inside `ZONFeatureDispatcher.m`.
- `auth.clear-records` / tag 103 → Dispatcher confirmation → legacy `deletekm` entry → `ZONAuthorizationResetService`.

## Current architectural risks for this program
- `PubgLoad` mixes remote download, cloud save, network, ZIP, filesystem and UI responsibilities.
- `daochucd` mixes backup engine, prompt/progress and share UI.
- `YYYPicker` mixes document-picker UI with ZIP/restore/filesystem engine behavior.
- `ZONFeatureDispatcher` still contains destructive game-data behavior instead of only routing.
- Clear-authorization routing still passes through the legacy `WX_NongShiFu123` entry even though the service already exists.

## Frozen operating rules
- Registry/Dispatcher remains the menu execution boundary.
- P63A is a boundary-only stage: no deep rewrite of `PubgLoad`, `daochucd`, `YYYPicker`, or unrelated `WX_NongShiFu123.mm` logic.
- Preserve menu identifiers, legacy tags, titles and user-visible action behavior.
- Preserve download URL semantics, ZIP behavior, backup staging/layout, restore overwrite/skip behavior, clear-game-data semantics and authorization reset clear set.
- Active source/framework additions require PBX verification, dual-variant CI and normal promotion gates.
- CI success does not equal real-device promotion.
- Each completed runtime stage must provide the built dylib artifact(s) to the user after CI success.
- Do not modify existing release/CI semantics unless explicitly required by the scoped stage.

## Immediate Next Task — P63A Six Button Service Boundary
Create explicit service/adapter entry points for all six scoped actions and route `ZONFeatureDispatcher` through them while keeping the current engines internally unchanged.

Expected first-stage shape:
`ZONFeatureRegistry → ZONFeatureDispatcher → Service Boundary → existing implementation`

P63A completion requires:
1. Service boundary source is in PBX Sources.
2. Dispatcher no longer directly owns/knows the legacy implementation details for the six actions except through the service boundary.
3. Behavior-contract tests validate identifiers/tags and service routing.
4. A_customer and B_debug compile/link for `arm64 + arm64e`.
5. User performs six-button real-device smoke test before promotion.

## Follow-on order after P63A promotion
- P63B: clear-game-data service implementation extraction.
- P63C: backup engine extraction.
- P63D: restore engine extraction.
- P63E: remote-download engine extraction.
- P63F: cloud-save engine extraction.
