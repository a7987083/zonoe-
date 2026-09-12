# KNOWN_ISSUES

## Current

### v1_p32 Dispatcher split validation pending
- Seven Dispatcher bodies have been moved from the header into `ZONFeatureDispatcher.m` on the p32-B work branch.
- PBX registration and full A/B compilation have not yet been proven at this source commit.
- Risk: linkage/target-registration failure or accidental drift during body movement.
- Mitigation: p31 source-equivalence check, Dispatcher contract smoke, Registry/Module ABI smokes, PBX registration assertion and A/B Xcode build.
- Device-verified baseline remains p31 until CI and real-device p32 regression pass.

### Dispatcher protected-path regression risk
- Even after CI, cloud save, local files, backup/restore, destructive confirmation boundaries and runtime toggles require real-device validation because static/source equivalence cannot prove UIKit presentation/runtime integration.
- Destructive clear actions should be tested only to the confirmation/cancel boundary unless intentional deletion is desired.

### ModuleLoader duplicate/dead-path structure
- Legacy/duplicate `ZONModuleLoader.h` copies remain; active target does not use ModuleLoader.
- Do not force it into the target without a real runtime requirement.

## Closed

### p32 Dispatcher boundary ambiguity
- Closed by p32-A Run `34703403975`; active ownership is unambiguous.

### v1_p31 cumulative device regression
- Closed; `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` is the current device-verified baseline.

### p31 Registry data-change risk
- Closed by Registry equivalence and smoke CI.
