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
- Legacy AFNetworking is retained for compatibility.

## Menu ownership after v1_p26
`PopupMenuVC` is the public/legacy UIKit compatibility controller, not the menu implementation owner.

Responsibilities:
- `PopupMenuVC`: UIKit lifecycle boundary and legacy selector passthrough.
- `ZONMenuCoordinator`: menu orchestration/lifecycle, panel/scroll ownership, build/relayout, show/hide/close and event forwarding.
- `ZONMenuPanelController`: panel construction, geometry, visible layout and animations.
- `ZONMenuChromeRenderer`: header/chrome rendering.
- `ZONSectionRenderer`: registered section rendering and relayout.
- `ZONFeatureRegistry`: feature/section data source.
- `ZONMenuEventBridge`: preserves existing action/toggle/runtime dispatch behavior.

p26 changed ownership structure, not feature semantics or visual appearance, and has passed device/runtime regression.

## p27 compilation-boundary cleanup
p27 does not change the runtime ownership graph. It changes source organization only:

```text
ZONMenuCoordinator.h
  -> public interface only

ZONMenuCoordinator.m
  -> private ZONCore dependencies
  -> private properties
  -> existing implementation

PopupMenuVC.m
  -> imports ZONMenuCoordinator.h
  -> legacy single compilation bridge imports ZONMenuCoordinator.m once
```

Why the bridge exists: `testmod.xcodeproj/project.pbxproj` is an older explicit-file target and does not currently enumerate the p19-p27 ZONCore source files. Adding a new `.m` file to disk alone would not make it a target source. p27 avoids broad project-file churn while removing the risk of exposing an `@implementation` from a public header. Explicit PBX integration can be handled as a separate verified cleanup later.

## UI flow
```text
Floating Entry
  -> PopupMenuVC
     -> ZONMenuCoordinator
        -> Header/Chrome
        -> Registered Feature Sections
        -> Diagnostics/About sections
        -> Event Bridge -> Existing business/runtime handlers
```

## Bootstrap rules
- Keep `+load`/constructor minimal.
- UI work must execute on the main queue after UIApplication is usable.
- Optional host framework/module failures must be non-fatal to core startup.
- No game-specific address, symbol, class or offset belongs in the core layer.

## External module ABI v1
A loadable module should expose a small versioned C ABI rather than require the core to know Objective-C class names. Planned symbols include:
- `zonoe_module_abi_version()`
- `zonoe_module_identifier()`
- `zonoe_module_initialize(const ZONHostAPI *host)`
- `zonoe_module_shutdown()`

Remote module delivery must eventually include manifest/hash/signature validation.

## Security invariants
- Treat all client-side secrets as recoverable.
- Do not rely on embedded symmetric secrets as the long-term trust root.
- Privileged remote configuration should eventually be signed/verifiable.
