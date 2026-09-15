# KNOWN_ISSUES

## Current

### P41 real-device validation pending
- Candidate: `v1_p41`, product source commit `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI Run `34959813770`: **success**.
- Contract, independent bridge-TU compile, A_customer/B_debug arm64+arm64e builds, export-surface comparison and load-library comparison all passed.
- P41 moves the existing UDID bridge implementation from `ZONUDIDBridge.h` into explicit `ZONUDIDBridge.m`; active Sources intentionally increase 75 → 76.
- Remaining risk is runtime/lifecycle behavior that CI cannot prove: first-launch callback delivery, app/scene activation polling, localhost result timing, fallback behavior and authorization continuation on a real device.
- Promoted fallback remains `v1_p39` / `613882da7068795533c530d45775f7ae5f79ed56` until the user explicitly reports P41 device pass.

### ZonoeUDIDAPI ownership still mixed with UI
- The low-level `ZONUDIDBridge` implementation boundary is fixed in P41.
- The stable public `ZonoeUDIDAPI` implementation still lives in `testmod/视图菜单/NSObject+UI.m` alongside floating/menu UI behavior.
- Risk: identity/auth plumbing and UIKit ownership remain coupled at one translation-unit level.
- Do not move this API until P41 passes its real-device gate; make it a separate later phase with exact body-equivalence and another device authorization/UDID regression.

### Global startup side effects
- `testmod/Bsphp/main.m` still uses `+load`, authorization-reset compatibility replacement and synchronous startup/preflight behavior.
- Timing/order is protected behavior. Instrument before attempting any ownership or thread/timing change.

### Repository hygiene
- Generated/package binaries and some historical/redundant repository material remain tracked.
- Cleanup must stay isolated from runtime refactors and must prove no build/release consumer depends on tracked outputs.

### Large legacy surfaces
- `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m` and related legacy units still hold multiple responsibilities.
- Audit call-chain and state ownership before splitting; do not perform opportunistic rewrites.

## Closed / corrected

### ZONUDIDBridge implementation-heavy header
- Closed structurally by P41 source `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- `ZONUDIDBridge.h` is declaration-only; implementation lives in `ZONUDIDBridge.m`.
- P41 contract proves a mechanical implementation move from the P40 header.
- Run `34959813770` passed A/B builds and ABI/load-library checks.
- Runtime promotion remains separately tracked under the P41 device-validation issue above.

### Canonical product-source ambiguity
- P38 finalized the canonical active product surface under `testmod/` + `testmod.xcodeproj`; root mirrors removed in that cleanup line are no longer active product sources.
- New changes must still be verified against PBX membership rather than filenames alone.

### ModuleLoader inactive-path assumption
- Corrected in P33: Bootstrap actively called `ZONLoadBundledModules()` from header-owned implementation.
- P33 made ownership explicit through `ZONModuleLoader.m` and `ZONBootstrap.m`; later device baselines supersede the original pending status.

### v1_p32 Dispatcher split validation
- Closed by source `84f8b3898bee9d95ed4034d12842879cc56280d3`, CI Run `34723015809` and explicit real-device pass.

### p31 Registry data-change risk
- Closed by Registry equivalence/smoke CI and later superseded device baselines.
