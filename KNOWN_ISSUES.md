# KNOWN_ISSUES

## Current

### Dispatcher source-split risk
- p32-A proved `testmod/ZONCore/ZONFeatureDispatcher.h` is an active header-only boundary compiled through `ZONMenuEventBridge.m`.
- Audit Run `34703403975` passed and confirmed no product-source change from the p31 device baseline.
- Remaining risk is the p32-B mechanical move itself: symbol/linkage mistakes or accidental behavior drift while moving seven function bodies to a `.m` file.
- Protected behavior includes cloud-save tmp self-heal, clear-game-data cleanup, clear-authorization deletion, legacy persistence keys and `ImgTool` runtime side effects.
- Required mitigation: exact source/route invariant checks, PBX registration check, full A/B build, then real-device protected-path regression.
- Do not combine business refactoring with the split.

### ModuleLoader duplicate/dead-path structure
- The repository contains legacy/duplicate `ZONModuleLoader.h` copies under root `ZONCore/` and `testmod/ZONCore/`.
- The actual target compiles `testmod/Bsphp/main.m`, which does not reference ModuleLoader, and current `project.pbxproj` has no ModuleLoader source entry.
- This is a maintenance/dead-path issue, not a current runtime defect. Do not force an inactive Loader implementation into the product target solely for structural symmetry.

## Closed

### p32 Dispatcher boundary ambiguity
- Closed by p32-A audit Run `34703403975`.
- Active ownership is unambiguous: EventBridge imports the header-only Dispatcher; no Dispatcher `.m` is currently in the target.

### v1_p31 cumulative device regression
- Closed by real-device verification; `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` is the current device-verified baseline.

### p31 Registry data-change risk
- Closed by CI with Registry equivalence and smoke tests.

### p30 first CI protection-check failure
- Cause: shallow checkout could not resolve the p29 comparison commit; successful rerun ID `34672196947`.

### p29 initial workflow YAML validation failure
- Test-only CI definition issue; no p29 source impact.

### Keyboard/presentation suspicion
- Closed as a user/test-side mistake; not a project defect.
