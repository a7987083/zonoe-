# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Version naming rule
- New stage: `P63 → P64 → P65 → ...`
- Fix to the same stage: `P64a → P64b → P64c ...`
- Historical strings `v1_p63a` and `v1_p63b` were naming mistakes introduced during this work; commit/artifact history is preserved, but the canonical stage mapping is corrected below.

## Current promoted runtime baseline — P64a / DEVICE PASSED
- Version: `v1_p64a`.
- Runtime/build source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- A_customer artifact `10608274021`, digest `sha256:5cc2772e8fb2794a1301ca79526ea9a375ae5686c92e9040609eb9009ab20302`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug artifact `10608289075`, digest `sha256:c6296cb2d5ee1114501e9f35eda7e5c9cef76e9bc2657d126accb79e9bdedff8`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- Real-device validation: PASS, explicitly reported by user.
- P64a is the promoted rollback/device baseline for P65.

## P63 — Six Button Service Boundary — COMPLETED / DEVICE PASSED
- Historical built VERSION string: `v1_p63a`; canonical stage is P63.
- Runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- Added `ZONSixButtonActionService` as the six-action boundary.
- Dispatcher no longer directly owns the six legacy action implementations.
- Clear authorization reaches `ZONAuthorizationResetService` behind the boundary.
- A_customer + B_debug `arm64 + arm64e`: PASS.
- Device regression: PASS.

## P64 — Clear Game Data Dedicated Service — CI PASSED / DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; canonical stage name is P64.
- Actual build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Introduced `ZONGameDataResetService`, background cleanup, stage display, no fixed 5-second wait, completion-controlled exit and explicit errors.
- Device test exposed a real design defect: `Library/Caches` could not be removed while the app was alive, and P64 incorrectly treated runtime container-directory removal/existence as fatal.
- P64 was not promoted and is superseded by P64a.

## P64a — Runtime Directory Cleanup Fix — COMPLETED / DEVICE PASSED
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- VERSION: `v1_p64a`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Standard/running container directory skeletons may remain when empty.
- `Library/Caches` and `tmp` are treated as volatile runtime locations; cleanup is attempted, but runtime-created cache residue does not itself fail the reset.
- Non-volatile business payload remains strict.
- `Documents` payload deletion remains strict.
- No fixed cleanup delay; successful completion exits immediately.
- Stage UI remains unchanged.
- User explicitly reported the P64a device regression fully normal.
- P64a is promoted and becomes the baseline for P65.

## P65 — Backup Engine Refactor — NEXT
### Goal
Refactor the current backup implementation out of `daochucd` into a clean API/service boundary while preserving backup compatibility and removing duplicate filesystem logic.

### Intended architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONBackupService → filesystem/archive engine`

### P65 scope
- Audit the complete current `daochucd` backup call chain before changing behavior.
- Preserve current user-facing backup entry, naming, large-file prompt semantics, ZIP compatibility and share behavior unless an existing defect is proven.
- Add a unified `ZONBackupService` API so external callers no longer need to know backup implementation details.
- Consolidate duplicate Documents/Library scanning and copy loops.
- Centralize include/exclude policy for cache/temp/runtime-only paths.
- Introduce a single backup manifest/scan result so size checks and copy phases do not repeatedly stat/traverse the same tree.
- Centralize staging-directory lifecycle: prepare → populate → archive → cleanup.
- Replace silent filesystem failures with observable result/error propagation.
- Keep UIKit/share presentation outside the pure backup engine/service core where practical.
- Preserve compatibility with the current restore path; a produced P65 backup must still be restorable by the existing restore implementation before P66 changes it.

### P65 verification gates
- Existing backup button route preserved.
- Existing six-button boundary preserved.
- Backup service/API contract test added.
- No duplicate Documents/Library copy loops remain in the active backup engine.
- Backup engine core has no direct presentation responsibility.
- ZIP/output compatibility checked against existing restore logic.
- A_customer `arm64 + arm64e`: required.
- B_debug `arm64 + arm64e`: required.
- Real-device backup creation: required.
- Real-device restore of the P65-created backup through the existing restore path: required before promotion.

## Follow-on stages
- P66 — Restore engine extraction from `YYYPicker`.
- P67 — Remote Download engine extraction from `PubgLoad`.
- P68 — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; correct naming in project records without rewriting history.
3. New functional stages increment the numeric version; suffix letters are fixes only.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.
6. For behavior-sensitive refactors, lock the current device-passed behavior before cleanup and prove compatibility before deleting legacy code.

# Next Task
Create the P65 work branch from promoted P64a, deeply audit `daochucd` backup behavior and dependencies, then implement the first clean `ZONBackupService` boundary without changing restore behavior yet.
