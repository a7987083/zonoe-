# P66 Restore Engine Audit

Baseline: P65 device-passed runtime `60db9885c1c69ff7e658bd99949274884d898b32`.
Branch: `work/p66-restore-engine-audit`.
Version: `v1_p66`.

## Scope
P66 extracts restore execution from `YYYPicker` into `ZONRestoreService` / `ZONRestorePolicy` while preserving the existing restore UX and compatibility entry `yidongwenjian` used by cloud/download flows.

## Confirmed legacy behavior that must remain compatible
- Picker entry remains `addBtnAction`.
- Accepted document type remains `public.data` and mode remains `UIDocumentPickerModeImport`.
- Restore staging root remains `/tmp/zonoe` for compatibility.
- Cloud/download path may still call `[[YYYPicker alloc] yidongwenjian]` after preparing `/tmp/zonoe`.
- Restore remains merge/overwrite semantics, not snapshot replacement.
- Legacy skip set remains `__MACOSX`, `.DS_Store`, `Preferences`.
- Successful restore reloads `MyCustomSettings` through `PreferenceManager`.
- Historical archives with nested/legacy Documents/Library discovery remain supported through a compatibility fallback.

## Audit findings and P66 actions

### P0 — archive path traversal / Zip Slip
Finding: the bundled SSZipArchive constructed output paths from archive entry names without proving the standardized output remained under the requested destination.

P66 action: add a standardized destination containment guard inside the shared unzip primitive before directory creation or file writes. Unsafe entries cause extraction failure. Because the guard is inside SSZipArchive, recursive/nested unzip calls are protected by the same containment check.

### P0 — restore engine mixed into YYYPicker
Finding: picker/UI, unzip lifecycle, filesystem discovery, copy/overwrite and cleanup were co-located.

P66 action: move filesystem/archive execution to `ZONRestoreService`; keep `YYYPicker` as UI/orchestration only.

### P0 — preflight before destructive copy
Finding: prior restore could begin copying before the overall backup structure had been fully resolved.

P66 action: resolve backup source roots and current application destination roots before applying copy operations. Prefer a common parent containing Documents/Library, with a legacy independent-discovery fallback for historical compatibility.

### P0/P1 — shared staging concurrency
Finding: local and cloud restore historically share `/tmp/zonoe`. P66 serializes restore execution inside `ZONRestoreService`, preventing simultaneous service-side apply operations.

Residual risk: legacy `PubgLoad` still prepares/deletes `/tmp/zonoe` outside the restore service before calling `yidongwenjian`. Full producer-side ownership belongs to the later PubgLoad/cloud extraction stage and must not be silently expanded into P66.

### P1 — Inbox ownership
Finding: prior local restore deleted the entire `<bundle>-Inbox` directory.

P66 action: remove only the selected archive, then remove the Inbox directory only if it is empty.

### P1 — error ownership
Finding: restore failures were mostly surfaced as generic UI strings.

P66 action: introduce `ZONRestoreErrorDomain` and typed error codes for invalid input, staging, extraction, root discovery, Documents/Library apply and cleanup failures. `YYYPicker` only presents the service result.

### P1 — backup root ambiguity
Finding: prior implementation independently searched the first recursive `Documents` and `Library`, so unrelated trees could theoretically be paired.

P66 action: prefer a common backup root containing direct Documents/Library children. Preserve the older independent recursive lookup only as a compatibility fallback.

### P2 — global `Preferences` skip rule
Finding: any item named `Preferences` is skipped recursively, not only `Library/Preferences`.

P66 decision: preserve for P66 compatibility. Move ownership into `ZONRestorePolicy`; do not narrow the rule without historical-backup evidence and device validation.

### P2 — merge restore vs snapshot restore
Finding: files absent from the backup are not removed from current Documents/Library. Therefore restore is a merge/overwrite operation rather than an exact snapshot rollback.

P66 decision: preserve semantics. Snapshot restore would be a behavior change and requires a separate design/device-validation stage.

### P2 — transactional rollback
Finding: a runtime filesystem failure after Documents succeeds but before Library completes can still leave a partially applied restore.

P66 action: preflight reduces avoidable partial-restore cases and the service now reports exact failure stage. Full rollback/snapshot transaction is intentionally not introduced in P66 because it changes disk usage and runtime semantics and requires separate compatibility testing.

## Required P66 verification
1. P66 migration + static contract PASS.
2. A_customer arm64 + arm64e build/link PASS.
3. B_debug arm64 + arm64e build/link PASS.
4. Real-device launch/menu regression PASS.
5. P65-created backup restores correctly through P66.
6. At least one historical/legacy backup restores correctly through P66.
7. Cloud/download prepared-staging path still restores through `yidongwenjian`.
8. Corrupt/non-ZIP archive fails without modifying destination data.
9. Crafted archive entry containing `../` is rejected by the unzip containment guard.

## Promotion rule
CI success alone does not promote P66. P65 remains the device rollback baseline until the scoped P66 real-device restore tests pass.
