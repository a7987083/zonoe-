# CODEBASE REVIEW / REFACTOR PLAN

## Review baseline
- Repository: `a7987083/zonoe-`.
- Current promoted/device baseline: `v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI Run `34995566144`: success.
- P42 real-device validation: passed.
- Active PBX Sources: 77.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- **Canonical future phase order, scope and gates live in `ROADMAP.md`. This review records architecture facts and risks; it does not override ROADMAP sequencing.**

## Current architecture summary

### Startup / authorization
```text
dyld loads testmod dylib
  -> testmod/Bsphp/main.m +load
     -> install authorization-reset compatibility hook
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous framework preflight
        -> main queue variant entry
           -> B_debug: floating entry
           -> A_customer: status -> ZonoeUDIDAPI -> authorization continuation
        -> ZONLoadBundledModules()
```

### UDID / authorization identity path
```text
A_customer authorization startup
  -> ZonoeUDIDAPI.h
     -> ZonoeUDIDAPI.m
        -> ZONUDIDBridge.h
           -> ZONUDIDBridge.m
              -> zonoe://udid callback + nonce
              -> localhost bridge polling
              -> NSUserDefaults bridge cache
        -> legacy WX_NongShiFu123 getUDID: fallback when needed
        -> DZUDID keychain validation/storage continuation
  -> existing authorization continuation
```

### Menu / feature flow
```text
NSObject+UI floating entry
  -> PopupMenuVC compatibility shell
     -> ZONMenuCoordinator
        -> ZONMenuPanelController
        -> ZONMenuChromeRenderer
        -> ZONSectionRenderer
           -> ZONFeatureRegistry
           -> ZONFeatureRenderer
        -> ZONMenuEventBridge
           -> ZONFeatureDispatcher
              -> legacy business handlers
              -> NSUserDefaults / ImgTool runtime state
```

### Extension-module flow
```text
ZONBootstrap
  -> ZONModuleLoader
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted .dylib enumeration
     -> standardized/resolved containment check
     -> dlopen(RTLD_NOW | RTLD_LOCAL)
     -> dlsym ABI version / identifier / initialize
     -> initialize(ZONHostAPI)
```

## Closed architecture findings

### Canonical-source ambiguity — corrected
- P38 established `testmod/` + `testmod.xcodeproj` as the canonical active product surface.
- PBX membership still decides whether code is active.

### Bootstrap / ModuleLoader implementation-heavy headers — corrected
- P33 moved active implementation ownership into explicit `.m` translation units.

### ZONUDIDBridge implementation-heavy header — corrected
- P41 source: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- `ZONUDIDBridge.h` is declaration-only; `ZONUDIDBridge.m` owns implementation.
- CI and real-device validation passed.

### ZonoeUDIDAPI mixed with UI category — corrected
- P42 source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- `ZonoeUDIDAPI.m` now owns stable public UDID API state/implementation.
- `NSObject+UI.m` no longer owns the UDID callback/fallback block.
- CI and real-device validation passed.

## Remaining priority findings

### P0 — authorization orchestration ownership is still cross-cutting
Authorization startup currently spans `main.m`, `ZonoeUDIDAPI`, `ZONUDIDBridge` and legacy `WX_NongShiFu123` continuation behavior.

Risk:
- a structural move can alter callback order, queue ownership, one-shot delivery, startup continuation or customer/B_debug branching even without changing obvious business logic.

Plan:
- P43 first maps exact callers/state ownership from the P42 tree.
- P44 may isolate only the smallest mechanically provable authorization-orchestration boundary.
- `+load` timing and authorization continuation are protected.

### P0 — global startup side effects remain order-sensitive
`main.m` still uses `+load`, method implementation replacement for authorization reset and synchronous startup/preflight behavior.

Risk:
- order-dependent behavior and weak test isolation.

Plan:
- do not optimize or reorder during ownership cleanup.
- P46 adds instrumentation/launch contract before any future timing/threading change is considered.

### P1 — legacy fallback coupling
`ZonoeUDIDAPI.m` still directly instantiates/calls `WX_NongShiFu123` for the existing web/profile UDID fallback and reads `DZUDID` after completion.

Risk:
- a modern service boundary still knows legacy implementation details.

Plan:
- P45 may add a narrow adapter only after P43/P44 evidence.
- no rewrite of fallback semantics, trigger conditions, keychain key or callback behavior.

### P1 — repository hygiene / generated artifacts
Generated/package binaries, user-state and historical/reproducible material may remain tracked.

Risk:
- repository size/indexing noise and accidental binary churn.

Plan:
- P47 isolates cleanup from runtime refactors and proves each removal has no PBX/script/release/runtime consumer.

### P2 — large legacy files / god objects
Large surfaces including `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m` remain expensive to reason about.

Risk:
- hidden shared state, callbacks, selectors, runtime hooks and UI lifecycle coupling.

Plan:
- P43 audits actual call/target ownership.
- P48 selects exactly one unit and one responsibility based on evidence; no opportunistic multi-file redesign.

### P2 — dead-code/dependency assumptions
Historical review already proved that apparently stale components can remain live through PBX or indirect runtime paths.

Plan:
- P49 re-audits active target/dependencies after the boundary phases.
- deletion requires PBX/import/caller/symbol evidence and a dedicated verification gate.

## Performance observations
No current measured regression justifies semantic optimization. Potential costs remain:
- synchronous framework/preflight work during startup;
- module scan/load after variant entry;
- localhost polling retry windows;
- repository/generated material affecting CI/indexing rather than proven runtime performance.

Rule: measurement before optimization. P46 owns startup timing/signpost evidence; structural phases must not alter queue/timing semantics.

## Protected behavior
Until a ROADMAP stage explicitly authorizes and proves otherwise, preserve:
- `main.m +load` timing and Bootstrap/authorization sequencing;
- authorization-reset compatibility behavior;
- Zonoe callback scheme/host, nonce generation/validation, callback parsing and storage keys;
- localhost bridge port/timeouts/retry count/delay/pending age/request throttle;
- `zonoe://udid` preferred path and legacy web/profile fallback;
- `DZUDID` keychain semantics;
- floating/menu stack and active features;
- cloud save/local files/backup-restore/clear-data/clear-auth paths;
- module-loader directories, containment checks, ABI checks and `dlopen` behavior;
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime paths.

## Next review action
Execute P43 as defined in `ROADMAP.md`: refresh active PBX/source reachability and ownership evidence from the actual P42 tree, then choose exactly one P44 authorization-orchestration extraction target. Do not change product runtime during the audit merely to reduce file size or improve aesthetics.
