# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p62` / `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- Current candidate: `v1_p63a` / `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- P63A CI Run `35483209464`: success.
- P63A real-device validation: **pending**.
- Architectures: `arm64 + arm64e`.
- Canonical plan: `ROADMAP.md`.

## Open risks

### P63A still requires six-button real-device regression
- Static behavior/service/PBX contracts and A_customer/B_debug builds passed.
- P63A is not promoted until the user explicitly confirms all six scoped actions behave normally on device.
- Any visible behavior difference from P62 is considered a P63A regression.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download and VIP cloud save now enter through `ZONSixButtonActionService`, but their underlying engines remain in `PubgLoad`.
- The class still mixes network access, URL handling, download delegate lifecycle, ZIP handling, filesystem staging, authorization checks, progress UI and restore-related side effects.
- Remote-download engine extraction is deferred to P63E; cloud-save engine extraction is deferred to P63F.

### `daochucd` still mixes backup engine and UI
- P63A only adds a service boundary; the existing backup engine remains inside `daochucd`.
- Backup combines filename prompt, filesystem scan/copy, >50 MiB decision UI, staging cleanup, ZIP creation and share UI.
- Existing device-tested backup behavior must remain the comparison baseline.
- Backup engine extraction is deferred to P63C.

### `YYYPicker` still mixes document-picker UI and restore engine
- P63A only adds a service boundary; the restore engine remains inside `YYYPicker`.
- Restore combines file picking, staging cleanup, ZIP extraction, nested Documents/Library discovery, recursive copy, skip rules, PreferenceManager reload and UI feedback.
- Restore engine extraction is deferred to P63D.

### Clear-game-data implementation needs dedicated cleanup/hardening
- The destructive implementation is no longer owned by `ZONFeatureDispatcher`; it is now behind `ZONSixButtonActionService`.
- P63A intentionally preserves the existing 5-second timing, tmp behavior, Documents/Library/default-domain deletion, redundant delete/enumerate flow and `error:nil` operations.
- Dedicated service separation, error propagation and removal of redundant operations belong to P63B and must be validated against the promoted P63A behavior if P63A passes device testing.

### Legacy `getKeychain` remains active
- `SFHFKeychainUtils` is no longer active, but `getKeychain` still stores historical authorization/device values such as `SJUSERID`, `ShiSanGeDZKM`, `DZUDID`, `ShiSanGeIDFV` and `rjyyz`.
- Do not replace or migrate these values as part of the six-button program; storage migration is a separate concern.

### Global startup/authorization side effects remain order-sensitive
- Startup/bootstrap, authorization, UDID acquisition, module loading and floating-entry lifecycle remain protected behavior surfaces.
- The six-button program must not opportunistically change their timing, retries, callbacks or persistence semantics.

### Historical CI/scripts remain intentionally tracked
- Historical phase scripts/tests/workflows provide reproducibility and audit evidence.
- Their age alone is not evidence that they can be removed.

## Closed / corrected

### Dispatcher direct six-button legacy dependency — CLOSED BY P63A CANDIDATE / DEVICE GATE PENDING
- Six scoped routes now call `ZONSixButtonActionService`.
- Dispatcher no longer directly imports/calls `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for those six actions.
- CI contract verifies the boundary. Runtime closure depends on the pending device gate.

### Clear-authorization button crossing legacy deletekm entry — CLOSED BY P63A CANDIDATE / DEVICE GATE PENDING
- Button routing now reaches `ZONAuthorizationResetService` through the P63A service boundary.
- The P62 reset clear-set contract is retained and checked in CI.
- Runtime closure depends on the pending device gate.

### P62 Authorization Reset Service — CLOSED / DEVICE PASSED
- Source `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- User explicitly reported the produced dylib tests fully normal.

### P62 SFHFKeychainUtils active dependency — CLOSED
- Active UDID storage was migrated to `ZONKeychain`.
- Legacy `SFHFKeychainUtils.h/.m` were removed from the active project surface.

### P62 reset-service PBX nondeterminism — CLOSED
- Migration script verifies/inserts exact PBXBuildFile, PBXFileReference and PBXSourcesBuildPhase entries.

### P62 CI migrated-revision race — CLOSED
- Build jobs are pinned to the exact migrated SHA and verify source membership before xcodebuild.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership is authoritative.

## Tracking rule
- Move an open risk to fully closed only after the required CI and, where applicable, real-device gate passes.
- Source edits or CI success alone do not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` so the five long-project records remain consistent.
