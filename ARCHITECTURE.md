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

## Compilation boundary after v1_p29
```text
Xcode target: testmod
  -> PopupMenuVC.m
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
```

The five listed ZONCore implementation modules are independent Objective-C translation units. Public/use-site headers now carry declarations for the p29 render/panel helpers rather than their complete implementations.

Still header-based by design after p29:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONMenuEventBridge.h`
- `ZONModuleLoader.h`

## p29 invariants
- No Feature Registry data change.
- No Dispatcher/EventBridge business behavior change.
- No UI geometry/color/text/animation change.
- No authorization, UDID, cloud-save or clear-game-data change.
- p29 is a compilation-boundary refactor only.

## Runtime baseline
`v1_p28` source commit `350a46deb089a05fc599e641bd1eeb419c36c0d5` remains the device-verified baseline until p29 device regression passes.
