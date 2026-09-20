# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p62` / `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- CI Run `35480732207`: success.
- Real-device validation: passed, explicitly reported by user.
- Architectures: `arm64 + arm64e`.
- Canonical plan: `ROADMAP.md`.
- Current active program: **P63A Six Button Service Boundary**.

## Open risks

### Six-button business layer is only partially decoupled
- `ZONFeatureRegistry` / `ZONFeatureDispatcher` already provide a stable routing boundary, but Dispatcher still directly references concrete legacy classes and destructive implementation details.
- P63A must add a service/adapter layer without changing behavior.
- The six scoped actions are remote download, VIP cloud save, backup save, restore save, clear game data and clear authorization records.

### `PubgLoad` remains a high-risk multi-responsibility class
- Remote download and VIP cloud-save both route into `PubgLoad`.
- The class mixes network access, URL handling, download delegate lifecycle, ZIP handling, filesystem staging, authorization checks, progress UI and restore-related side effects.
- P63A may wrap the current entry points but must not deep-rewrite this class.
- Remote-download engine extraction is deferred to P63E; cloud-save engine extraction is deferred to P63F.

### `daochucd` mixes backup engine and UI
- Backup currently combines filename prompt, filesystem scan/copy, >50 MiB decision UI, staging cleanup, ZIP creation and share UI.
- Existing P51-B behavior is device-tested and must be preserved.
- Backup engine extraction is deferred to P63C.

### `YYYPicker` mixes document-picker UI and restore engine
- Restore currently combines file picking, staging cleanup, ZIP extraction, nested Documents/Library discovery, recursive copy, skip rules, PreferenceManager reload and UI feedback.
- Restore engine extraction is deferred to P63D.

### Clear-game-data destructive behavior still lives in Dispatcher
- The current implementation clears tmp contents while preserving/recreating the tmp directory, removes Documents/Library and clears the app defaults domain before exit.
- It uses several `error:nil` filesystem operations and contains redundant delete/enumerate behavior.
- P63A must preserve current semantics; cleanup/error-model changes belong to dedicated P63B.

### Clear-authorization route still crosses a legacy entry
- `ZONAuthorizationResetService` already owns the effective clear set and P62 device validation passed.
- The button route still goes through `WX_NongShiFu123::deletekm` as a compatibility entry.
- P63A should establish a service boundary and must not duplicate or drift the P62 reset set.

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

### P62 Authorization Reset Service — CLOSED / DEVICE PASSED
- Source `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- A_customer and B_debug build/link/output verification passed.
- User explicitly reported the produced dylib tests fully normal.
- Authorization clear ownership now lives in `ZONAuthorizationResetService`.

### P62 SFHFKeychainUtils active dependency — CLOSED
- Active UDID storage was migrated to `ZONKeychain`.
- Legacy `SFHFKeychainUtils.h/.m` were removed from the active project surface.

### P62 reset-service PBX nondeterminism — CLOSED
- Migration script now verifies/inserts exact PBXBuildFile, PBXFileReference and PBXSourcesBuildPhase entries rather than relying on a global file-ID presence test.

### P62 CI migrated-revision race — CLOSED
- Build jobs are pinned to the exact migrated SHA and verify source membership before xcodebuild.

### Prior StoreKit/App Store cleanup — CLOSED
- Historical StoreKit/App Store residual cleanup remains covered by later device-verified baselines.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership is authoritative.

## Tracking rule
- Move an open risk to fully closed only after the required CI and, where applicable, real-device gate passes.
- Source edits or CI success alone do not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` so the five long-project records remain consistent.
