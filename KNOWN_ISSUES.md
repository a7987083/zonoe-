# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p69` / runtime source `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- P69 CI Run `35668507458`: success; real-device validation passed.
- Current candidate: `v1_p70` / runtime source `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`.
- P70 CI Run `35678277659`: success; device validation pending.
- Architectures: `arm64 + arm64e`.

## Open risks

### P70 backup presentation relocation needs device proof
- The backup engine itself remains `ZONBackupService`/`ZONBackupPolicy`, but alert/HUD/share orchestration moved from `daochucd` to `ZONBackupCoordinator`.
- Validate presentation from the active menu host, especially the name alert and share/options controller.
- Validate >50 MB skip/backup prompt behavior.
- Validate cleanup after dismissing the share/options menu does not affect a subsequent backup.

### Backup/restore compatibility remains a promotion gate
- P70 intentionally does not change archive format, but the produced ZIP must still be restored successfully through the current `ZONRestoreAPI` path before promotion.
- Successful restore must retain the verified PreferenceManager/cleanup/exit lifecycle.

### YYYPicker remains UI-heavy
- Restore core is already behind `ZONRestoreAPI`, but `YYYPicker` still combines document picker, file browsing, collection-view and QuickLook UI responsibilities.
- Any future extraction should start only after a fresh audit from the latest device-passed runtime baseline.

## Closed / corrected
- P69 save-transfer coordinator: CLOSED / DEVICE PASSED. `PubgLoad` is compatibility shim only.
- P68 cloud-save engine extraction: CLOSED / DEVICE PASSED.
- P67 post-restore regression: CLOSED by P67a; P67 itself remains not promoted.
- P65 backup engine duplication/policy ownership: CLOSED by `ZONBackupService` + `ZONBackupPolicy`.

## Tracking rule
- CI success alone does not equal promotion.
- P69 stays rollback baseline until explicit P70 device confirmation.
- Every stage transition must keep `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` synchronized.
