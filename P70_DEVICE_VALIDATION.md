# P70 Device Validation

## Candidate
- Version: `v1_p70`
- Branch: `work/p70-backup-presentation-coordinator`
- Device baseline: `v1_p69`
- Device-baseline build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`
- P70 actual migrated/build SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`
- CI Run: `35678277659`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## Artifacts
### A_customer
- Artifact ID: `10673084097`
- Artifact digest: `sha256:16ba447b6c766e74b1ac9f736496981944323dff524206acbbc87b114cf859d1`
- dylib SHA256: `8ec75343eaba37716d2627a11ce4bbacbfbe59527065145ee75b7e131b55b064`

### B_debug
- Artifact ID: `10673868377`
- Artifact digest: `sha256:8385d8c7a5f16cf3d5d5760a57788b2670f72cc44d5f7e89830e4503b8a391e5`
- dylib SHA256: `ec9429db69b07ae4ebc626fd66c2fa91fd41dd2939c597dfbac9e99f83d0ad64`

## Scope
P70 moves backup presentation/orchestration out of `daochucd` into `ZONBackupCoordinator`.

`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONBackupCoordinator -> ZONBackupService`

`daochucd::backupasd` remains only as a legacy compatibility shim. The P65 backup engine/policy are reused.

## Required real-device validation
Use A_customer first.

1. Launch, menu and six-button regression.
2. Backup button shows the existing backup-name alert.
3. Empty backup name still uses the app bundle ID.
4. Normal backup completes, HUD stages are sensible, and share/options menu appears.
5. For an item larger than 50 MB, both `跳过` and `备份` decisions behave correctly.
6. Dismissing the share/options menu cleans backup output/staging without breaking a second backup attempt.
7. A P70-created ZIP restores successfully through the current restore path; successful restore still closes the game and restored data is correct after relaunch.
8. Local restore, remote ZIP restore and cloud-save restore remain normal.
9. Invalid/failure paths do not falsely report backup/restore success.

P70 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
