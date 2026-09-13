# KNOWN_ISSUES

## Current

### ModuleLoader duplicate/dead-path structure
- Legacy/duplicate `ZONModuleLoader.h` copies remain; active target does not use ModuleLoader.
- Do not force it into the target without a real runtime requirement.

## Closed

### v1_p32 Dispatcher split validation
- Closed by final source commit `84f8b3898bee9d95ed4034d12842879cc56280d3` and CI Run `34723015809`.
- Dispatcher source equivalence, PBX registration, Dispatcher contract smoke, Registry smoke, Module ABI smoke and full A/B Xcode builds passed.
- User explicitly reported the required p32 real-device checklist passed.
- `v1_p32` is the current device-verified baseline.

### Dispatcher protected-path regression risk
- Closed for p32 by real-device validation of cloud save, local files, backup/restore, destructive confirmation boundaries, runtime toggles/slider, repeated menu interaction and visual/order behavior.
- Destructive clear actions remain intended to be tested only to the confirmation/cancel boundary unless intentional deletion is required.

### p32 Dispatcher boundary ambiguity
- Closed by p32-A Run `34703403975`; active ownership is unambiguous.

### v1_p31 cumulative device regression
- Closed; `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` passed its cumulative regression and was later superseded by p32.

### p31 Registry data-change risk
- Closed by Registry equivalence and smoke CI.
