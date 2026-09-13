# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p33-bootstrap-moduleloader-boundary`.
- Current development version: `v1_p33`.
- Current p33 source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- Device-verified baseline remains `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3` until p33 device regression passes.

## p33 scope
P33 is an isolated compilation-ownership refactor of the active startup/module-loader path:
- `ZONBootstrap.h` -> declaration-only; implementation moved to `ZONBootstrap.m`.
- `ZONModuleLoader.h` -> declaration-only; implementation moved to `ZONModuleLoader.m`.
- Both `.m` files are registered in `testmod.xcodeproj`.
- No intended authorization, UDID, menu, Dispatcher, route, persistence, UI, module ABI or module-loading behavior change.

Important correction: ModuleLoader is active. `main.m` calls `ZONBootstrapStart()`, and Bootstrap calls `ZONLoadBundledModules()`. Older documentation saying it was inactive was based on the absence of an independent `.m` target entry and was incorrect because its implementation was header-owned.

## Verification
- Source/body equivalence against p32: passed for Bootstrap and all ModuleLoader functions.
- Isolated product-source scope: passed.
- PBX registration: passed.
- Independent `.m` compilation with warnings-as-errors: passed.
- Required symbol checks: passed.
- Dispatcher contract: passed.
- Feature Registry smoke: passed.
- Module ABI smoke/example exports: passed.
- A_customer and B_debug full Xcode build/package, iOS 12 / arm64 + arm64e: passed.
- Workflow: `p33 Bootstrap ModuleLoader Boundary Build` / Run `34733013479` / success.
- A artifact: `testmod-v1_p33-A_customer` / ID `10309833185`.
- B artifact: `testmod-v1_p33-B_debug` / ID `10309663469`.
- Real-device p33 validation: pending.

## Architecture review findings
See `REFACTOR_REVIEW.md`. Highest remaining risks are canonical-source ambiguity between root and `testmod/`, the implementation-heavy active `ZONUDIDBridge.h`, and UDID/auth plumbing living inside `NSObject+UI.m`.

## Next task
Run the p33 A_customer real-device startup/bootstrap checklist from `DEVICE_TEST_MATRIX.md`. Do not promote p33 or start an auth/UDID structural refactor until that result is recorded.
