# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Current promoted/device baseline — P69
- VERSION: `v1_p69`.
- Branch: `work/p69-save-transfer-coordinator`.
- Runtime/build source: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- A_customer artifact `10670576190`, dylib SHA256 `475d6721881ea69d1aebb131449ad66038342040fe98dcc9886207c167419574`.
- B_debug artifact `10670576184`, dylib SHA256 `23a07b9272cb6ce5f591d95d35c253858914d470918e3f9b5bcac865e0407615`.
- Real-device validation: PASS, explicitly reported by user (`全部正常`).
- Previous rollback baseline: P68 / `57492160450673f9ea17e69b9d4776668db32773`.

## Current architecture
`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONSaveTransferCoordinator -> ZONCloudSaveService / ZONRemoteDownloadService -> ZONRestoreAPI`

P69 makes the active menu host explicit across the save-transfer path. `PubgLoad` no longer owns active remote/cloud orchestration and remains only as a legacy compatibility shim for migrated selectors.

## Important regression history
- P67 CI passed but real-device restore regressed because the P66 post-restore lifecycle tail was bypassed. Never infer device correctness from CI alone.
- P67a restored the compatibility tail through `ZONRestoreAPI` and passed device validation.
- P68 extracted cloud-save networking/business parsing and passed device validation.
- P69 extracted remaining save-transfer UI/process orchestration and passed device validation.

## Next-stage rule
Do not reuse stale P65 planning sections. Before defining P70:
1. inspect the current P69 source,
2. identify remaining mixed responsibilities and external callers,
3. compare risk/value of candidate extractions,
4. choose a narrow stage with explicit behavior contracts and scoped device checks.

## Long-project rules
- Preserve commit history.
- Do not silently alter CI/release policy.
- CI success is not device promotion.
- Always distinguish modified / committed / CI-built / artifact-produced / device-verified / promoted.
- Keep all five long-project state files synchronized.
- For regressions, compare against the last explicitly device-passed baseline before proposing generic lower-layer causes.
