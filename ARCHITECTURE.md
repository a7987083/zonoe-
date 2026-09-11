# zonoemenu Architecture

## Client architecture
```text
Host App
  -> zonoemenu bootstrap
     -> environment/runtime probe
     -> floating entry
        -> PopupMenuVC compatibility shell
           -> ZONMenuCoordinator
              -> ZONMenuPanelController
              -> ZONMenuChromeRenderer
              -> ZONSectionRenderer
                 -> ZONFeatureRegistry
              -> ZONMenuEventBridge
                 -> existing dispatcher/business handlers
     -> service layer
        -> legacy BS/PHP auth adapter
        -> storage/config/update/download services
     -> external module layer
        -> versioned module ABI
        -> bundle-local dylib loader
```

## Technology / runtime constraints
- Objective-C / Objective-C++ / C / C++.
- UIKit; no SwiftUI migration for v1.
- Xcode dylib target with current MonkeyDev/Theos integration.
- arm64 + arm64e; production minimum iOS 12.0+.
- Existing fishhook/CaptainHook/runtime facilities remain behind feature boundaries.

## Menu ownership
- `PopupMenuVC`: UIKit lifecycle boundary and legacy selector passthrough.
- `ZONMenuCoordinator`: orchestration/lifecycle, panel/scroll ownership, build/relayout, show/hide/close and event forwarding.
- `ZONMenuPanelController`: panel construction/layout/animation.
- `ZONMenuChromeRenderer`: header/chrome rendering.
- `ZONSectionRenderer`: section rendering/relayout.
- `ZONFeatureRegistry`: feature/section data source.
- `ZONMenuEventBridge`: action/toggle/runtime bridge to existing business handlers.

## Compilation boundary after v1_p28
```text
PopupMenuVC.m
  -> #import ZONMenuCoordinator.h

Xcode target: testmod
  -> compiles PopupMenuVC.m
  -> compiles ZONMenuCoordinator.m independently
```

p27 removed `@implementation` from the public coordinator header but temporarily compiled the `.m` through `PopupMenuVC.m`. p28 removes that bridge and registers `ZONMenuCoordinator.m` directly in the target Sources phase. The coordinator implementation itself is unchanged.

## Bootstrap rules
- Keep `+load`/constructor minimal.
- UI work must execute on the main queue after UIApplication is usable.
- Optional module/framework failures must be non-fatal to core startup.
- Game-specific offsets/symbols/classes do not belong in core.

## External module ABI
External dylibs should use a small versioned C ABI and eventually require manifest/hash/signature validation before production remote delivery.

## Security invariants
- Treat client-side secrets as recoverable.
- Do not rely on embedded symmetric secrets as the long-term trust root.
- Privileged remote configuration should eventually be signed/verifiable.
