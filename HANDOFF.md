# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p32-dispatcher-split`
- Current source version: `v1_p32`.
- Device-verified baseline: `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3`.

## p32-A audit
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Run: `34703403975` / success.
- Detailed contract: `DISPATCHER_AUDIT.md`.

## p32-B implementation
- `ZONFeatureDispatcher.h` declares the seven Dispatcher functions and no longer contains inline bodies.
- `ZONFeatureDispatcher.m` contains the mechanically moved bodies.
- Existing header imports were retained intentionally to avoid mixing transitive-include cleanup with the source split.
- `ZONMenuEventBridge.m` remains behaviorally unchanged and still imports `ZONFeatureDispatcher.h`.
- `dispatcher_contract_smoke.py` locks route identifiers, handler calls, protected destructive markers, persistence keys and runtime-sync ownership.
- `ZONFeatureDispatcher.m` is registered in the Xcode target in final p32 source commit `84f8b3898bee9d95ed4034d12842879cc56280d3`.

## Verification result
- p31 -> p32 implementation equivalence: passed.
- Dispatcher PBX registration: passed.
- Dispatcher contract smoke: passed.
- Registry smoke: passed.
- Module ABI smoke: passed.
- A_customer and B_debug full Xcode build/package for arm64 + arm64e / iOS 12: passed.
- Build workflow: `p32 Dispatcher Boundary Build` / Run `34723015809` / success.
- A_customer artifact: `testmod-v1_p32-A_customer`.
- B_debug artifact: `testmod-v1_p32-B_debug`.
- Real-device p32 checklist: passed by explicit user report.

## Protected behavior
The p32 device regression confirmed the Dispatcher split did not introduce observed regression in cloud-save flow, local files, backup/restore, destructive confirmation boundaries, runtime toggles/slider, menu interaction or visual/order behavior.

## Current baseline rule
`v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3` is the current device-verified runtime baseline. Do not promote a later development version until its CI and required real-device checklist both pass.

## Next task
Plan the next isolated development phase from the p32 device-verified baseline. No p33 runtime source change has been promoted or device-verified yet.
