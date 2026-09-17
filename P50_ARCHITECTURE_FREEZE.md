# P50 Architecture Freeze Contract

## Baseline
P50 freezes the device-verified P49 runtime as the architectural baseline.

- Version: `v1_p49`
- Runtime commit: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`
- CI Run: `35195152912`
- Device status: passed, explicitly reported by user
- Active PBX Sources: `78`
- Architectures: `arm64 + arm64e`
- A_customer artifact: `10485344383`
- A_customer dylib SHA256: `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`
- B_debug artifact: `10485622521`

## Frozen boundaries
The following ownership boundaries are considered stable and MUST NOT be structurally changed without a new explicitly scoped stage:

1. Startup / bootstrap
   - `testmod/ZONBootstrap/`
   - `main.m +load -> ZONBootstrapStart -> authorization/module loading`
2. Authorization / UDID
   - `testmod/ZONServices/ZONAuthorizationCoordinator.*`
   - `ZONUDIDBridge.*`
   - `ZonoeUDIDAPI.*`
   - `ZONLegacyUDIDFallbackAdapter.*`
3. Feature model / dispatch
   - `testmod/ZONCore/ZONFeatureRegistry.*`
   - `testmod/ZONCore/ZONFeatureDispatcher.*`
4. Menu presentation boundary
   - `ZONMenuCoordinator`, renderers, panel/event bridge
   - UI may be replaced in a later UI-only stage, but business dispatch must remain behind Registry/Dispatcher.
5. Module loading
   - `testmod/ZONCore/ZONModuleLoader.*`
   - bundled module scan / `dlopen` ordering is frozen.
6. Persistence / save paths
   - backup, restore, cloud-save and authorization persistence semantics are frozen.
7. Hook/runtime behavior
   - existing hook entry points, ad-speed/IAP toggles and their persistence keys are frozen unless a dedicated behavior stage is opened.

## P49 dependency baseline
- `Network.framework` is deliberately absent.
- `StoreKit.framework` is deliberately absent.
- Active Sources remain `78`.
- Exported symbol surface matches the immediate promoted predecessor except where already documented in earlier stages.
- No further framework/source deletion is allowed without a new reachability proof and promotion gate.

## Change policy after P50
Allowed without reopening architecture:
- UI-only renderer/theme/layout changes that continue to consume Registry/Dispatcher.
- Documentation, tests, CI, diagnostics and observability that do not alter runtime ordering/semantics.
- Bug fixes with an explicit root-cause scope and regression contract.
- New isolated features added behind existing boundaries.

Requires a new architecture stage:
- moving startup responsibilities between `+load`, bootstrap and services;
- changing authorization continuation, timeout/retry behavior or UDID fallback order;
- bypassing Registry/Dispatcher from new UI code;
- changing module load order or `dlopen` discovery semantics;
- changing persistence keys, save locations or destructive-data behavior;
- deleting active source/framework dependencies;
- merging/splitting frozen core classes solely for code-style reasons.

## Promotion rule
P50 is a stabilization stage, not a behavior stage. Product/runtime source should remain byte-for-byte equivalent to promoted P49 unless a separate explicitly named candidate is opened. Contract CI must verify the frozen counts, absence of removed frameworks and documentation consistency.
