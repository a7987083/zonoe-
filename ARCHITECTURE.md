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

## Technology
- Objective-C / Objective-C++ / C / C++.
- UIKit; no SwiftUI migration for v1.
- Xcode dylib target; current MonkeyDev/Theos integration retained initially.
- arm64 + arm64e; iOS 12.0+.
- fishhook/CaptainHook/runtime facilities retained behind feature boundaries.
- Keychain for sensitive per-device/session values; NSUserDefaults for non-sensitive preferences.
- Legacy AFNetworking retained for compatibility, with new networking isolated behind a service interface.

## Bootstrap rules
- `+load`/constructor must remain minimal.
- UI work must execute on main queue only after UIApplication is usable.
- Optional host frameworks are discovered before dlopen and failures must be non-fatal.
- External modules are opt-in and isolated: one module failure must not prevent core menu startup.
- No game-specific address, symbol, class, or offset belongs in the core layer.

## Menu ownership after v1_p26
`PopupMenuVC` remains the public/legacy compatibility controller but is no longer the menu implementation owner.

Responsibilities:
- `PopupMenuVC`: UIKit lifecycle boundary and legacy selector passthrough only.
- `ZONMenuCoordinator`: orchestration/lifecycle, panel/scroll ownership, build/relayout, show/hide/close and event forwarding.
- `ZONMenuPanelController`: panel construction, geometry, visible layout and animations.
- `ZONMenuChromeRenderer`: header/chrome rendering.
- `ZONSectionRenderer`: renders registered sections and performs section relayout.
- `ZONFeatureRegistry`: feature/section data source.
- `ZONMenuEventBridge`: preserves existing action/toggle/runtime dispatch behavior.

p26 intentionally changes ownership structure, not feature semantics or menu appearance.

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

## External module ABI v1
A loadable module should expose a small C ABI rather than requiring the core to know Objective-C class names.

Planned exported symbols:
- `zonoe_module_abi_version()`
- `zonoe_module_identifier()`
- `zonoe_module_initialize(const ZONHostAPI *host)`
- `zonoe_module_shutdown()`

The host API will provide versioned callbacks for logging, preference storage, UI feature registration and runtime/environment information. ABI structs use an explicit size/version field for forward compatibility.

## Backend transition
Phase 1: `LegacyBSAuthAdapter` reproduces current behavior exactly.
Phase 2: new backend issues short-lived sessions and signed remote configuration.

Proposed future API:
- POST /v1/auth/activate
- POST /v1/auth/refresh
- POST /v1/device/register
- GET /v1/config
- GET /v1/releases/latest
- GET /v1/announcements

## Security invariants
- Treat all dylib/client-side secrets as recoverable.
- Do not rely on embedded symmetric secrets as the long-term trust root.
- Remote configuration affecting privileged behavior must eventually be signed/verifiable.
- Never allow a downloaded external module to load solely because a URL exists; add manifest/hash/signature validation before production remote module delivery.
