# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p69`.
- Runtime/build source: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Real-device validation: passed, explicitly reported by user (`全部正常`).
- Architectures: `arm64 + arm64e`.
- Previous rollback baseline: P68 / `57492160450673f9ea17e69b9d4776668db32773`.

## Open risks

### `PubgLoad` still exists as a legacy compatibility surface
- P69 removed the active remote-download/cloud-save orchestration from `PubgLoad`.
- Legacy selectors still forward through `PubgLoad` for compatibility.
- Do not delete or further collapse this shim until current external callers are audited and a contract proves removal is safe.

### Next-stage ownership is not yet defined
- P65–P69 completed the backup/restore/remote/cloud save-transfer refactor chain.
- The next high-value refactor must be selected from the current P69 source, not from old ROADMAP assumptions.
- Candidate work should have a clear boundary, measurable risk reduction, and a narrow device-validation surface.

### Post-restore lifecycle is behavior-sensitive
- P67 proved that a structurally cleaner call chain can still regress real-device lifecycle behavior.
- `ZONRestoreAPI` and the established post-success PreferenceManager/exit tail must remain the compatibility boundary unless a separately validated change replaces it.

## Closed / corrected

### P69 save-transfer coordinator — CLOSED / DEVICE PASSED
- Main save-transfer routes now receive the active host view controller explicitly through `ZONSixButtonActionService`.
- `ZONSaveTransferCoordinator` owns remote/cloud UI and process orchestration.
- P67/P67a/P68 service stack remains reused.
- User explicitly reported all scoped P69 behavior normal on device.
- P69 is promoted.

### P68 cloud-save extraction — CLOSED / DEVICE PASSED
- Cloud-save metadata/entitlement/network business logic lives in `ZONCloudSaveService`.
- Real-device validation passed.

### P67 remote-download migration regression — CLOSED BY P67a
- P67 bypassed the established post-restore lifecycle tail.
- P67a routed successful restore through `ZONRestoreAPI` compatibility behavior and passed device validation.

### P66 restore engine extraction — CLOSED / DEVICE PASSED
- Restore engine/service boundary passed real-device validation.

### P65 backup engine refactor — CLOSED / DEVICE PASSED
- Backup engine refactor passed real-device backup/restore validation.

## Tracking rule
- CI success alone does not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json`, and `KNOWN_ISSUES.md` together.
- The next stage must start from P69 as the verified baseline unless a deliberate rollback is requested.
