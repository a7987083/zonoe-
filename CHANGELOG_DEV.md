# CHANGELOG_DEV

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — CI PASSED / DEVICE PENDING
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Fixed P64 device failure where `Library/Caches` could not be removed while the process was alive.
- Replaced the invalid success criterion “Library/tmp must contain zero child directories” with payload-aware verification.
- Standard/runtime directory skeletons may remain when empty.
- `Library/Caches` and `tmp` are volatile runtime locations: cleanup is attempted, but runtime-created cache residue is not treated as user/game payload.
- Non-volatile business files still produce a real failure if they remain after cleanup/verification.
- `Documents` payload deletion remains strict.
- Existing stage display, background execution, no-5-second behavior, completion-controlled exit and error reporting are preserved.
- Added `Tests/p64a_game_data_runtime_directory_contract.py`.
- Added dedicated P64a A/B CI workflow.
- A_customer `arm64 + arm64e`: PASS. Artifact `10608274021`, digest `sha256:5cc2772e8fb2794a1301ca79526ea9a375ae5686c92e9040609eb9009ab20302`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug `arm64 + arm64e`: PASS. Artifact `10608289075`, digest `sha256:c6296cb2d5ee1114501e9f35eda7e5c9cef76e9bc2657d126accb79e9bdedff8`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- Device validation remains required before promotion.

## 2026-09-21 — P64 Clear Game Data Dedicated Service — CI PASSED / DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; this was a naming error. Canonical stage is P64.
- Actual build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Added `ZONGameDataResetService` as a pure Foundation reset engine.
- Removed both historical 5-second clear-game-data timers.
- Added background cleanup, real stage display, explicit NSError propagation, verification, and success-controlled exit.
- Device test found that `Library/Caches` may remain/in-use while the app is alive; P64 incorrectly treated that runtime directory removal failure as fatal.
- P64 was not promoted and is superseded by P64a candidate.

## 2026-09-20 — P63 Six Button Service Boundary — DEVICE PASSED
- Historical built VERSION string: `v1_p63a`; this was a naming error. Canonical stage is P63.
- Runtime source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Added `ZONSixButtonActionService` and routed all six scoped actions through it.
- A_customer and B_debug `arm64 + arm64e`: PASS.
- User explicitly reported all six scoped buttons normal on device.
- P63 remains the current promoted rollback/device baseline.

## 2026-09-20 — P62 Authorization Reset Service — DEVICE PASSED / SUPERSEDED
- Source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Authorization reset extracted into `ZONAuthorizationResetService`.
- Device validation passed; superseded by P63.

## Version naming rule correction
- New stage increments the number: `P63 → P64 → P65`.
- Same-stage fixes use suffixes: `P64a → P64b → P64c`.
- Existing commits/artifacts are not rewritten; canonical project records correct the mistaken historical P63a/P63b labels.

## Earlier architecture cleanup
- P60 UDID acquisition progress/manual retry: device passed.
- P58 download lifecycle hardening: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P51/P51-B feature routing and backup refactor: device passed.
- P50 architecture freeze: completed.
- P49 active-target/dependency audit: device passed.
- P48.1 StoreKit residual cleanup: device passed.
