# KNOWN_ISSUES

## Current state
- Promoted/device baseline: canonical `v1_p63` / runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- Current candidate: `v1_p64a` / actual build SHA `010f383da7f1429c4db93bfda559431e3c4080f9`.
- P64a CI Run `35524126925`: success.
- P64a status: **CI passed / device pending**.
- Architectures: `arm64 + arm64e`.

## Open risks

### P64a runtime-directory model still requires device proof
- P64 failed on device because `Library/Caches` could not be removed while the app was alive.
- P64a now distinguishes remaining business payload from runtime container-directory skeletons.
- Empty directories may remain.
- `Library/Caches` and `tmp` are treated as volatile runtime locations; runtime-created residue no longer fails reset by itself.
- Device validation must prove that this fixes the observed failure without leaving real game data behind.

### Runtime-created cache residue is intentionally tolerated
- P64a still attempts to clear volatile locations.
- If the running process/system recreates cache files immediately, those files are treated as new runtime residue rather than old user/game payload.
- Non-volatile files remain strict and still fail verification.

### Authorization/session behavior after full app-default reset remains observational
- The game-data reset engine does not call Keychain APIs or `ZONAuthorizationResetService`.
- It does reset the complete app `NSUserDefaults` domain.
- Device behavior after relaunch must therefore be observed rather than assumed.

### Failure path remains hard to force naturally
- Non-volatile deletion/verification failure should show an error and not exit.
- CI locks the control flow, but normal device testing may not naturally produce such a failure.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download extraction is planned for P67.
- Cloud save extraction is planned for P68.

### `daochucd` still mixes backup engine and UI
- Backup extraction is planned for P65.

### `YYYPicker` still mixes picker UI and restore engine
- Restore extraction is planned for P66.

## Closed / corrected

### P64 compile/PBX uncertainty — CLOSED / CI PASSED
- Canonical stage P64 was historically mislabeled `v1_p63b`.
- CI Run `35522283236`: success.
- A_customer/B_debug arm64+arm64e builds passed.
- Device promotion failed for runtime-directory semantics, not compilation.

### P64 strict-empty-directory verification — FIXED IN P64a / DEVICE VERIFICATION PENDING
- The old `children.count == 0` style success criterion was removed.
- Payload-aware recursive verification replaced it.
- Empty runtime directory skeletons are allowed.
- `Library/Caches` no longer has to be removed as a directory for reset to succeed.

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
- P64a requires scoped real-device validation before becoming the promoted baseline.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
