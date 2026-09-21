# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p65`.
- Runtime/build source: `60db9885c1c69ff7e658bd99949274884d898b32`.
- CI Run `35562076044`: success.
- P65 real-device validation: passed, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- Next development stage: P66 restore engine extraction.

## Open risks

### `YYYPicker` still mixes picker UI and restore engine
- Restore extraction is the P66 target.
- P66 must preserve the device-proven ability to restore backups produced by P65.
- Archive path/layout semantics accepted by the current implementation must be locked before refactoring.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download extraction is planned for P67.
- Cloud save extraction is planned for P68.

## Closed / corrected

### P65 backup engine refactor — CLOSED / DEVICE PASSED
- Runtime/build source: `60db9885c1c69ff7e658bd99949274884d898b32`.
- CI Run `35562076044`: success.
- A_customer and B_debug `arm64 + arm64e`: PASS.
- Startup/menu and existing six-button regression: PASS.
- Real-device backup creation: PASS.
- Backup output/share behavior: PASS.
- P65-produced backup restored through the existing pre-P66 restore path: PASS.
- Post-restore game/data behavior: PASS.
- User explicitly reported all scoped P65 behavior normal.
- P65 is promoted and becomes the rollback baseline for P66.

### P65 `ZONBackupService.h` compiler failure — CLOSED
- The blocking failure was target header resolvability, not a requirement to export private headers.
- Target header search path now includes `$(SRCROOT)/testmod/ZONServices` for both configurations.
- CI subsequently built and verified both A_customer and B_debug successfully.

### P64a runtime-directory model — CLOSED / DEVICE PASSED / SUPERSEDED
- Runtime source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- P64a distinguished game/user payload from runtime directory skeletons and volatile cache/temp residue.
- User reported P64a fully normal on device.
- Superseded as promoted baseline by P65.

### P64 strict-empty-directory verification — CLOSED BY P64a
- P64 failed because runtime directory removal/existence was treated as fatal.
- Payload-aware verification replaced the old strict-empty model.

### P63 six-button service boundary — CLOSED / DEVICE PASSED
- Runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- User explicitly reported all six scoped buttons normal on device.

### Version naming drift — CORRECTED IN PROJECT RECORDS
- New stages increment numeric phase.
- Same-stage fixes use `a/b/c/d` suffixes.
- Historical commits/artifacts are preserved.

## Tracking rule
- CI success alone does not equal promotion.
- A phase is promoted only after its scoped real-device behavior is explicitly confirmed.
- Every stage transition updates `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
- Every successful CI delivery includes the dylib and a concrete real-device validation checklist.
