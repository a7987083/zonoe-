# ROADMAP

## Current baseline
- Device-verified version: `v1_p31`.
- Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- p31 CI: Run `34673034214` / success.

## Completed phases
- `v1_p28` — ZONCore Build Integration.
- `v1_p29` — Rendering Boundary Cleanup.
- `v1_p30` — EventBridge Boundary Cleanup.
- `v1_p31` — Feature Registry Boundary Cleanup + cumulative hardware regression.
- `v1_p32-A` — Dispatcher Boundary Audit / Run `34703403975` / success.

## Current phase — v1_p32-B Dispatcher Source Split
Status: `source_split_implemented_ci_pending`.

### Goal
Move the seven audited Dispatcher bodies into `ZONFeatureDispatcher.m` without changing business behavior.

### Implemented source scope
- `VERSION`: `v1_p31` -> `v1_p32`.
- `ZONFeatureDispatcher.h`: declarations only; existing imports intentionally retained to minimize transitive-include risk.
- Added `ZONFeatureDispatcher.m` containing the seven audited bodies.
- Added permanent `dispatcher_contract_smoke.py` and wired it into `module-abi.yml`.
- Defined the p32 real-device checklist before artifact handoff.

### CI plan
1. Prove only Dispatcher header/implementation + VERSION changed under product source before PBX integration.
2. Compare p32 `.m` implementation text against normalized p31 inline bodies.
3. Register `ZONFeatureDispatcher.m` in PBX and commit that integration to the work branch.
4. Run Dispatcher contract, Registry smoke and Module ABI smoke.
5. Build/package `A_customer` and `B_debug` for arm64 + arm64e / iOS 12.

## Next Task
Run p32 isolated build CI. If both variants succeed, record the final source head/artifact hashes and hand A_customer to the user for the p32 device checklist.
