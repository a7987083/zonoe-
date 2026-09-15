# KNOWN_ISSUES

## Current baseline
- Promoted/device baseline: `v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3`.
- P42 CI Run `34995566144`: success.
- P42 real-device validation: passed.
- Active PBX Sources: 77.
- P43 audit Run `35001000784`: success; product runtime/PBX unchanged from P42.
- Canonical future plan: `ROADMAP.md`.

## Open risks

### P44 authorization orchestration extraction is startup-sensitive
- P43 selected the static authorization/reset helper block in `testmod/Bsphp/main.m` as the P44 extraction target.
- Planned boundary: `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m`.
- Risk: a mechanically small source move can still alter startup semantics if call order, queue behavior, callback ownership, object lifetime or method-replacement timing changes.
- Required invariants: reset-extension install remains before `ZONBootstrapStart`; original `deletekm` IMP call-through remains before extended UDID clearing; `DZUDID` and the four Zonoe bridge-default keys keep exact semantics; existing-keychain and bridge-cache fast paths remain unchanged; fresh acquisition remains status -> callback registration -> request; `[auth loada]` continuation remains unchanged.
- Mitigation: P44 must use an exact/mechanical extraction contract, protected-source identity checks, full A/B builds, export/load-library comparison and A_customer real-device validation before promotion.
- Rollback: P42 remains the device baseline until P44 passes its device gate.

### Global startup side effects remain order-sensitive
- `testmod/Bsphp/main.m` still uses `+load`, authorization-reset compatibility replacement and synchronous framework preflight/bootstrap behavior.
- P44 is not authorized to change those semantics; it may only move ownership of the selected helper block.
- Risk: startup order remains difficult to isolate and easy to break with innocent-looking cleanup.
- Plan: P46 instruments/measures launch ordering before any later startup simplification is considered.

### `WX_NongShiFu123.mm` remains a high-risk legacy god object
- P43 confirmed it remains active and owns broad responsibilities including `loada`, authorization state, network/server flows, UDID/IDFV branches, activation UI and validation/status behavior.
- Risk: direct cleanup or splitting can alter device activation, callback/UI timing or network behavior.
- Rule: do not rewrite or split it in P44. P44 treats it strictly as an implementation dependency.
- Later split work must be evidence-driven and isolated.

### Legacy web/profile fallback still depends directly on WX_NongShiFu123
- `ZonoeUDIDAPI.m` still invokes the existing `WX_NongShiFu123 getUDID:` fallback and reads `DZUDID` after completion.
- This is intentional and currently device-verified.
- Risk: legacy implementation details leak into the modern service boundary.
- Plan: P45 creates only a narrow adapter after P44 device pass; no fallback behavior rewrite.

### Other large active legacy surfaces remain coupled
- P43 confirmed `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain active/candidate legacy units.
- `PubgLoad.mm` mixes file/download/config/UI responsibilities.
- `JiangHuHook.m` is a protected runtime-hook surface affecting menu lifecycle, StoreKit and ad/video behavior through CaptainHook/ImgTool state.
- Risk: opportunistic splitting can alter state ownership, callbacks, UI timing or runtime hooks.
- Plan: defer god-object splitting to P48 and choose exactly one responsibility based on live call/state evidence.

### Repository hygiene
- Generated/package binaries, user-specific Xcode state and historical/reproducible material may remain tracked.
- Risk: repository/index/CI noise and accidental binary churn.
- Plan: P47 isolated cleanup only after proving no PBX/script/release/runtime consumer depends on each removal candidate.

### Dead-code assumptions can be wrong
- Historical audits already showed that apparently stale dependencies may still be live, including JDStatusBarNotification paths.
- Rule: file-name duplication or search absence is not deletion proof. PBX membership, import/caller reachability and runtime/symbol evidence are required.
- Plan: P49 re-audits active target/dependencies after the boundary work.

### Performance risks are not yet measured regressions
- Synchronous preflight, module loading and startup side effects may affect launch performance, but no current measured regression justifies changing timing/threading.
- Plan: P46 measurement first. Do not optimize queues, retry delays, `dlopen` timing or `+load` based on assumption.

## Closed / corrected

### P43 remaining-ownership uncertainty — CLOSED
- P43 work branch: `work/zonoemenu-v1-p43-architecture-audit`.
- Audit head: `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`.
- CI Run `35001000784`: success.
- Runtime/PBX tree versus P42 is unchanged and active Sources remain 77.
- P44 target is now explicitly fixed as the authorization orchestration/reset helper block in `main.m`; `WX_NongShiFu123.mm` is excluded from direct P44 rewriting.
- Evidence is recorded in `P43_ARCHITECTURE_AUDIT.md`.

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
