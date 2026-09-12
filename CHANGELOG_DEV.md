# CHANGELOG_DEV

## 2026-09-12 — v1_p29 Rendering Boundary Cleanup
- Baseline: device-verified `v1_p28` source commit `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- Bumped `VERSION` to `v1_p29`.
- Converted `ZONMenuPanelController`, `ZONMenuChromeRenderer`, `ZONFeatureRenderer`, and `ZONSectionRenderer` from header-only static-inline implementation to declaration headers plus independent `.m` translation units.
- Registered all four new `.m` files in the Xcode target Sources phase.
- Preserved existing helper signatures, function bodies, UI geometry, colors, text, animation values, UserDefaults keys and dispatch flow.
- Did not modify Registry data, Dispatcher business behavior, EventBridge, ModuleLoader, authorization, UDID, cloud save, clear-game-data, `WX_NongShiFu123.mm`, `main.m`, or keyboard/presentation logic.
- Source split commit: `aca50911e66b6d91313ab990746a658b28f04066`.
- Integrated p29 source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- CI run `34671336051`: A_customer and B_debug both passed compile/link/package and arm64+arm64e verification.
- A dylib SHA256: `3c6a15f17e44a681e0fa8eae6356c42df52fa7a1182dfd748baadb621fcb345a`.
- B dylib SHA256: `b475bf5533daf73dc5aea2a004dda6174b75365b8c3cb732309fbd0160a9eca7`.
- Device/runtime regression is pending; p28 remains the device-verified baseline.
- An initial test-only workflow YAML revision failed before any job was created; it was corrected with no p29 source impact.

## 2026-09-12 — v1_p28 ZONCore Build Integration
- Registered `ZONMenuCoordinator.m` as a normal Xcode target source and removed the temporary direct `.m` import bridge.
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- A/B CI passed and the user subsequently completed device regression with no issues.
- p28 is the current device-verified baseline.

## 2026-09-12 — v1_p27 Post-Refactor Cleanup
- Made `ZONMenuCoordinator.h` interface-only and moved implementation/private dependencies to `ZONMenuCoordinator.m`.
- A/B CI and device regression passed.
