# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p32`.
- Source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- CI Run `34723015809`: success.
- Real-device regression: passed.

## Current development candidate — v1_p33
Status: `ci_verified_device_pending`.

### Goal
Make active startup/module-loader compilation ownership explicit without changing behavior.

### Implemented
- `VERSION`: `v1_p32` -> `v1_p33`.
- `ZONBootstrap.h` declaration-only + new `ZONBootstrap.m`.
- `ZONModuleLoader.h` declaration-only + new `ZONModuleLoader.m`.
- Both `.m` files registered in the Xcode target.
- Added `Tests/bootstrap_moduleloader_contract.py` and permanent CI coverage.
- Corrected architecture documentation: ModuleLoader is active through Bootstrap.

### Verification completed
- Exact moved-body equivalence against p32.
- Protected source-scope check.
- PBX registration.
- Independent compile/symbol checks.
- Dispatcher contract, Registry smoke and Module ABI smoke.
- A_customer and B_debug full iOS 12 arm64/arm64e builds.
- Run `34733013479`: success.

### Promotion gate
P33 requires A_customer real-device startup/bootstrap regression before it can replace p32 as the promoted baseline.

## Refactor backlog after p33 promotion
1. Canonical-source audit: root duplicate trees vs active `testmod/`; establish/remove legacy copies only after PBX/reference proof.
2. UDID boundary audit: lock `ZONUDIDBridge` state machine and `ZonoeUDIDAPI` behavior before moving implementation out of headers/UI category.
3. Repository hygiene: generated binaries, packages and Xcode user state in an isolated no-runtime-change cleanup.
4. Large legacy-file audits (`jianghu.*`, `WX_NongShiFu123.mm`, `DLGMemUIView.m`, `PubgLoad.mm`) before any split.
5. Add startup timing/signposts before changing `+load`, preflight or module-loading threading.

## Next task
Complete the v1_p33 device checklist in `DEVICE_TEST_MATRIX.md`. If passed, promote p33; otherwise fall back to p32 and investigate only the failed startup boundary.
