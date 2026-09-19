# ARCHITECTURE

## Canonical runtime surface
The active product runtime is `testmod/` plus `testmod.xcodeproj`. PBX target membership is authoritative for compiled source. Historical/duplicate trees outside that surface are not assumed active without PBX/call-chain evidence.

## Current baselines
- Promoted/device baseline: `v1_p62` / `a11160e70ff1163b2c462bb3ef5d539da1f489eb`.
- P62 CI head: `c1f1415d3787b879def387d68e2df089776dbffa`.
- P62 CI Run `35410564486`: success.
- P62 real-device validation: passed.
- Current candidate: `v1_p65` / test head `f5742ed68489b529169c850619cb9e1036150920`.
- P65 CI Run `35424279529`: success; device validation pending.
- Active PBX Sources: 78.
- Architectures: arm64 + arm64e.

## Startup / authorization
```text
dyld loads testmod.dylib
  -> testmod/Bsphp/main.m +load
     -> ZONInstallAuthorizationResetExtension()
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous framework preflight
           -> AppLovinSDK dynamic load if present
           -> UnityFramework dynamic load if present
        -> main queue variant entry
           -> B_debug: floating menu entry
           -> A_customer: ZONStartCustomerAuthorization()
              -> existing DZUDID keychain state
              -> ZonoeUDIDAPI bridge cache / request callback
              -> legacy fallback adapter when required
              -> WX_NongShiFu123::loada
                 -> BSPHP / BSPHPy authorization modes
                 -> NetTool / server config / activation UI
        -> ZONLoadBundledModules()
```

P65 keeps this sequence intact. It only centralizes private persistence/validation helpers inside `ZONAuthorizationCoordinator.m`.

## Identity / authorization persistence
```text
ZONAuthorizationCoordinator
  -> DZUDID keychain
  -> ZonoeUDIDAPI
     -> ZONUDIDBridge
        -> zonoe:// callback + nonce
        -> localhost bridge/cache
        -> NSUserDefaults bridge state
  -> legacy WX_NongShiFu123 loada continuation
```

P65 centralizes the exact existing persistence keys:
- `DZUDID`
- `zonoe.udid.bridge.value`
- `zonoe.udid.bridge.scheme`
- `zonoe.udid.bridge.requestTimestamp`
- `zonoe.udid.bridge.requestNonce`

## Menu ownership
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
              -> existing business handlers
              -> NSUserDefaults / ImgTool / file operations
```

Registry metadata remains the menu source of truth; Dispatcher owns route execution for migrated features.

## Extension module ownership
```text
ZONBootstrap
  -> ZONModuleLoader
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted .dylib scan
     -> standardized/resolved containment check
     -> dlopen(RTLD_NOW | RTLD_LOCAL)
     -> dlsym ABI / identifier / initialize
     -> module initialize(ZONHostAPI)
```

Successful modules intentionally stay loaded for process lifetime. The module scan/load currently executes on the main-queue Bootstrap ready path and should not be moved asynchronously without a measured, dedicated stage.

## Compilation boundary
The Xcode `testmod` target includes the modern boundaries plus legacy product sources. Important explicit boundaries include:
- `ZONBootstrap.m`
- `ZONModuleLoader.m`
- `ZONFeatureRegistry.m`
- `ZONFeatureDispatcher.m`
- menu coordinator/renderers/event bridge
- `ZONAuthorizationCoordinator.m`
- `ZonoeUDIDAPI.m`
- `ZONUDIDBridge.m`
- `ZONLegacyUDIDFallbackAdapter.m`
- legacy authorization/menu/hook/storage sources

P65 does not add/remove PBX sources; count remains 78.

## Main architectural debt
1. `WX_NongShiFu123.mm` still combines legacy authorization/network/server/UI/global-state responsibilities.
2. Server configuration parsing assumes expected split-array shapes before indexing.
3. Reachability helper needs isolated defensive hardening.
4. Clear-data completion and process exit are independently scheduled for the same deadline.
5. Startup `+load`, preflight, authorization and module loading remain order-sensitive.
6. `ZONLaunchTrace.h` still carries static-inline implementation rather than declaration-only ownership.
7. Dispatcher is stable but directly imports several legacy business handlers.

See `P65_CODEBASE_REVIEW.md`, `ROADMAP.md`, `KNOWN_ISSUES.md` and `PROJECT_STATE.json` for the staged remediation plan and current validation state.
