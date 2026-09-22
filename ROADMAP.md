# ROADMAP

## Current promoted runtime baseline — P69 / DEVICE PASSED
- Version: `v1_p69`.
- Runtime/build source: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Real-device validation: PASS, explicitly reported by user.
- P69 remains the rollback/device baseline while P70 is under device validation.

## P70 — Backup Presentation Coordinator Extraction — CI PASSED / DEVICE PENDING
- Branch: `work/p70-backup-presentation-coordinator`.
- Version: `v1_p70`.
- Baseline: P69 runtime SHA `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- Actual migrated/build SHA: `a8a6316b0490bbbfcdd9e98d1feb78bdfa56a82c`.
- CI Run `35678277659`: success.
- A_customer + B_debug: Xcode 16.4 build, arm64+arm64e verification and artifact upload all PASS.
- Architecture: `ZONSixButtonActionService -> ZONBackupCoordinator -> ZONBackupService`.
- `daochucd` is now legacy compatibility shim only.
- P65 backup engine and policy remain the implementation core; P70 does not change archive format or include/exclude policy.

### P70 device gates
1. Launch/menu/six-button regression.
2. Backup naming alert appears from the active host controller.
3. Blank backup name still falls back to bundle ID.
4. Normal backup completes and share/options UI appears.
5. Large-item (>50 MB) skip/backup decision behaves as before.
6. Share/options dismissal cleanup does not break a subsequent backup.
7. A P70-created ZIP restores successfully through the current restore flow and success still closes the game.
8. Remote/cloud/local restore regressions remain normal.

## Completed recent stages
- P65 — Backup engine/service + policy extraction.
- P66 — Restore engine extraction.
- P67 — Remote-download extraction; CI passed but device failed because post-restore lifecycle was bypassed.
- P67a — `ZONRestoreAPI` restored the P66 PreferenceManager/exit tail; device passed.
- P68 — Cloud-save engine extraction; device passed.
- P69 — Save-transfer coordinator extraction; `PubgLoad` reduced to compatibility shim; device passed.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not rewrite validated historical commits.
3. New functional stages increment the numeric version; suffix letters are fixes only.
4. CI success does not equal device promotion.
5. Runtime/build SHA and later documentation HEAD must be recorded separately.
6. Start every new phase from the latest device-passed runtime SHA, not a later docs-only SHA.
7. Keep `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` synchronized.

# Next Task
Complete P70 real-device validation. Do not define/promote P71 until P70 device behavior is explicitly confirmed or a P70a fix is required.
