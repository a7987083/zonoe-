# ROADMAP

## Current baseline
- Device-verified version: `v1_p32`.
- Source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- p32 CI: Run `34723015809` / success.
- p32 real-device regression: passed by explicit user report.

## Completed phases
- `v1_p28` — ZONCore Build Integration.
- `v1_p29` — Rendering Boundary Cleanup.
- `v1_p30` — EventBridge Boundary Cleanup.
- `v1_p31` — Feature Registry Boundary Cleanup + cumulative hardware regression.
- `v1_p32-A` — Dispatcher Boundary Audit / Run `34703403975` / success.
- `v1_p32-B` — Dispatcher Source Split / final source `84f8b3898bee9d95ed4034d12842879cc56280d3` / Run `34723015809` / CI success / device regression passed.

## v1_p32 result
Status: `device_verified`.

### Completed source scope
- `VERSION`: `v1_p31` -> `v1_p32`.
- `ZONFeatureDispatcher.h`: declarations only; existing imports retained to minimize transitive-include risk.
- Added `ZONFeatureDispatcher.m` containing the seven audited bodies.
- Registered `ZONFeatureDispatcher.m` in the Xcode target.
- Added permanent `dispatcher_contract_smoke.py` and wired it into `module-abi.yml`.
- Defined and completed the p32 real-device checklist.

### Verification completed
1. Proved Dispatcher source/body equivalence against p31.
2. Verified PBX registration.
3. Passed Dispatcher contract, Registry smoke and Module ABI smoke.
4. Built/packaged `A_customer` and `B_debug` for arm64 + arm64e / iOS 12.
5. User explicitly reported the p32 real-device checklist passed.

## Next Task
Define the next isolated development phase from the `v1_p32` device-verified baseline. Do not start or promote a broader refactor without first recording its boundary, invariants, CI plan and device-test scope.
