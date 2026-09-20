# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p63a` / `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- P63A CI Run `35483209464`: success.
- P63A real-device validation: **passed, explicitly reported by user for all six scoped buttons**.
- Architectures: `arm64 + arm64e`.
- Canonical plan: `ROADMAP.md`.
- Current next stage: **P63B Clear Game Data Dedicated Service**.

## Open risks

### Clear-game-data implementation still needs dedicated extraction/hardening
- The destructive implementation is no longer owned by `ZONFeatureDispatcher`, but it still lives inside `ZONSixButtonActionService`.
- Promoted P63A intentionally preserves the current 5-second timing, tmp behavior, Documents/Library/default-domain deletion, redundant delete/enumerate flow and multiple `error:nil` operations.
- P63B must first isolate this implementation into a dedicated service and lock P63A behavior as the comparison contract.
- Redundant delete/enumerate work may be removed only with behavior-equivalence evidence.
- Filesystem failures should become observable through an explicit result/error model without silently changing the promoted user-facing flow.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download and VIP cloud save enter through `ZONSixButtonActionService`, but their underlying engines remain in `PubgLoad`.
- The class still mixes network access, URL handling, download lifecycle, ZIP handling, filesystem staging, authorization checks, progress UI and restore-related side effects.
- Remote-download engine extraction is deferred to P63E; cloud-save engine extraction is deferred to P63F.

### `daochucd` still mixes backup engine and UI
- P63A added a service boundary only; the backup engine remains inside `daochucd`.
- Existing device-tested backup behavior must remain the comparison baseline.
- Backup engine extraction is deferred to P63C.

### `YYYPicker` still mixes document-picker UI and restore engine
- P63A added a service boundary only; the restore engine remains inside `YYYPicker`.
- Restore engine extraction is deferred to P63D.

### Legacy `getKeychain` remains active
- `SFHFKeychainUtils` is no longer active, but `getKeychain` still stores historical authorization/device values such as `SJUSERID`, `ShiSanGeDZKM`, `DZUDID`, `ShiSanGeIDFV` and `rjyyz`.
- Do not replace or migrate these values as part of P63B; storage migration is a separate concern.

### Global startup/authorization side effects remain order-sensitive
- Startup/bootstrap, authorization, UDID acquisition, module loading and floating-entry lifecycle remain protected behavior surfaces.
- The six-button program must not opportunistically change their timing, retries, callbacks or persistence semantics.

### Historical CI/scripts remain intentionally tracked
- Historical phase scripts/tests/workflows provide reproducibility and audit evidence.
- Their age alone is not evidence that they can be removed.

## Closed / corrected

### P63A six-button real-device regression — CLOSED / DEVICE PASSED
- Runtime source `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- A_customer and B_debug build/link/output verification passed for `arm64 + arm64e`.
- User explicitly reported all six scoped buttons normal on device.
- P63A is the promoted baseline for P63B.

### Dispatcher direct six-button legacy dependency — CLOSED BY P63A
- Six scoped routes call `ZONSixButtonActionService`.
- Dispatcher no longer directly imports/calls `PubgLoad`, `daochucd`, `YYYPicker`, `WX_NongShiFu123` or `SVProgressHUD` for those six actions.
- CI and real-device regression both passed.

### Clear-authorization button crossing legacy deletekm entry — CLOSED BY P63A
- Button routing reaches `ZONAuthorizationResetService` through the P63A service boundary.
- P62 reset clear-set contract was retained and device regression passed.

### P62 Authorization Reset Service — CLOSED / DEVICE PASSED / SUPERSEDED
- Source `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- User explicitly reported the produced dylib tests fully normal.
- Superseded as current promoted runtime baseline by P63A.

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
