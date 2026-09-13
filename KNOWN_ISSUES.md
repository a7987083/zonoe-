# KNOWN_ISSUES

## Current

### v1_p33 device validation pending
- Bootstrap/ModuleLoader compilation ownership refactor passed source-equivalence, independent compile, smoke, ABI and A/B full-build CI in Run `34733013479`.
- Real-device startup/bootstrap regression has not yet been reported.
- Device-verified fallback remains `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3`.

### Canonical source ambiguity
- Repository root and `testmod/` contain overlapping legacy source trees; some duplicate names have diverged substantially.
- `testmod/` + `testmod.xcodeproj` is the current canonical product-runtime surface, but root duplicates must be audited before removal.
- Risk: editing the wrong copy or reintroducing obsolete implementation.

### UDID implementation boundary
- `testmod/ZONServices/ZONUDIDBridge.h` still owns substantial active implementation including callback/nonce/storage/socket/request logic.
- Stable `ZonoeUDIDAPI` implementation currently lives in `NSObject+UI.m`, mixing auth/device plumbing with UI category ownership.
- Do not mechanically split this without a dedicated contract and customer real-device activation/authorization gate.

### Repository hygiene
- Generated/package binaries and Xcode user-specific state remain tracked in the repository.
- Cleanup must be isolated from runtime changes and must verify no release consumer depends on tracked outputs.

### Large legacy surfaces
- Large multi-responsibility legacy files remain. Audit call/target ownership before any split; do not perform opportunistic rewrites.

## Closed / corrected

### ModuleLoader inactive-path assumption
- Previous documentation stated ModuleLoader was inactive because there was no `.m` target entry.
- Corrected: Bootstrap actively called `ZONLoadBundledModules()` from the header-owned implementation.
- P33 makes ownership explicit through `ZONModuleLoader.m` and `ZONBootstrap.m`; CI Run `34733013479` passed. Device promotion is tracked separately above.

### v1_p32 Dispatcher split validation
- Closed by source `84f8b3898bee9d95ed4034d12842879cc56280d3`, CI Run `34723015809` and explicit real-device pass.
- `v1_p32` remains the current promoted baseline until p33 device verification.

### p31 Registry data-change risk
- Closed by Registry equivalence/smoke CI and later superseded device baselines.
