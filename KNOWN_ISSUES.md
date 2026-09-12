# KNOWN_ISSUES

## Current

### Dispatcher business-heavy boundary — under p32 audit
- `testmod/ZONCore/ZONFeatureDispatcher.h` remains header-only and owns seven inline function bodies.
- The active target compiles those bodies through `ZONMenuEventBridge.m`; there is no `ZONFeatureDispatcher.m` target source yet.
- Protected behavior includes cloud-save tmp self-heal, clear-game-data cleanup, clear-authorization deletion, legacy persistence keys and `ImgTool` runtime side effects.
- Risk: a header-to-`.m` split can cause behavior drift if it is mixed with cleanup/refactoring.
- Mitigation added in p32-A: `DISPATCHER_AUDIT.md`, `Tests/dispatcher_boundary_audit.py`, and `p32 Dispatcher Boundary Audit` CI.
- Status: audit implementation complete; CI pending. Do not start business refactoring during the split.

### ModuleLoader duplicate/dead-path structure
- The repository contains legacy/duplicate `ZONModuleLoader.h` copies under root `ZONCore/` and `testmod/ZONCore/`.
- The actual target compiles `testmod/Bsphp/main.m`, which does not reference ModuleLoader, and current `project.pbxproj` has no ModuleLoader source entry.
- This is a maintenance/dead-path issue, not a current runtime defect. Do not force an inactive Loader implementation into the product target solely for structural symmetry.

## Closed

### v1_p31 cumulative device regression
- Closed by real-device verification: user reported the cumulative p29 + p30 + p31 checklist passed with no issues.
- `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` is the current device-verified baseline.

### p31 Registry data-change risk
- Closed by CI: p30 Registry dictionary rows and key name/value definitions were compared against p31 before smoke/build jobs.
- `feature_registry_smoke` passed with 10 features, 3 sections and unchanged tag/identifier/order/stateKey/renderer behavior.

### p30 first CI protection-check failure
- Cause: shallow checkout could not resolve the p29 comparison commit.
- No p30 source impact; successful rerun ID `34672196947`.

### p29 initial workflow YAML validation failure
- Test-only CI definition issue; no p29 source impact.

### Keyboard/presentation suspicion
- Closed as a user/test-side mistake; not a project defect.
