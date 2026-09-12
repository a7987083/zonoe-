# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p30-eventbridge-boundary`
- Current version: `v1_p30`
- Current device-verified baseline: `v1_p28` / `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- p29 source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e` (device verification still pending)
- p30 source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`

## Current phase — v1_p30 EventBridge Boundary Cleanup
p30 converts `ZONMenuEventBridge` from a header-only `static inline` implementation into a declaration-only header plus an independent Objective-C translation unit.

Changes:
- `VERSION`: `v1_p29` -> `v1_p30`.
- `ZONMenuEventBridge.h`: declarations only; no longer imports Dispatcher/ImgTool implementation dependencies.
- Added `ZONMenuEventBridge.m` with the existing EventBridge function bodies and UserDefaults keys.
- Registered `ZONMenuEventBridge.m` in the Xcode target Sources phase.

Intentionally untouched:
- `ZONFeatureDispatcher.h` and all Dispatcher business handlers.
- `ZONFeatureRegistry.h` data.
- `ZONModuleLoader.h`.
- authorization / BS-PHP, UDID, VIP cloud save, clear-game-data.
- `WX_NongShiFu123.mm`, `main.m`, AppDelegate / SceneDelegate.
- UI style, dimensions, colors, text and spacing.
- keyboard/presentation logic.

## Source commits
- EventBridge source split: `760f03f511005f639f9a7a1de8aaad6f02f85c9a`.
- PBX integration / p30 source head: `8e88b63611d19af6c42d9172c0f5741b34f51809`.

p29-docs-head -> p30 source diff is exactly:
- `VERSION`
- `testmod.xcodeproj/project.pbxproj`
- `testmod/ZONCore/ZONMenuEventBridge.h`
- `testmod/ZONCore/ZONMenuEventBridge.m`

## v1_p30 CI verification
- Workflow: `p30 EventBridge Boundary Build`
- Successful Run ID: `34672196947`
- Validation branch: `test/zonoemenu-v1-p30-build`
- Validation workflow commit: `e1ed9d36adf3bf268ae2cb7f287e607046bf611b`
- Result: success
- Xcode: 16.4
- Deployment target: iOS 12.0
- Architectures: arm64 + arm64e

### A_customer
- Artifact: `testmod-v1_p30-A_customer`
- Artifact ID: `10291256225`
- Artifact ZIP SHA256: `e25fab0249f3a87fc4db849c2199006f6ba89a203ba03c596207a7208b2f755a`
- Dylib SHA256: `383fdab525bbdb1cdfced50288c1ac5b8acfbfdbe8419802fdc29b735095133a`

### B_debug
- Artifact: `testmod-v1_p30-B_debug`
- Artifact ID: `10290359063`
- Artifact ZIP SHA256: `6a245b6aa0bf85468bb14a8c9a049c803dd5ba64649e19c8e94ad18b5ec0a31c`
- Dylib SHA256: `2eb3c8693b6836feb926dbbf587b54125892b025c17fdb026c6b32c7e371accf`

Both variants passed protected-source verification, compile, link, dylib packaging and universal arm64/arm64e Mach-O verification.

## Validation note
The first p30 CI run failed before compilation because the build checkout was shallow and the protection assertion referenced the p29 commit. The assertion was fixed by using full history and the correct `git diff --exit-code` ordering. No p30 source file changed as part of that CI-only correction.

## Runtime verification state
- `v1_p28`: device/runtime verified; current fallback baseline.
- `v1_p29`: CI verified, hardware regression not explicitly confirmed.
- `v1_p30`: CI verified, hardware regression pending.

Because p30 is built on top of p29, the next hardware test must cover both the p29 Renderer/Panel boundary changes and the p30 EventBridge boundary change before either is promoted above p28.

## Current compile relationship
```text
ZONMenuCoordinator.m
  -> ZONMenuPanelController.h
  -> ZONMenuChromeRenderer.h
  -> ZONSectionRenderer.h
       -> ZONFeatureRenderer.h
  -> ZONMenuEventBridge.h
       -> implemented by ZONMenuEventBridge.m
           -> ZONFeatureDispatcher.h
           -> ImgTool.h

Xcode target Sources
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
```

## Next task
Device-regression-test `v1_p30` A_customer. Focus on menu open/close, section fold/relayout, card/grid actions, switches, ad-speed slider/runtime synchronization, plus protected action paths. If it passes, p30 can become the new device-verified baseline and p29 is implicitly covered by the same test.
