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

## Compilation boundary after v1_p31
```text
Xcode target: testmod
  -> PopupMenuVC.m
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
  -> ZONFeatureRegistry.m
```

`ZONFeatureRegistry.h` now exposes enums, exported key declarations and registry function declarations only. Registry key definitions, 3 section records, 10 feature records and lookup/validation functions live in `ZONFeatureRegistry.m`.

Still header-based / intentionally not converted:
- `ZONFeatureDispatcher.h`: business-heavy boundary; directly owns protected cloud-save, clear-game-data and clear-authorization routes.
- `ZONModuleLoader.h`: audited in p31 but not part of the active target runtime; actual `testmod/Bsphp/main.m` does not reference it and `project.pbxproj` has no ModuleLoader source entry. Do not force it into the product target without a real runtime requirement.

## p31 invariants
- Registry data is unchanged: 10 features and 3 sections with the same tags, identifiers, titles, risk/migrated values, ordering, state keys and renderers.
- No Dispatcher function-body or protected business-handler change.
- No EventBridge behavior change.
- No UI geometry/color/text/animation change.
- No authorization, UDID, cloud-save or clear-game-data behavior change.
- No actual `testmod/Bsphp/main.m` change.

## Runtime baseline
`v1_p31` source commit `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` is the current device-verified baseline. The user reported the cumulative p29 + p30 + p31 real-device regression passed with no issues, so the pending p29/p30 hardware gates are closed by that same regression.
