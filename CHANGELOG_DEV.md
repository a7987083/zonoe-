# CHANGELOG_DEV

## 2026-09-22 — v1_p70 Backup Presentation Coordinator — CI PASSED / DEVICE PENDING
- Branch: `work/p70-backup-presentation-coordinator`.
- Baseline: promoted P69 runtime `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- Actual migrated/build SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`.
- CI Run `35678277659`: success.
- Added `ZONBackupCoordinator` as the backup presentation/orchestration boundary.
- `ZONSixButtonActionService` now passes its existing host view controller directly to the coordinator.
- `daochucd::backupasd` is retained only as a compatibility shim.
- `ZONBackupService` / `ZONBackupPolicy` remain the existing pure backup core; archive layout and backup policy were not intentionally changed.
- Preserved backup-name alert, blank-name bundle-ID fallback, >50 MB decision prompt, stage HUD, share/options UI and post-options cleanup.
- Inherited P65/P67/P67a/P68/P69 contracts plus P70 contract passed.
- A_customer and B_debug Xcode 16.4 arm64+arm64e builds passed.
- Device promotion remains blocked pending scoped real-device validation.

## 2026-09-22 — v1_p69 Save Transfer Coordinator — DEVICE PASSED / PROMOTED
- Runtime/build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Moved remote-download/cloud-save UI orchestration from `PubgLoad` to `ZONSaveTransferCoordinator`.
- `PubgLoad` became a legacy compatibility shim.
- User explicitly reported the P69 real-device regression fully normal.
- P69 is the current promoted rollback baseline for P70.

## Recent completed stages
- P68 `57492160450673f9ea17e69b9d4776668db32773`: cloud-save engine extraction; CI + device PASS.
- P67a `0433ab7f3ce24f5a11dd3d8a4fe3be360a233d61`: restored post-success PreferenceManager/exit lifecycle; CI + device PASS.
- P67 `71410f993dc9c00d16586af75c7d8e05bcdc8307`: CI PASS / DEVICE FAILED; not promoted.
- P66 `5cd3667754449b9a7630ba2d1e7db472d692377b`: restore engine extraction; device PASS.
- P65 `60db9885c1c69ff7e658bd99949274884d898b32`: backup engine refactor; device PASS.

## Operating rule
CI success alone does not equal device promotion. Runtime/build SHA, artifact SHA and documentation-only HEADs must remain distinguishable.
