# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p32-dispatcher-audit`
- Runtime version/baseline: `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` (device verified)
- Current development phase: `v1_p32-A Dispatcher Boundary Audit`

## Current context
p31 is fully CI- and device-verified. p32 starts with a non-runtime audit because the remaining `ZONFeatureDispatcher.h` boundary directly owns cloud-save, destructive cleanup, authorization deletion and runtime-toggle side effects.

The p32-A branch intentionally does not change `testmod/`, `testmod.xcodeproj/project.pbxproj` or `VERSION`. Its purpose is to prove the live call chain and freeze the invariants that a later split must preserve.

## Active Dispatcher ownership
- Xcode target compiles `testmod/ZONCore/ZONMenuEventBridge.m`.
- `ZONMenuEventBridge.m` imports `ZONFeatureDispatcher.h`.
- Xcode target does not currently register `ZONFeatureDispatcher.m`.
- Therefore all seven `static inline` Dispatcher bodies are compiled into the EventBridge translation unit.

Detailed audit: `DISPATCHER_AUDIT.md`.
Automated audit: `Tests/dispatcher_boundary_audit.py`.
CI workflow: `.github/workflows/p32-dispatcher-audit.yml`.

## Dispatcher-owned behavior that must not drift
- Actions: remote download, cloud save, local files, backup, restore, clear game data, clear authorization.
- Toggles: IAP/no-ads, ad-speed enable, placeholder 203.
- Persistent keys: `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`.
- EventBridge-owned numeric speed key remains `AADDssppeedd`.
- Runtime side effects remain `ImgTool.NeiGou`, `ImgTool.ADSpeed`, `ImgTool.ADBiansu`.
- Cloud save must self-heal sandbox `tmp` before status handling.
- Destructive routes must retain confirmation boundaries and delayed exit behavior.

## Risk
`ZONFeatureDispatcher.h` is business-heavy. A mechanical header-to-implementation split is acceptable only if the route strings, call targets, confirmation/destructive flow and runtime side effects remain identical. Do not mix business cleanup/refactoring into the split.

## Verification policy
- p32-A: static/topology audit only; product source must remain byte-identical to p31 baseline through the protected product paths.
- p32-B: source split must get isolated source-equivalence checks plus full A/B Xcode builds.
- CI success is not device verification. Any p32 A_customer runtime candidate requires a real-device checklist and explicit user pass before baseline promotion.

## Current compile relationship
```text
ZONMenuCoordinator.m
  -> ZONMenuEventBridge.m
       -> imports ZONFeatureDispatcher.h (7 inline bodies)
       -> ImgTool runtime sync

Xcode target Sources
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
  -> ZONFeatureRegistry.m
  -> no ZONFeatureDispatcher.m yet
```

## Next task
Run/verify `p32 Dispatcher Boundary Audit`. If green, start p32-B by moving only the seven Dispatcher bodies into an independent `.m`, registering it in the target, and building A/B variants before any real-device handoff.
