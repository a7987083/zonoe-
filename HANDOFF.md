# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Version naming rule
- New functional stage increments the number: P63, P64, P65...
- Same-stage fix uses suffix letters: P64a, P64b, P64c...
- Historical `v1_p63a`/`v1_p63b` strings are retained in commit/artifact history only; canonical mapping is P63/P64.

## Current promoted/device baseline — P64a
- VERSION: `v1_p64a`.
- Runtime/build source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- A_customer artifact `10608274021`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug artifact `10608289075`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- Real-device validation: PASS, explicitly reported by user.
- P64a is the rollback/device baseline for P65.

## P64 history
### P64 — Clear Game Data Dedicated Service — DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; canonical stage is P64.
- Runtime source: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Device failure: `Library/Caches` removal while the app remained alive was incorrectly treated as fatal.

### P64a — Runtime Directory Cleanup Fix — DEVICE PASSED
- Standard/running directory skeletons may remain when empty.
- `Library/Caches` and `tmp` are volatile runtime locations.
- Non-volatile payload remains strict.
- No fixed 5-second cleanup/exit timer.
- Stage UI remains visible; success exits immediately after cleanup completes.
- User explicitly reported all scoped behavior normal on device.

## Current work target — P65 Backup Engine Refactor
### Objective
Extract the backup execution path from `daochucd` into a clean service/API boundary and remove duplicate filesystem logic without breaking current backup or restore compatibility.

### Intended architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONBackupService → filesystem/archive engine`

### P65 design rules
- Audit `daochucd` completely before deleting or moving logic.
- Lock current backup behavior first: naming, included paths, excluded paths, >50MB behavior, staging, archive path/format and sharing.
- Keep restore behavior unchanged during P65.
- A backup created by P65 must remain restorable through the existing pre-P66 restore path.
- Introduce a single backup API; callers should not need to know `daochucd` internals.
- Consolidate duplicated Documents/Library scans and copy loops.
- Prefer a single manifest/scan result so size checks and copy execution share the same filesystem snapshot.
- Centralize include/exclude rules in a backup policy boundary.
- Centralize staging workspace lifecycle.
- Replace silent `error:nil` failures in the active backup engine with observable errors/results.
- Keep presentation/share responsibilities outside the pure backup engine where practical.
- Preserve existing UI behavior unless a real defect is found and explicitly approved.

### Initial P65 file target
Prefer a controlled first split rather than many tiny classes:
- `testmod/ZONServices/ZONBackupService.h`
- `testmod/ZONServices/ZONBackupService.m`
- `testmod/ZONServices/ZONBackupPolicy.h`
- `testmod/ZONServices/ZONBackupPolicy.m`
Additional model files only if the audit proves they materially simplify the implementation.

### Required P65 verification
1. Current `daochucd` behavior/data-flow audit documented in code/tests.
2. Backup button route remains unchanged externally.
3. Backup API/service contract test passes.
4. Existing ZIP/output semantics remain compatible with current restore implementation.
5. No duplicate active Documents/Library copy loops remain.
6. A_customer `arm64 + arm64e` builds/links.
7. B_debug `arm64 + arm64e` builds/links.
8. Real-device backup creation works.
9. The produced backup restores successfully through the existing restore flow.

## Follow-on order
- P66: restore engine extraction.
- P67: remote-download engine extraction.
- P68: cloud-save engine extraction.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
