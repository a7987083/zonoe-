# v1_p32 Dispatcher Boundary Audit

## Baseline
- Device-verified baseline: `v1_p31`.
- Product source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- Audit branch: `work/zonoemenu-v1-p32-dispatcher-audit`.
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Audit workflow: `p32 Dispatcher Boundary Audit` / Run `34703403975` / `success`.
- Audit phase made no changes under `testmod/`, `testmod.xcodeproj/project.pbxproj` or `VERSION`.

## Active compilation ownership
The active Xcode target compiles `testmod/ZONCore/ZONMenuEventBridge.m` and `testmod/ZONCore/ZONFeatureRegistry.m`. There is no `ZONFeatureDispatcher.m` entry in the target.

`ZONMenuEventBridge.m` imports `ZONFeatureDispatcher.h`, so the Dispatcher's `static inline` function bodies are currently compiled into the EventBridge translation unit. This is an active runtime boundary, not a dead/duplicate path.

## Dispatcher implementation inventory
`testmod/ZONCore/ZONFeatureDispatcher.h` currently owns seven inline functions:
1. `ZONTmpDirectoryPath`
2. `ZONEnsureTmpDirectory`
3. `ZONClearGameDataPreservingTmp`
4. `ZONPresentClearGameDataConfirmation`
5. `ZONPresentClearAuthorizationConfirmation`
6. `ZONDispatchMigratedActionForLegacyTag`
7. `ZONDispatchMigratedToggleForLegacyTag`

## Action routes that must remain equivalent
- `base.remote-download` -> `PubgLoad.yuanchengdwon`
- `base.cloud-save` -> ensure sandbox tmp exists -> `PubgLoad.checkCloudSaveStatus`
- `base.local-files` -> present `SandboxBrowserVC` inside a navigation controller
- `data.backup-save` -> `daochucd.backupasd`
- `data.restore-save` -> `YYYPicker.addBtnAction`
- `data.clear-game-data` -> destructive confirmation -> delayed local data cleanup -> `exit(0)`
- `auth.clear-records` -> destructive confirmation -> `WX_NongShiFu123.deletekm` -> delayed `exit(0)`

## Toggle routes that must remain equivalent
- `runtime.iap-noads` -> persist `NNGG` / `NNGGNNGG` -> `ImgTool.NeiGou`
- `runtime.ad-speed` -> persist `AADD` / `AADDAADD` -> `ImgTool.ADSpeed`
- `runtime.placeholder-203` -> current placeholder log only

`ZONMenuEventBridge.m` remains the owner of ad-speed numeric persistence (`AADDssppeedd`) and runtime synchronization to `ImgTool.NeiGou`, `ImgTool.ADSpeed` and `ImgTool.ADBiansu`.

## Protected invariants
A source split must not change:
- cloud-save tmp-directory self-heal before cloud status handling;
- clear-game confirmation text/boundary, tmp preservation, Documents/Library/defaults cleanup or delayed exit behavior;
- clear-authorization confirmation boundary, `deletekm` handoff or delayed exit behavior;
- registry identifiers or route order;
- legacy UserDefaults keys;
- `ImgTool` runtime side effects;
- local-files presentation semantics;
- EventBridge slider persistence/runtime-sync ownership.

## Automated audit result
`Tests/dispatcher_boundary_audit.py` proved the active target topology, seven-function inventory, seven action routes, three toggle routes and protected markers. `.github/workflows/p32-dispatcher-audit.yml` additionally proved the audit commit had no product-source diff from the p31 device-verified commit. Run `34703403975` completed successfully.

## Split decision
**Approved for p32-B mechanical split.** The audit found no inactive/duplicate Dispatcher ambiguity. The split must remain behavior-preserving and isolated from business refactoring.

## Next Task
Move the seven function bodies into `ZONFeatureDispatcher.m`, leave declarations in `ZONFeatureDispatcher.h`, register the `.m` in the Xcode target, prove source/route equivalence, build A/B variants, then hand out A_customer for device regression.
