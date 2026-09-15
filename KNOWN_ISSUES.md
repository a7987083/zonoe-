# KNOWN_ISSUES

## Current baseline
- Promoted/device baseline: `v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI Run `34995566144`: success.
- Real-device validation: passed.
- Active PBX Sources: 77.
- Canonical future plan: `ROADMAP.md`.

## Open risks

### Global startup side effects remain order-sensitive
- `testmod/Bsphp/main.m` still uses `+load`, authorization-reset compatibility replacement and synchronous startup/preflight behavior.
- Risk: startup order is difficult to isolate and easy to break with innocent-looking structural changes.
- Rule: timing/order remains protected. P46 instruments/measures before any later startup simplification is considered.

### Authorization orchestration remains coupled to legacy startup/auth implementation
- P41/P42 fixed UDID bridge/API ownership, but the higher-level authorization orchestration still crosses `main.m`, Zonoe UDID API and legacy `WX_NongShiFu123` behavior.
- Risk: moving callbacks/continuations can change customer startup semantics even when function bodies look equivalent.
- Plan: P43 audits exact ownership/callers; P44 may extract only a mechanically provable orchestration boundary.

### Legacy web/profile fallback still depends directly on WX_NongShiFu123
- `ZonoeUDIDAPI.m` still invokes the existing `WX_NongShiFu123 getUDID:` fallback and reads `DZUDID` after completion.
- This is intentional and currently device-verified.
- Risk: legacy implementation details leak into the modern service boundary.
- Plan: P45 creates only a narrow adapter after P44/P43 evidence; no fallback behavior rewrite.

### Repository hygiene
- Generated/package binaries, user-specific Xcode state and historical/reproducible material may remain tracked.
- Risk: repository/index/CI noise and accidental binary churn.
- Plan: P47 isolated cleanup only after proving no PBX/script/release/runtime consumer depends on each removal candidate.

### Large legacy surfaces / god objects
- `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m` and related legacy units still contain broad responsibilities.
- Risk: opportunistic splitting can alter state ownership, callbacks, UI timing or runtime hooks.
- Plan: P43 produces reachability/ownership evidence; P48 splits exactly one responsibility from exactly one selected unit.

### Dead-code assumptions can be wrong
- Historical audits already showed that apparently stale dependencies may still be live, e.g. JDStatusBarNotification paths.
- Rule: file-name duplication or search absence is not deletion proof. PBX membership, import/caller reachability and runtime/symbol evidence are required.
- Plan: P49 re-audits active target/dependencies after the boundary work.

### Performance risks are not yet measured regressions
- Synchronous preflight, module loading and startup side effects may affect launch performance, but no current measured regression justifies changing timing/threading.
- Plan: P46 measurement first. Do not optimize queues, retry delays, `dlopen` timing or `+load` based on assumption.

## Closed / corrected

### P41 real-device validation pending — CLOSED
- P41 source `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`, CI Run `34959813770`.
- User explicitly reported real-device validation normal.
- P41 was later superseded by device-verified P42.

### ZonoeUDIDAPI ownership mixed with UI — CLOSED
- Closed by P42 source `e87b683a9c868e00d13582c8145bb9368878fee3`.
- `ZonoeUDIDAPI` implementation now lives in `testmod/ZONServices/ZonoeUDIDAPI.m`.
- `NSObject+UI.m` no longer owns UDID callback/fallback state.
- P42 CI and real-device validation passed.

### ZONUDIDBridge implementation-heavy header — CLOSED
- Closed by P41.
- `ZONUDIDBridge.h` is declaration-only; implementation lives in `ZONUDIDBridge.m`.
- P41 contract/build/device validation passed.

### Canonical product-source ambiguity — CORRECTED
- P38 established `testmod/` + `testmod.xcodeproj` as canonical active product surface.
- New work must still verify PBX membership rather than relying on filenames alone.

### ModuleLoader inactive-path assumption — CORRECTED
- P33 made Bootstrap/ModuleLoader ownership explicit through `.m` translation units and permanent contract coverage.

### Dispatcher/Registry earlier validation risks — CLOSED
- Covered by their own CI/device gates and superseded by later device-verified baselines through P42.

## Tracking rule
When a planned ROADMAP risk becomes fixed, move it to `Closed / corrected` only after the corresponding CI gate and, when required, real-device gate pass. Do not mark an issue closed merely because source code was edited.
