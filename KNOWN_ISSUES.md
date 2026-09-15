# KNOWN_ISSUES

## Current baseline
- Promoted/device baseline: `v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3`.
- P42 CI Run `34995566144`: success; real-device validation passed.
- Current candidate: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- P44 CI Run `35020232205`: success.
- P44 device status: **pending**.
- Active PBX Sources: 78 on P44 candidate.
- Canonical plan: `ROADMAP.md`.

## Open risks

### P44 real-device authorization/lifecycle validation pending
- The structural extraction itself is CI-verified: mechanical equivalence contract passed, coordinator independent compile passed, A_customer/B_debug arm64+arm64e builds passed, and exported symbols/load libraries are identical to P42.
- Remaining risk is runtime lifecycle behavior that static/build checks cannot prove: Objective-C block/object lifetime across the new translation unit, `+load` startup lifecycle, method-replacement timing, foreground return after Zonoe/browser, and legacy fallback continuation.
- Required device checks: existing `DZUDID` fast path; clear-auth/fresh Zonoe callback and `DZUDID` writeback; deletekm reset clearing bridge state; fallback/foreground return without duplicate loop/crash; menu smoke.
- Rollback: P42 remains promoted until explicit P44 real-device PASS.

### Global startup side effects remain order-sensitive
- `testmod/Bsphp/main.m` still uses `+load`, framework preflight and Bootstrap startup behavior.
- P44 deliberately preserved those semantics and only moved authorization/reset helper ownership.
- Risk: later cleanup can still break ordering even when source looks simpler.
- Plan: P46 instruments/measures launch ordering before any startup simplification.

### `WX_NongShiFu123.mm` remains a high-risk legacy god object
- It remains active and owns broad responsibilities including `loada`, authorization state, network/server flows, UDID/IDFV branches, activation UI and validation/status behavior.
- P44 treats it only as an implementation dependency; it was not rewritten or split.
- Later split work must be evidence-driven and isolated.

### Legacy web/profile fallback still depends directly on WX_NongShiFu123
- `ZonoeUDIDAPI.m` still invokes the existing `WX_NongShiFu123 getUDID:` fallback and reads `DZUDID` after completion.
- This is intentional and remains the target for P45 only after P44 device promotion.
- Risk: legacy class details remain coupled to the modern UDID service boundary.

### Other large active legacy surfaces remain coupled
- `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain active/candidate legacy units.
- `JiangHuHook.m` is a protected runtime-hook surface; opportunistic splitting can alter StoreKit/ad/video/menu behavior.
- Plan: defer a single evidence-driven split to P48.

### Repository hygiene
- Generated/package binaries, user-specific Xcode state and historical/reproducible material may remain tracked.
- Plan: P47 isolated cleanup only after proving no PBX/script/release/runtime consumer depends on each candidate.

### Dead-code assumptions can be wrong
- Historical audits already showed apparently stale dependencies can still be live, including JDStatusBarNotification paths.
- Rule: PBX membership, import/caller reachability and runtime/symbol evidence are required before deletion.
- Plan: P49 re-audits after boundary work.

### Performance risks are not yet measured regressions
- Synchronous preflight/module/startup effects may affect launch performance, but no measured regression currently justifies timing/threading changes.
- Plan: P46 measurement first.

## Closed / corrected

### P44 authorization orchestration ownership mixed into main.m — STRUCTURALLY CLOSED / DEVICE GATE OPEN
- Product source `aee574d180da7cc82db54be7ab5aeaa9d072c561` adds `ZONAuthorizationCoordinator.h/.m` and mechanically removes the helper implementation block from `main.m`.
- CI Run `35020232205`: success.
- Active Sources 77 → 78; sole new source `ZONAuthorizationCoordinator.m`.
- A/B builds, independent compile, mechanical contract, P42 ABI and load-library comparisons all passed.
- This item is structurally closed, but promotion remains blocked by the separate P44 device-validation issue above.

### P43 remaining-ownership uncertainty — CLOSED
- P43 audit head `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`; CI `35001000784` success.
- Runtime/PBX versus P42 unchanged; P44 target was explicitly selected from audit evidence.

### P41 real-device validation pending — CLOSED
- P41 CI passed and user explicitly reported device validation normal; later superseded by P42.

### ZonoeUDIDAPI ownership mixed with UI — CLOSED
- Closed by P42 source `e87b683a9c868e00d13582c8145bb9368878fee3`; P42 CI/device passed.

### ZONUDIDBridge implementation-heavy header — CLOSED
- Closed by P41; bridge declaration/implementation ownership is explicit and device-verified through later baselines.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership remains authoritative.

### ModuleLoader / Dispatcher / Registry earlier validation risks — CLOSED
- Covered by permanent contracts/CI and superseded by later device-verified baselines.

## Tracking rule
Move an open risk to fully closed only after its required CI and, where applicable, real-device gate pass. Source edits or CI success alone do not equal runtime promotion.
