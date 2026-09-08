# zonoemenu Architecture

## Client architecture

```text
Host App
  -> zonoemenu bootstrap
     -> environment/runtime probe
     -> floating entry + menu shell
     -> service layer
        -> legacy BS/PHP auth adapter
        -> storage/config/update/download services
     -> feature registry
        -> built-in legacy features
        -> external dylib modules loaded with dlopen()
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
- +load/constructor must remain minimal.
- UI work must execute on main queue only after UIApplication is usable.
- Optional host frameworks are discovered before dlopen and failures must be non-fatal.
- External modules are opt-in and isolated: one module failure must not prevent core menu startup.
- No game-specific address, symbol, class, or offset belongs in the core layer.

## External module ABI v1
A loadable module should expose a small C ABI rather than requiring the core to know Objective-C class names.

Planned exported symbols:
- `zonoe_module_abi_version()`
- `zonoe_module_identifier()`
- `zonoe_module_initialize(const ZONHostAPI *host)`
- `zonoe_module_shutdown()`

The host API will provide versioned callbacks for logging, preference storage, UI feature registration and runtime/environment information. ABI structs use an explicit size/version field for forward compatibility.

## UI structure
```text
Floating Entry
  -> Main Menu Shell
     -> Status/Header
     -> Built-in Feature Sections
     -> External Module Sections
     -> Diagnostics
     -> About/Version
```

Existing PopupMenuVC remains the compatibility UI during v1 migration. New registration APIs feed into it incrementally rather than replacing it in one change.

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

## Proposed future database
- applications
- devices
- licenses
- license_devices
- sessions
- configs
- releases
- announcements
- audit_logs

No database migration is required for the initial compatibility MVP.

## Security invariants
- Treat all dylib/client-side secrets as recoverable.
- Do not rely on embedded symmetric secrets as the long-term trust root.
- Remote configuration affecting privileged behavior must eventually be signed/verifiable.
- Never allow a downloaded external module to load solely because a URL exists; add manifest/hash/signature validation before production remote module delivery.
