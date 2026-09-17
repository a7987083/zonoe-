# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p48_1` / `71eddfa0600112aa56a8bef45013d73f4673794a`.
- CI Run `35180342515`: success.
- Real-device validation: passed, explicitly reported by user.
- Active Sources: **78**.
- Architectures: `arm64 + arm64e`.
- Canonical plan: `ROADMAP.md`.

## Open risks

### P49 dead-code/dependency removal risk
- P49 is the next planned stage.
- No source, framework, library, script or historical audit asset may be removed merely because it appears old or unused.
- Required evidence includes PBX membership, imports/callers, runtime lookup paths, symbols/load commands, build scripts/workflows and package consumers.
- Any candidate removal must be compared against the P48.1 promoted baseline and pass both build and device gates where runtime-affecting.

### Global startup side effects remain order-sensitive
- `main.m +load`, framework preflight, Bootstrap, authorization, module loading and floating-entry lifecycle remain order-sensitive.
- Later cleanup must not alter queueing, callback order, retries, timeouts or module load timing without an explicit behavior phase.

### `WX_NongShiFu123.mm` remains a high-risk legacy god object
- It remains active and still owns legacy authorization/network/server state, UDID/IDFV branches, activation UI and status behavior.
- Structural changes require narrow scope and equivalence evidence.

### Other large active legacy surfaces remain coupled
- `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain candidate legacy units.
- `JiangHuHook.m` remains a protected runtime-hook surface; opportunistic cleanup can alter behavior.

### Historical CI/scripts remain intentionally tracked
- Historical phase scripts/tests/workflows provide reproducibility and audit evidence.
- Their age is not evidence of deadness.

## Closed / corrected

### P48.1 StoreKit residual cleanup device gate — CLOSED
- Source `71eddfa0600112aa56a8bef45013d73f4673794a`.
- CI Run `35180342515`: success.
- User explicitly reported real-device validation normal.
- P48.1 is now the promoted rollback/device baseline.

### Residual StoreKit/App Store surface in YYYPicker — CLOSED BY P48.1
- StoreKit import/protocol/product-page methods and App Store identifier path were removed.
- Restore-save/import behavior was preserved.
- PBX is unchanged versus P48.
- Exported symbols are unchanged versus P48.
- Mach-O load-library delta is exactly the removal of `StoreKit.framework`; all other libraries remain unchanged.

### P45/P46/P47 pending inherited device gate — SUPERSEDED/COVERED
- Their relevant runtime behavior is now covered by later promoted real-device-passed baselines.
- They remain historical intermediate stages and are not rollback baselines.

### Tracked generated package ZIP — CLOSED BY P47
- Removed after no-consumer evidence and protected by `Packages/*.zip` ignore rule.

### P44 device validation — CLOSED / SUPERSEDED
- P44 passed real-device validation and served as rollback baseline until later promoted versions.

### Authorization orchestration mixed into main.m — CLOSED
- P44 mechanically moved the selected authorization/reset block into `ZONAuthorizationCoordinator.h/.m`.

### ZonoeUDIDAPI ownership mixed with UI — CLOSED
- Closed by P42 and covered by later device-verified baselines.

### ZONUDIDBridge implementation-heavy header — CLOSED
- Closed by P41 and covered by later device-verified baselines.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership is authoritative.

## Tracking rule
Move an open risk to fully closed only after the required CI and, where applicable, real-device gate passes. Source edits or CI success alone do not equal promotion.
