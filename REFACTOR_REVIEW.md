# CODEBASE REVIEW / REFACTOR PLAN

## Review baseline
- Repository: `a7987083/zonoe-`
- Device-verified runtime baseline: `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Current development candidate: `v1_p33` / `0f12e4353e8859c585fe2975812964a28b7410d1`.
- p33 CI: Run `34733013479` / success.
- p33 device status: pending; p32 remains the promoted runtime baseline until explicit device regression passes.

## Architecture summary

### Startup / authorization
```text
dyld loads testmod dylib
  -> testmod/Bsphp/main.m +load
     -> install authorization-reset compatibility hook
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous legacy framework preflight (AppLovinSDK / UnityFramework)
        -> main queue variant entry
           -> B_debug: floating entry
           -> A_customer: status -> keychain / UDID -> authorization loada
        -> ZONLoadBundledModules()
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

### UDID flow
```text
main.m
  -> public ZonoeUDIDAPI functions (currently implemented in NSObject+UI.m)
     -> ZONUDIDBridge header-owned implementation
        -> callback URL + nonce and/or localhost result fetch
        -> NSUserDefaults bridge cache
     -> DZUDID keychain
     -> authorization loada
```

## Priority findings

### P0 — canonical-source ambiguity
The repository contains legacy source trees at repository root and active copies below `testmod/`. Some names are duplicated while implementations have diverged substantially; for example the root `菜单/PopupMenuVC.m` is a legacy all-in-one controller while `testmod/菜单/PopupMenuVC.m` is now only the compatibility shell around `ZONMenuCoordinator`.

Risk: an engineer can make a correct-looking change to the wrong copy and produce no runtime change, or later accidentally reintroduce obsolete implementation.

Plan: treat `testmod/` + `testmod.xcodeproj` as the canonical product-runtime surface, then audit PBX membership and references before archiving/removing root duplicates in an isolated no-runtime-change phase.

### P0 — implementation-heavy active headers
Before p33, `ZONBootstrap.h` and `ZONModuleLoader.h` contained active runtime implementations as `static inline` functions. `ZONModuleLoader` was incorrectly described by old documentation as inactive, but Bootstrap directly invokes `ZONLoadBundledModules()`.

Risk: implicit compilation ownership, transitive-import dependency, duplicate definitions/copies, and misleading target topology.

Status: fixed in p33 by declaration headers + independent `.m` translation units, exact body-equivalence checks and PBX registration.

Remaining high-risk example: `testmod/ZONServices/ZONUDIDBridge.h` is still a large active implementation header.

### P1 — UDID/auth plumbing mixed with UI category
`testmod/视图菜单/NSObject+UI.m` owns both floating/menu UI behavior and the stable `ZonoeUDIDAPI` implementation, while the lower-level bridge itself is implemented in `ZONUDIDBridge.h`.

Risk: device identity, callback lifecycle, networking/socket retry logic and UIKit presentation share compilation/lifecycle ownership. A future UI edit can accidentally affect auth/UDID behavior.

Plan: first audit and lock the UDID state machine; then mechanically move stable API implementation to `ZonoeUDIDAPI.m` and bridge implementation to `ZONUDIDBridge.m`. Require customer authorization/UDID real-device regression before promotion.

### P1 — repository hygiene / generated artifacts
The tree includes generated/package binaries and user-specific Xcode state alongside source.

Risk: repository size, indexing noise, accidental binary churn and weak source/build provenance.

Plan: audit consumers first, then isolate a repository-hygiene commit with `.gitignore` and removal of reproducible/generated/user-state files. Do not combine with runtime refactors.

### P2 — large legacy files / god objects
Large legacy surfaces such as `jianghu.*`, `WX_NongShiFu123.mm`, `DLGMemUIView.m` and `PubgLoad.mm` carry broad responsibility and are expensive to reason about.

Plan: audit actual call/target ownership before splitting. Each split needs an invariant contract and its own build/device gate; do not perform opportunistic rewrites.

### P2 — global startup side effects
`main.m` uses `+load`, method implementation replacement for authorization reset, synchronous framework preflight and global/static state.

Risk: order-sensitive startup behavior and difficult isolation/testing.

Plan: instrument first; only then consider a launch adapter. Preserve `+load` timing until measured behavior proves it can move safely.

## Performance observations
No runtime profiler or launch-time measurement was produced by this review, so these are risks, not measured regressions:
- framework existence checks and `dlopen` happen synchronously during `+load` preflight;
- bundled-module directory scan and `dlopen` currently occur on the main queue after variant entry;
- UDID localhost polling is off-main but can span repeated socket timeout/sleep cycles;
- duplicate sources/binaries primarily hurt checkout/index/CI rather than proven runtime performance.

Recommended next performance step: add signpost/timing around preflight, authorization-ready, module scan and first menu presentation before changing thread/timing semantics.

## p33 implemented refactor
- `VERSION` -> `v1_p33`.
- `ZONBootstrap.h` -> declarations only.
- Added `ZONBootstrap.m` with the exact p32 implementation body.
- `ZONModuleLoader.h` -> public declarations only.
- Added `ZONModuleLoader.m`; public entry points are external functions and internal helpers are file-static.
- Registered both `.m` files in the `testmod` Xcode target.
- Added `Tests/bootstrap_moduleloader_contract.py` and permanent CI coverage.

No intended authorization, UDID, menu, dispatcher, module ABI, route, persistence, UI or module-loading semantic change.

## Behavior-preservation proof
`Tests/bootstrap_moduleloader_contract.py` compares the moved function bodies against device-verified p32 commit `84f8b3898bee9d95ed4034d12842879cc56280d3` for:
- `ZONBootstrapStart`
- `ZONCoreLog`
- `ZONGetHostAPI`
- `ZONBundledModuleDirectories`
- `ZONPathIsInsideDirectory`
- `ZONLoadModuleAtPath`
- `ZONLoadBundledModules`

It additionally locks call ownership and module-loader safety/ABI invariants: module directories, `.dylib` filter, symlink resolution, `RTLD_NOW | RTLD_LOCAL`, required exports, ABI rejection, duplicate-identifier rejection, host API initialization and failure `dlclose`.

CI Run `34733013479` additionally proved:
- source scope stayed isolated from protected auth/UI/Dispatcher files;
- both new translation units compile independently under `-Wall -Wextra -Werror`;
- required exported symbols exist;
- Dispatcher contract, Feature Registry smoke and Module ABI smoke pass;
- `A_customer` and `B_debug` fully compile/link/package for iOS 12, arm64 + arm64e.

## Promotion rule
P33 is `ci_verified_device_pending`. It must not supersede p32 until the p33 real-device startup/bootstrap checklist is explicitly reported as passed.
