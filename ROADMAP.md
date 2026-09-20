# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Version naming rule
- New stage: `P63 → P64 → P65 → ...`
- Fix to the same stage: `P64a → P64b → P64c ...`
- Historical strings `v1_p63a` and `v1_p63b` were naming mistakes introduced during this work; commit/artifact history is preserved, but the canonical stage mapping is corrected below.

## Current promoted runtime baseline — P63 / DEVICE PASSED
- Canonical version: `v1_p63`.
- Historical built VERSION string: `v1_p63a`.
- Runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Six-button real-device regression: PASS, explicitly reported by user.
- P63 remains the rollback/device baseline until P64a passes device validation.

## P63 — Six Button Service Boundary — COMPLETED / DEVICE PASSED
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
- Device test exposed a real design defect: `Library/Caches` could not be removed while the app was alive, and P64 incorrectly treated the existence/removal failure of runtime container directories as a fatal reset failure.
- P64 is not promoted.

## P64a — Runtime Directory Cleanup Fix — CI PASSED / DEVICE PENDING
### Candidate
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- VERSION: `v1_p64a`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: **success**.
- A_customer artifact `10608274021`, digest `sha256:5cc2772e8fb2794a1301ca79526ea9a375ae5686c92e9040609eb9009ab20302`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug artifact `10608289075`, digest `sha256:c6296cb2d5ee1114501e9f35eda7e5c9cef76e9bc2657d126accb79e9bdedff8`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.

### P64a behavior
- Preserve standard/running container directory skeletons when the directory itself cannot be removed.
- Empty runtime directories are not considered game/user payload.
- `Library/Caches` and `tmp` are treated as volatile runtime locations: cleanup is attempted, but runtime-created cache residue does not by itself fail the reset.
- Non-volatile business files still fail verification if they remain.
- `Documents` remains strict for payload deletion.
- No fixed cleanup delay; successful completion exits immediately.
- Stage UI remains unchanged.

### Verification completed
- P64a runtime-directory contract: PASS.
- Existing six-button routing/PBX membership: PASS.
- Existing authorization reset contract: PASS.
- A_customer xcodebuild/link/output: PASS.
- B_debug xcodebuild/link/output: PASS.
- `arm64 + arm64e`: PASS.

### Promotion gate remaining
Real-device test must confirm:
- the prior `Library/Caches` deletion failure no longer blocks cleanup;
- local game data is reset;
- stage display remains visible;
- app exits immediately after successful cleanup;
- relaunch behaves as fresh local state;
- other five button routes remain normal.

## Follow-on stages
- P65 — Backup engine extraction from `daochucd`.
- P66 — Restore engine extraction from `YYYPicker`.
- P67 — Remote Download engine extraction from `PubgLoad`.
- P68 — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; correct naming in project records without rewriting history.
3. New functional stages increment the numeric version; suffix letters are fixes only.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.

# Next Task
Real-device validate `v1_p64a`. Do not promote P64a or begin P65 until the user explicitly reports the scoped clear-game-data regression passed.
