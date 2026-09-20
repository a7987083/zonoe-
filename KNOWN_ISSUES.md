# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p63a` / `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- Current candidate: `v1_p63b` / actual build SHA `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- P63B CI Run `35522283236`: success.
- P63B status: **CI passed / device pending**.
- Architectures: `arm64 + arm64e`.

## Open risks

### Active-container cleanup must be proven on device
- P63B clears `Documents`, `Library`, and `tmp` contents while the process is still alive, then exits after verification.
- Frameworks/game code may recreate files during cleanup; the service performs a final verification sweep.
- If critical files continue to reappear or deletion fails, the service returns failure and does not force exit.
- Device validation must confirm fresh-local-state behavior after relaunch.

### Authorization/session behavior after full app-default reset is intentionally not assumed
- P63B does not explicitly call Keychain APIs, `getKeychain`, `ZONKeychain`, or `ZONAuthorizationResetService`.
- However, P63B removes the complete app `NSUserDefaults` persistent domain as part of reinstall-like local reset.
- If authorization/session state is mirrored in app defaults, relaunch behavior may change even though Keychain is not explicitly cleared.
- Device test must record what actually happens rather than treating “authorization remains intact” as a guaranteed contract.

### P63B intentionally changes clear-game-data timing/UX
- P63A used fixed 5-second timing.
- User explicitly approved removing those waits.
- P63B shows real stages and exits when cleanup actually completes.
- This is a scoped intentional behavior change, not a regression.

### Failure path is contract-verified but difficult to force in normal device smoke testing
- Critical cleanup/verification failure should show an error and not exit.
- CI locks this control flow structurally, but a normal device run may not naturally produce a filesystem failure.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download and VIP cloud save still use existing `PubgLoad` engines.
- Remote extraction is deferred to P63E; cloud extraction to P63F.

### `daochucd` still mixes backup engine and UI
- Backup extraction is deferred to P63C.

### `YYYPicker` still mixes picker UI and restore engine
- Restore extraction is deferred to P63D.

### Legacy `getKeychain` remains active
- Historical authorization/device values remain outside P63B storage-migration scope.

## Closed / corrected

### P63B compile/PBX uncertainty — CLOSED / CI PASSED
- Deterministic P63B migration passed.
- P63B behavior/architecture contract passed.
- A_customer and B_debug Xcode builds passed for `arm64 + arm64e`.
- Dylib output verification and artifact upload passed.

### P63A six-button real-device regression — CLOSED / DEVICE PASSED
- Runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- User explicitly reported all six scoped buttons normal on device.

### Dispatcher direct six-button legacy dependency — CLOSED BY P63A
- Six scoped routes use `ZONSixButtonActionService`.

### Clear-authorization button crossing legacy deletekm entry — CLOSED BY P63A
- Button routing reaches `ZONAuthorizationResetService` through the service boundary.

### P62 Authorization Reset Service — CLOSED / DEVICE PASSED / SUPERSEDED
- CI Run `35480732207`: success.
- Superseded by P63A as promoted runtime baseline.

## Tracking rule
- CI success alone does not equal promotion.
- P63B requires scoped real-device validation before becoming the promoted baseline.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
