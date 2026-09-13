# ARCHITECTURE

## Canonical runtime surface
The active product runtime is `testmod/` plus `testmod.xcodeproj`. The repository root still contains legacy/duplicate source trees with overlapping names; those copies are not assumed canonical unless PBX/call-chain evidence proves otherwise.

## Startup / authorization
```text
dyld loads testmod dylib
  -> testmod/Bsphp/main.m +load
     -> authorization-reset compatibility hook
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous legacy framework preflight
        -> main queue variant entry
           -> B_debug: floating entry
           -> A_customer: status -> keychain/UDID -> authorization loada
        -> ZONLoadBundledModules()
```

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
```

## Extension module ownership
```text
ZONBootstrap.m
  -> ZONModuleLoader.m
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted .dylib scan
     -> path containment check
     -> dlopen / dlsym ABI checks
     -> module initialize(ZONHostAPI)
```

`ZONModuleLoader` is an active runtime boundary: Bootstrap invokes `ZONLoadBundledModules()`. Before p33 its implementation lived in `ZONModuleLoader.h` and was therefore compiled transitively into callers. P33 makes that ownership explicit with an independent `.m` target source.

## Compilation boundary at v1_p33 candidate
```text
Xcode target: testmod
  -> PopupMenuVC.m
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
  -> ZONFeatureRegistry.m
  -> ZONFeatureDispatcher.m
  -> ZONModuleLoader.m
  -> ZONBootstrap.m
  -> legacy product sources
```

Declaration-only boundaries now include `ZONFeatureRegistry.h`, `ZONFeatureDispatcher.h`, `ZONModuleLoader.h` and `ZONBootstrap.h`.

## Remaining implementation-heavy boundary
`testmod/ZONServices/ZONUDIDBridge.h` still contains active callback/nonce/storage/socket/request implementation. The public `ZonoeUDIDAPI` implementation also currently lives inside `NSObject+UI.m`, mixing identity/auth plumbing with UI ownership. This is a future isolated audit/refactor candidate and is intentionally unchanged in p33.

## Runtime baselines
- Device-verified: `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Current CI-verified candidate: `v1_p33` / `0f12e4353e8859c585fe2975812964a28b7410d1`.
- p33 Run `34733013479`: success.
- p33 is not promoted until its required real-device regression passes.

See `REFACTOR_REVIEW.md` for the full architecture review, risks and staged refactor plan.
