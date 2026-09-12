# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p29-render-boundary`
- Current version: `v1_p29`
- p28 source commit / current device-verified baseline: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- p29 source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`

## Device-verified baseline — v1_p28
The user completed p28 device/runtime regression with no reported issues. `v1_p28` remains the current device-verified baseline until p29 passes the same hardware regression.

## Current phase — v1_p29 Rendering Boundary Cleanup
p29 converts four menu/render helpers from header-only `static inline` implementations into normal Objective-C translation units while preserving their existing function signatures, function bodies, UI constants and call flow.

Split modules:
1. `ZONMenuPanelController.h` + new `ZONMenuPanelController.m`
2. `ZONMenuChromeRenderer.h` + new `ZONMenuChromeRenderer.m`
3. `ZONFeatureRenderer.h` + new `ZONFeatureRenderer.m`
4. `ZONSectionRenderer.h` + new `ZONSectionRenderer.m`

All four `.m` files are registered in `testmod.xcodeproj/project.pbxproj` and compiled independently by target `testmod`.

p29 intentionally does not modify:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONMenuEventBridge.h`
- `ZONModuleLoader.h`
- authorization / BS-PHP
- UDID
- VIP cloud save
- clear-game-data
- `WX_NongShiFu123.mm`
- `main.m`
- AppDelegate / SceneDelegate
- Feature Registry data
- Dispatcher business handlers
- UI style, dimensions, colors, text or spacing
- keyboard/presentation logic

## Source commits
- Source split: `aca50911e66b6d91313ab990746a658b28f04066`
- PBX target integration / p29 source head: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`

Source-only p28-docs-head -> p29 source diff is limited to:
- `VERSION`
- `testmod.xcodeproj/project.pbxproj`
- the four target headers
- the four new target `.m` files

No protected business source file is part of the p29 source diff.

## v1_p29 CI verification
- Workflow: `p29 Render Boundary Build`
- Run ID: `34671336051`
- Validation branch: `test/zonoemenu-v1-p29-build-verify`
- Validation workflow commit: `0c346ce3eb4c2dab4fc43a6e48c2c90be9bf0bd9`
- Result: success
- Xcode: 16.4
- Deployment target: iOS 12.0
- Architectures: arm64 + arm64e

### A_customer
- Result: success
- Artifact: `testmod-v1_p29-A_customer`
- Artifact ID: `10291080372`
- Artifact ZIP SHA256: `c60f650142890d5ebb51c232b5920b59a46b30fff215751086965f2a1c658315`
- Dylib SHA256: `3c6a15f17e44a681e0fa8eae6356c42df52fa7a1182dfd748baadb621fcb345a`

### B_debug
- Result: success
- Artifact: `testmod-v1_p29-B_debug`
- Artifact ID: `10291205155`
- Artifact ZIP SHA256: `aece191a32982d91922b1c266eba44b68c990b8fb67484fd415313824115701d`
- Dylib SHA256: `b475bf5533daf73dc5aea2a004dda6174b75365b8c3cb732309fbd0160a9eca7`

Both variants passed source verification, compile, link, dylib packaging, Mach-O verification and artifact upload. No undefined-symbol or duplicate-symbol regression occurred.

An initial test-only workflow revision failed YAML validation before GitHub created any job. It did not modify the p29 work branch. The workflow was corrected before source integration and build verification.

## Runtime verification state
- `v1_p28`: device/runtime verified; current baseline.
- `v1_p29`: source/static/CI verified; device/runtime regression pending.
- Do not promote p29 as the device baseline until the user confirms the A_customer build on hardware.

## Current compile relationship
```text
ZONMenuCoordinator.m
  -> ZONMenuPanelController.h
  -> ZONMenuChromeRenderer.h
  -> ZONSectionRenderer.h
       -> ZONFeatureRenderer.h

Xcode target Sources
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
```

## Next task
Device-regression-test `v1_p29` A_customer against the device-verified `v1_p28` baseline. Focus on menu open/close, section fold/relayout, card/grid buttons, switches/ad-speed slider, and confirm protected business paths show no regression.
