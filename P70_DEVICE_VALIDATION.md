# P70 Device Validation

## Candidate
- Version: `v1_p70`
- Branch: `work/p70-backup-presentation-coordinator`
- Previous device baseline: `v1_p69`
- Previous device-baseline build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`
- P70 actual migrated/build SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`
- CI Run: `35678277659`
- CI status: `success`
- Device status: `passed`
- Promotion status: `promoted_device_passed`
- Device reported by user: `true`

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

## Real-device validation result
The user explicitly reported all scoped P70 real-device validation as normal.

Validated scope:
1. Launch, menu and six-button regression: passed.
2. Backup-name alert presentation: passed.
3. Empty backup name fallback to app bundle ID: passed.
4. Normal backup, progress HUD, and share/options menu: passed.
5. >50 MB `跳过` / `备份` decision paths: passed.
6. Share/options dismissal cleanup and subsequent backup attempt: passed.
7. P70-created ZIP restore, successful process exit, and restored data after relaunch: passed.
8. Local restore, remote ZIP restore and cloud-save restore regression: passed.
9. Failure paths do not falsely report success: passed.

## Promotion
P70 is now the promoted runtime/device baseline.

- Promoted version: `v1_p70`
- Promoted runtime SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`
- Promoted CI Run: `35678277659`
- Previous verified rollback baseline: `v1_p69` / `1e8240e66ddf95fcfeebe970417a5b8721908cd8`

Later documentation-only commits must not be confused with the verified P70 runtime SHA above.
