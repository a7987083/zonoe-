# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Current promoted/device baseline — P65
- VERSION: `v1_p65`.
- Branch: `work/p65-backup-engine-refactor`.
- Runtime/build source: `60db9885c1c69ff7e658bd99949274884d898b32`.
- CI Run `35562076044`: success.
- A_customer artifact `10622392644`, dylib SHA256 `83ab3e382d27e8c168a7428453e6b6da0f2acf0f5921877cb304e03485bde51e`.
- B_debug artifact `10622696370`, dylib SHA256 `849760004323c613d63c58c1b516141a732ece72603f2e19927327bebcaf8839`.
- Architectures: `arm64 + arm64e`.
- Real-device validation: PASS, explicitly reported by user.
- Startup/menu and six-button regression: PASS.
- P65 backup creation/output: PASS.
- P65-produced backup restored through existing pre-P66 restore flow: PASS.
- Post-restore behavior/data: PASS.
- **P65 is the rollback/device baseline for P66.**

## P65 implementation notes
- Backup execution is behind the `ZONBackupService` boundary.
- `ZONBackupService.h/.m` and `ZONBackupPolicy.h/.m` are registered in the active target.
- Target-private headers are resolved through `$(SRCROOT)/testmod/ZONServices` in target header search paths.
- Do not move these private headers into an exported Headers build phase just to satisfy compilation.
- The previous compiler failure `'ZONBackupService.h' file not found` is closed.
- Restore behavior remained unchanged during P65 and was proven compatible on device.

## Previous baseline — P64a
- VERSION: `v1_p64a`.
- Runtime source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- Device validation passed.
- Superseded by promoted P65, but retained as historical fallback.

## Current work target — P66 Restore Engine Extraction
### Objective
Extract restore execution from `YYYPicker` behind a clean service/API boundary while preserving the now device-proven P65 backup format and observable restore behavior.

### Guardrails
- Start from promoted P65 behavior, not from an older branch.
- Lock current restore call chain/data-flow before moving code.
- Preserve archive layout/path interpretation accepted by the current restore path.
- Keep picker/UI/presentation responsibilities outside the pure restore engine where practical.
- Centralize restore filesystem/error handling without silently changing compatibility behavior.
- Require A_customer and B_debug `arm64 + arm64e` builds.
- Deliver dylib after successful CI.
- Explicitly list real-device verification items with every delivered dylib.
- Real-device restore of a P65-produced backup is required before P66 promotion.

## Follow-on order
- P67: remote-download engine extraction.
- P68: cloud-save engine extraction.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
- Every successful build handoff includes the compiled dylib and concrete real-device validation scope.
