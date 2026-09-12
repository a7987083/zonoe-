# KNOWN_ISSUES

## Current

### v1_p31 cumulative device regression pending
- Severity: validation gate, not a known defect.
- `v1_p31` passed Registry data-equivalence checks, Registry smoke, Module ABI smoke, A/B CI and universal Mach-O verification.
- `v1_p29` and `v1_p30` were also CI-verified but were not explicitly hardware-confirmed before p31 development continued.
- Therefore the p31 real-device checklist intentionally includes the pending p29 Renderer/Panel and p30 EventBridge regression scope.
- Until the user explicitly reports the cumulative p31 checklist passed, `v1_p28` / `350a46deb089a05fc599e641bd1eeb419c36c0d5` remains the device-verified fallback baseline.

### Remaining business-heavy header boundary
- `ZONFeatureDispatcher.h` remains header-based.
- It directly owns protected business paths including cloud save, clear-game-data and clear-authorization.
- Do not convert or alter it as part of unrelated cleanup; any future Dispatcher work needs its own source audit, tests and explicit protected-path regression plan.

### ModuleLoader duplicate/dead-path structure
- The repository contains legacy/duplicate `ZONModuleLoader.h` copies under root `ZONCore/` and `testmod/ZONCore/`.
- The actual target compiles `testmod/Bsphp/main.m`, which does not reference ModuleLoader, and current `project.pbxproj` has no ModuleLoader source entry.
- This is a maintenance/dead-path issue, not a current runtime defect. Do not force an inactive Loader implementation into the product target solely for structural symmetry.

## Closed

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
