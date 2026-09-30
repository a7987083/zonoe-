# ARCHITECTURE

## Review baseline
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Active development branch: `work/p79.8-udid-first-rebuild`.
- Current behavior-preserving architecture hardening build: `v1_p79_8e`.
- Product behavior baseline remains P79.8d; P79.8e changes tests/CI only and produces a byte-identical raw dylib.
- Last real-device-confirmed authorization baseline: P79.8a.

## Startup and bootstrap
```text
dyld loads testmod dylib
  -> testmod/Bsphp/main.m +load
     -> ZONInstallAuthorizationResetExtension()
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous legacy framework preflight
           -> AppLovinSDK lookup/dlopen when present
           -> UnityFramework lookup/dlopen when present
        -> schedule ready block on main queue
           -> B_debug: show floating entry directly
           -> A_customer: status UI + ZONStartCustomerAuthorization()
        -> ZONLoadBundledModules()
```

Startup order is intentionally sensitive. Structural refactors must not reorder `+load`, preflight, customer authorization, or module loading without a dedicated device gate.

## Customer authorization data flow
```text
ZONStartCustomerAuthorization
  -> Keychain DZUDID exists?
       yes -> continue
       no  -> ZonoeCurrentUDID bridge cache?
                yes -> continue
                no  -> ZonoeSetUDIDCallback + ZonoeRequestUDIDIfNeeded
  -> persist/verify DZUDID
  -> purge obsolete AuthV2/legacy persistent residue
  -> ZONAuthV2Flow.start(udid)
       -> GET /index/index/apiface?udid=...
       -> classify: active / missing / expired / blocked / unknown
       -> active: Runtime Config -> Verify v2
       -> missing/expired: card prompt -> pre-license -> /appstore -> post-license gate
                          -> Runtime Config -> Verify v2
       -> Verify success
            -> session lastVerify/access_level/permissions
            -> notice/update presentation
            -> show floating icon
```

Important ownership rule: `/apiface` owns device activation state; Verify owns current-App applicability, `access_level`, and `permissions`.

## Menu architecture
```text
floating entry
  -> PopupMenuVC compatibility shell
  -> ZONMenuCoordinator
       -> ZONMenuPanelController
       -> ZONMenuChromeRenderer
       -> ZONSectionRenderer
            -> ZONFeatureRegistry
            -> server permission filtering
            -> ZONFeatureRenderer
       -> ZONMenuEventBridge
            -> ZONFeatureDispatcher
                 -> ZONSixButtonActionService
                 -> ZONLocalFilesCoordinator
                 -> ZONResetCoordinator
                 -> runtime UserDefaults + ImgTool side effects
                 -> P79.8d passive injected-dylib trigger
```

`ZONFeatureRegistry` is the current source of truth for menu feature identifiers, legacy tags, sections, risk, migration ownership, and server-required permissions. It is currently dictionary/string-key based rather than strongly typed.

## Business-service layer
Primary service/coordinator boundaries under `testmod/ZONServices/` include:
- authorization and UDID coordination;
- remote/cloud save transfer;
- backup and local restore;
- local file browsing;
- reset/clear-data/clear-authorization;
- runtime-directory ownership;
- launch tracing.

The menu dispatcher should remain a routing boundary; business implementation belongs in these services/coordinators.

## External dylib mechanisms
There are currently two distinct mechanisms and they must not be conflated.

### Formal bundled modules
```text
ZONBootstrap
  -> ZONModuleLoader
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted .dylib enumeration
     -> containment check
     -> dlopen(RTLD_NOW | RTLD_LOCAL)
     -> dlsym zonoe_module_abi_version / identifier / initialize
     -> ABI check
     -> initialize(ZONHostAPI)
```

The host owns loading and successful modules remain loaded for process lifetime.

### P79.8d passive injected module
```text
external injector loads passive dylib
  -> runtime.iap-noads switch ON
     -> enumerate already-loaded dyld images
     -> accept known passive image names
     -> validate Mach-O + 0x847C RET signature
     -> validate 0x888C init prologue
     -> arm64e PAC-sign function pointer when required
     -> call image base + 0x888C on main thread
     -> one-shot latch per process
```

The host does **not** call `dlopen`/`dlclose` for this passive module. Missing/invalid passive dylib does not roll back the existing IAP/no-ads toggle.

## Current persistence model
- Long-lived authorization identity: Keychain `DZUDID`.
- AuthV2 card/config/verify/bootstrap/activation state: process memory only.
- Persistent AuthV2 default: `zonoe.auth.v2.lastNoticeFingerprint` only.
- Existing menu/runtime preference keys remain persistent and are intentionally unchanged.

## Current server permission model
- `basic`: normal menu only; no `extra_menu` / `extra_features`.
- `app_plus`: normal + extra menu/features.
- `global_plus`: normal + extra menu/features.
- `VIP云存档` requires `extra_menu` for rendering and `extra_features` for action; the actual download path performs a fresh Verify before resolving/downloading the archive.

## Verification architecture
P79.8e makes the active P79 workflow sensitive to `ZONCore`, `ZONServices`, project-file and current contract-test changes. It runs:
1. P79 isolation checks;
2. current Dispatcher service-routing contract;
3. P79.8d passive-dylib runtime contract;
4. Xcode 16.4 device build for `arm64 + arm64e`.

P79.8e CI Run `36718795572` / #40 succeeded. Raw P79.8e dylib is byte-for-byte identical to the P79.8d raw dylib (SHA256 `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`).

## Protected behavior
Until a dedicated stage proves otherwise, preserve:
- `main.m +load` and bootstrap ordering;
- DZUDID/keychain and UDID bridge semantics;
- P79.8a UDID-first authorization decision rules;
- P79.8b persistence cleanup contract;
- P79.8c server-driven cloud permission gates;
- P79.8d passive-dylib names/signatures/RVAs, PAC, main-thread and one-shot semantics;
- menu feature identifiers/legacy tags and runtime preference keys;
- module-loader ABI, directories, containment checks and process-lifetime ownership.
