# zonoemenu HANDOFF

## Source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Current promoted/device baseline — P69
- Version: `v1_p69`.
- Runtime/build source: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Real-device validation: PASS, explicitly reported by user.
- Keep P69 as rollback baseline until P70 is explicitly device-passed.

## Current work target — P70 Backup Presentation Coordinator
- Branch: `work/p70-backup-presentation-coordinator`.
- Version: `v1_p70`.
- Actual migrated/build source: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`.
- CI Run `35678277659`: success.
- Device status: pending.
- Architecture: `ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONBackupCoordinator -> ZONBackupService`.
- `daochucd` is compatibility shim only.
- P70 intentionally does not change `ZONBackupService`/`ZONBackupPolicy` backup format or restore stack.

## P70 artifacts
- A_customer artifact `10673084097`; digest `sha256:16ba447b6c766e74b1ac9f736496981944323dff524206acbbc87b114cf859d1`; dylib SHA256 `8ec75343eaba37716d2627a11ce4bbacbfbe59527065145ee75b7e131b55b064`.
- B_debug artifact `10673868377`; digest `sha256:8385d8c7a5f16cf3d5d5760a57788b2670f72cc44d5f7e89830e4503b8a391e5`; dylib SHA256 `ec9429db69b07ae4ebc626fd66c2fa91fd41dd2939c597dfbac9e99f83d0ad64`.

## Required P70 device validation
1. Launch/menu/six-button sanity.
2. Backup naming alert works from active host controller.
3. Empty name falls back to bundle ID.
4. Backup completes and share/options UI opens.
5. >50 MB item decision keeps both skip and backup choices working.
6. Dismissing share/options cleans temporary output without breaking the next backup.
7. P70-created ZIP restores through the current restore path and success still exits the game.
8. Remote/cloud/local restore paths do not regress.

## Long-project rules
- Preserve validated history; do not rewrite historical commits.
- Start a new stage from the latest device-passed runtime SHA, not docs-only HEAD.
- CI success is not promotion.
- Fix the first real compiler/runtime error; avoid unrelated cleanup during a regression fix.
- Keep all five long-project state files synchronized.
