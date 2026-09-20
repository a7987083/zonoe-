# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Version naming rule
- New functional stage increments the number: P63, P64, P65...
- Same-stage fix uses suffix letters: P64a, P64b, P64c...
- Historical `v1_p63a`/`v1_p63b` strings are retained in commit/artifact history only; canonical mapping is P63/P64.

## Promoted rollback/device baseline — P63
- Canonical version: `v1_p63`.
- Historical built VERSION string: `v1_p63a`.
- Runtime source: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Six-button real-device validation: passed.

## P64 — Clear Game Data Dedicated Service — DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; canonical stage is P64.
- Runtime source: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Device failure: attempting to remove `Library/Caches` while the app remained alive produced a fatal reset error.
- Root cause: P64 treated runtime container-directory existence/removal failure as equivalent to remaining game data.
- P64 is not promoted.

## Current candidate — P64a
- VERSION: `v1_p64a`.
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Status: CI passed / device pending.
- A_customer artifact `10608274021`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug artifact `10608289075`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.

## P64a cleanup model
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONGameDataResetService`

Rules:
- `Documents`: strict payload cleanup.
- `Library`: recursive payload cleanup; empty directory skeletons may remain.
- `Library/Caches`: volatile runtime location; attempt cleanup but do not fail merely because the runtime recreates/holds cache files or the directory itself.
- `tmp`: volatile runtime location with the same best-effort runtime-residue rule.
- Non-volatile files that survive cleanup remain fatal and prevent exit.
- `NSUserDefaults` app domain is still reset.
- Keychain/auth reset service is not called by the game-data reset engine.
- No fixed 5-second cleanup/exit timer.
- Stage UI remains visible; success exits immediately after cleanup completes.

## Device gate for P64a
Test:
1. clear-game-data confirmation works;
2. stage messages appear;
3. prior `Library/Caches` failure no longer appears;
4. app exits after successful cleanup;
5. relaunch resembles fresh local game state;
6. no old game save/config data remains;
7. other five button routes still open normally.

Do not promote P64a or start P65 until the user explicitly reports the scoped device gate passed.

## Follow-on stages
- P65: backup engine extraction.
- P66: restore engine extraction.
- P67: remote-download engine extraction.
- P68: cloud-save engine extraction.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
