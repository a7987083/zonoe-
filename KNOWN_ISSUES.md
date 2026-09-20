# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p64a` / runtime source `010f383da7f1429c4db93bfda559431e3c4080f9`.
- P64a CI Run `35524126925`: success.
- P64a real-device validation: passed, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- Next development stage: P65 backup engine refactor.

## Open risks

### `daochucd` still mixes UI, filesystem traversal, archive work and sharing
- The current backup entry is still `daochucd::backupasd` behind `ZONSixButtonActionService`.
- UI presentation, path enumeration, size checks, large-file decisions, staging-directory work, copy logic, ZIP creation and share presentation are coupled.
- P65 must separate the backup engine from presentation without breaking existing behavior.

### Backup format compatibility must be preserved during P65
- P65 changes the implementation boundary before P66 changes restore.
- A P65-produced backup must remain restorable by the existing restore path.
- Include/exclude rules, relative paths, archive layout and naming behavior must be audited before cleanup.

### Duplicate traversal/copy logic may hide behavior differences
- Documents and Library paths may currently be handled by similar but not perfectly identical code.
- Do not blindly merge loops until the audit records all conditionals, exclusions, size handling and output mapping.

### Backup cache/temp exclusion policy needs explicit ownership
- Cache/temp/runtime-only paths should not be scattered through ad-hoc `if` conditions.
- P65 should centralize them in a backup policy boundary while preserving any compatibility-critical legacy inclusions.

### Staging/workspace lifecycle is a failure-sensitive area
- Temporary backup workspace creation, reuse, deletion and archive cleanup must become deterministic.
- A partial failure must not leave stale staging data that contaminates the next backup.

### Silent filesystem failures remain a backup risk
- Existing backup code may still use `error:nil` or continue after individual copy failures.
- P65 should surface actionable errors while preserving current UX semantics where possible.

### `YYYPicker` still mixes picker UI and restore engine
- Restore extraction is planned for P66.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download extraction is planned for P67.
- Cloud save extraction is planned for P68.

## Closed / corrected

### P64a runtime-directory model — CLOSED / DEVICE PASSED
- P64a distinguishes game/user payload from runtime directory skeletons and volatile cache/temp residue.
- `Library/Caches` no longer needs to disappear as a directory for reset to succeed.
- CI Run `35524126925`: success.
- User explicitly reported P64a fully normal on device.
- P64a is now the promoted baseline.

### P64 strict-empty-directory verification — CLOSED BY P64a
- P64 failed because runtime directory removal/existence was treated as fatal.
- Payload-aware verification replaced the old strict-empty model.

### P63 six-button service boundary — CLOSED / DEVICE PASSED
- Historical built VERSION string `v1_p63a`; canonical stage is P63.
- Runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- User explicitly reported all six scoped buttons normal on device.

### Version naming drift — CORRECTED IN PROJECT RECORDS
- New stages increment numeric phase.
- Same-stage fixes use `a/b/c/d` suffixes.
- Historical commits/artifacts are preserved; only canonical project records are corrected.

## Tracking rule
- CI success alone does not equal promotion.
- P65 must preserve current backup/restore compatibility and pass scoped real-device backup + restore validation before promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
