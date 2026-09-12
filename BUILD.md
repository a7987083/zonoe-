# BUILD

## Current build
- Project: `testmod.xcodeproj`
- Target/product: `testmod` / `testmod.dylib`
- CI Xcode: 16.4
- Minimum validated deployment target: iOS 12.0
- Architectures: arm64 + arm64e

## ZONCore target sources after v1_p30
The target independently compiles:
- `ZONMenuCoordinator.m`
- `ZONMenuPanelController.m`
- `ZONMenuChromeRenderer.m`
- `ZONFeatureRenderer.m`
- `ZONSectionRenderer.m`
- `ZONMenuEventBridge.m`

Still header-based by design after p30:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONModuleLoader.h`

## Latest v1_p30 verification
- Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`
- Workflow: `p30 EventBridge Boundary Build`
- Successful Run ID: `34672196947`
- Validation branch: `test/zonoemenu-v1-p30-build`
- Result: success

A_customer:
- Artifact ID: `10291256225`
- ZIP SHA256: `e25fab0249f3a87fc4db849c2199006f6ba89a203ba03c596207a7208b2f755a`
- dylib SHA256: `383fdab525bbdb1cdfced50288c1ac5b8acfbfdbe8419802fdc29b735095133a`

B_debug:
- Artifact ID: `10290359063`
- ZIP SHA256: `6a245b6aa0bf85468bb14a8c9a049c803dd5ba64649e19c8e94ad18b5ec0a31c`
- dylib SHA256: `2eb3c8693b6836feb926dbbf587b54125892b025c17fdb026c6b32c7e371accf`

Both builds passed source-protection checks, compilation, linking, dylib packaging and universal arm64/arm64e Mach-O verification.

## Device baseline
- Current device-verified version: `v1_p28`
- Device-verified source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- `v1_p29` and `v1_p30` are CI-verified but runtime-pending until the current A_customer build is confirmed on hardware.
