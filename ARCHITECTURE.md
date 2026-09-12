# ARCHITECTURE

## Menu ownership
```text
Floating Entry
  -> PopupMenuVC compatibility shell
     -> ZONMenuCoordinator
        -> ZONMenuPanelController
        -> ZONMenuChromeRenderer
        -> ZONSectionRenderer
           -> ZONFeatureRenderer
           -> ZONFeatureRegistry
        -> ZONMenuEventBridge
           -> ZONFeatureDispatcher
              -> existing business handlers
```

## Compilation boundary after v1_p30
```text
Xcode target: testmod
  -> PopupMenuVC.m
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
```

`ZONMenuEventBridge.h` is now declaration-only. Its implementation/private dependencies (`ZONFeatureDispatcher.h`, `ImgTool.h`, runtime UserDefaults keys) live in `ZONMenuEventBridge.m`.

Still header-based by design after p30:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONModuleLoader.h`

## p30 invariants
- No Dispatcher function-body or protected business-handler change.
- No Feature Registry data change.
- No UI geometry/color/text/animation change.
- No authorization, UDID, cloud-save or clear-game-data change.
- EventBridge action/toggle/slider/runtime-sync behavior and UserDefaults keys are preserved.

## Runtime baseline
`v1_p28` source commit `350a46deb089a05fc599e641bd1eeb419c36c0d5` remains the device-verified baseline. `v1_p29` and `v1_p30` are CI-verified but require current hardware regression before promotion.
