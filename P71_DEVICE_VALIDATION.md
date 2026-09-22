# P71 Device Validation

## Candidate
- Version: `v1_p71`
- Branch: `work/p71-local-restore-coordinator`
- Device baseline: `v1_p70`
- Device-baseline build SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`
- P71 actual migrated/build SHA: `ef556183635b6d7256bb33eac456eff9bccae190`
- CI Run: `35690162490`
- CI status: `success`
- Device status: `passed`
- Device reported by user: `true`
- Promotion status: `promoted`

## Artifacts
### A_customer
- Artifact ID: `10678023711`
- Artifact digest: `sha256:038f4d4a99884c459d9acb2e90d6eb1e0db6effd205cb469397deabf0484230a`
- dylib SHA256: `0cc598d17a7f7ba3bf396186fab7c458d6ebb9b82ab2cbd5bb5b49e1f4fb6457`

### B_debug
- Artifact ID: `10677973826`
- Artifact digest: `sha256:6bb603a408ef0fe2c631fac48df7168bcecf751965e16b4fa671fc1739514085`
- dylib SHA256: `afb5edc8e789104e4b7c6c92a34653b3fb214bd0c6ba1a2beee02c28689d1abb`

## Scope
P71 moves local restore presentation/orchestration out of `YYYPicker` into `ZONLocalRestoreCoordinator`.

`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONLocalRestoreCoordinator -> ZONRestoreAPI -> ZONRestoreService`

`YYYPicker` keeps its file browser / QuickLook responsibilities. Its historical `addBtnAction`, `restorePreparedArchiveStaging`, and `yidongwenjian` methods remain as compatibility shims. P66/P67a post-success preference reload / cleanup / process-exit behavior remains behind `ZONRestoreAPI`.

## Real-device validation result
User explicitly reported all scoped validation items as normal.

Validated on device:
1. Launch, menu and six-button regression normal.
2. Local restore opens the Files document picker normally.
3. Valid backup ZIP restore path works with processing HUD.
4. Successful local restore still closes the game automatically through the preserved P66/P67a tail.
5. Relaunch confirms restored data is correct.
6. Cancelling the document picker does not crash or falsely report success.
7. Invalid/non-backup input does not falsely report success or exit as success.
8. Remote ZIP restore and cloud-save restore remain normal and auto-close on success.
9. P70 backup creation/share flow remains normal.
10. Local restore remains reusable after prior cancelled/failed attempts.

## Promotion
P71 is promoted as the current device-verified runtime baseline.
Previous device-verified rollback baseline remains P70: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`.
