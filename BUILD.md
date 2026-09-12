# BUILD

## Current build
- Project: `testmod.xcodeproj`
- Target/product: `testmod` / `testmod.dylib`
- CI Xcode: 16.4
- Minimum validated deployment target: iOS 12.0
- Architectures: arm64 + arm64e

## ZONCore target sources after v1_p29
The target now compiles these ZONCore implementation files independently:
- `ZONMenuCoordinator.m`
- `ZONMenuPanelController.m`
- `ZONMenuChromeRenderer.m`
- `ZONFeatureRenderer.m`
- `ZONSectionRenderer.m`

`ZONFeatureRegistry`, `ZONFeatureDispatcher`, `ZONMenuEventBridge` and `ZONModuleLoader` remain header-based and were intentionally excluded from p29.

## Latest v1_p29 verification
- Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`
- Workflow: `p29 Render Boundary Build`
- Run ID: `34671336051`
- Validation branch: `test/zonoemenu-v1-p29-build-verify`
- Result: success

A_customer:
- Artifact ID: `10291080372`
- ZIP SHA256: `c60f650142890d5ebb51c232b5920b59a46b30fff215751086965f2a1c658315`
- dylib SHA256: `3c6a15f17e44a681e0fa8eae6356c42df52fa7a1182dfd748baadb621fcb345a`

B_debug:
- Artifact ID: `10291205155`
- ZIP SHA256: `aece191a32982d91922b1c266eba44b68c990b8fb67484fd415313824115701d`
- dylib SHA256: `b475bf5533daf73dc5aea2a004dda6174b75365b8c3cb732309fbd0160a9eca7`

Both builds passed compilation, linking, dylib packaging and universal arm64/arm64e Mach-O verification.

## Device baseline
- Current device-verified version: `v1_p28`
- Device-verified source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- `v1_p29` remains runtime-pending until hardware regression is confirmed.
