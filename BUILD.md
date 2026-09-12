# BUILD

## Current build
- Project: `testmod.xcodeproj`
- Target/product: `testmod` / `testmod.dylib`
- CI Xcode: 16.4
- Minimum validated deployment target: iOS 12.0
- Architectures: arm64 + arm64e

## ZONCore target sources after v1_p31
The target independently compiles:
- `ZONMenuCoordinator.m`
- `ZONMenuPanelController.m`
- `ZONMenuChromeRenderer.m`
- `ZONFeatureRenderer.m`
- `ZONSectionRenderer.m`
- `ZONMenuEventBridge.m`
- `ZONFeatureRegistry.m`

`ZONFeatureDispatcher.h` remains header-based because it owns protected business behavior. `ZONModuleLoader` was audited but is not on the actual target runtime path and was not added to the target.

## Latest v1_p31 verification
- Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`
- Workflow: `p31 Registry Boundary Build`
- Run ID: `34673034214`
- Validation branch: `test/zonoemenu-v1-p31-registry-build`
- Validation workflow commit: `57dbc4eca5131f9c0496806a9bd68d2d5f3eb716`
- Result: success

Additional pre-build validation:
- Registry dictionary data equivalence vs p30: success.
- Registry key name/value equivalence vs p30: success.
- `feature_registry_smoke`: success under `-Wall -Wextra -Werror`.
- Module ABI smoke and required export checks: success.

A_customer:
- Artifact ID: `10291681640`
- ZIP SHA256: `5f1e106ef2d8a861b75ecaa7e7d44ca83b2c992122aa03e681ec399cc6ae9602`
- dylib SHA256: `579d721b6f2cfcb89b711ad676632851c84173d65f872259d26553bf180b6b68`

B_debug:
- Artifact ID: `10291566984`
- ZIP SHA256: `c2b8b9b15d8dc732bf208f7d06d1edec1c74f5811ca8426305568ed2d3b312d6`
- dylib SHA256: `ffe787f48c0ed5e6e3862692ccf279879831257ccdd7a8946af239d405927743`

Both variants passed source-protection checks, compilation, linking, dylib packaging and universal arm64/arm64e Mach-O verification.

## Device baseline
- Current device-verified version: `v1_p28`
- Device-verified source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- `v1_p29`, `v1_p30` and `v1_p31` remain runtime-pending.
- A successful p31 cumulative hardware checklist from `DEVICE_TEST_MATRIX.md` will cover p29+p30+p31 and allow p31 promotion.
