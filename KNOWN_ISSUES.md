# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p63a` / `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- P63A CI Run `35483209464`: success.
- P63A six-button real-device validation: passed.
- Current work branch: `work/p63b-clear-game-data-service`.
- Current candidate version: `v1_p63b`.
- P63B status: **source ready / CI pending**.
- Architectures: `arm64 + arm64e`.

## Open risks

### P63B reset engine must prove active-container cleanup is stable while the process is alive
- P63B intentionally clears `Documents`, `Library`, and `tmp` contents while the app is still running, then exits.
- Frameworks or the game may recreate files during cleanup; the service therefore performs a final verification sweep.
- If critical files continue to reappear or a delete fails, P63B must return failure and must not force exit.
- Device validation must specifically check fresh-local-state behavior after relaunch.

### P63B intentionally changes clear-game-data timing/UX
- The promoted P63A clear path used fixed 5-second timers.
- User explicitly approved removing those timers.
- P63B instead shows real stages and exits when cleanup actually completes.
- This is an intentional behavior change, not a regression; the new P63B contract is authoritative for this button.

### Main app data reset is not identical to deleting every persistent identity source
- P63B scope is the primary app data container plus the app `NSUserDefaults` domain.
- Keychain/authorization storage is intentionally preserved and belongs to the separate “清除授权记录” action.
- App Group containers and iCloud/CloudKit remote data are intentionally not deleted.
- Device testing should therefore expect fresh local game data while authorization may remain valid.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download and VIP cloud save still use the existing `PubgLoad` engines behind `ZONSixButtonActionService`.
- Remote-download extraction is deferred to P63E; cloud-save extraction is deferred to P63F.

### `daochucd` still mixes backup engine and UI
- Backup extraction is deferred to P63C.

### `YYYPicker` still mixes document-picker UI and restore engine
- Restore extraction is deferred to P63D.

### Legacy `getKeychain` remains active
- `getKeychain` still owns historical authorization/device values.
- Do not migrate these values during P63B.

### Startup/authorization side effects remain order-sensitive
- Startup/bootstrap, authorization, UDID acquisition, module loading and floating-entry lifecycle remain protected surfaces.
- P63B must not change them.

## Closed / corrected

### P63A six-button real-device regression — CLOSED / DEVICE PASSED
- Runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- User explicitly reported all six scoped buttons normal on device.

### Dispatcher direct six-button legacy dependency — CLOSED BY P63A
- Six scoped routes call `ZONSixButtonActionService`.
- Dispatcher remains decoupled from the legacy action implementations.

### Clear-authorization button crossing legacy deletekm entry — CLOSED BY P63A
- Button routing reaches `ZONAuthorizationResetService` through the service boundary.

### P62 Authorization Reset Service — CLOSED / DEVICE PASSED / SUPERSEDED
- Source `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Superseded by P63A as current promoted runtime baseline.

### P62 SFHFKeychainUtils active dependency — CLOSED
- Active UDID storage was migrated to `ZONKeychain`.

### P62/P63A PBX migration nondeterminism — CORRECTED
- Runtime-added Objective-C sources use deterministic PBXBuildFile/PBXFileReference/PBXSourcesBuildPhase migration scripts.

## Tracking rule
- Source completion or CI success alone does not equal promotion.
- P63B requires scoped real-device validation after both A/B builds pass.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
