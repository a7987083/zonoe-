# ROADMAP

## Current baseline
- Device-verified version: `v1_p31`.
- Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- Validation workflow: `p31 Registry Boundary Build` / Run `34673034214` / success.
- `v1_p29` Rendering and `v1_p30` EventBridge hardware gates were closed by the cumulative `v1_p31` real-device regression.

## Completed phases
- `v1_p28` — ZONCore Build Integration.
- `v1_p29` — Rendering Boundary Cleanup.
- `v1_p30` — EventBridge Boundary Cleanup.
- `v1_p31` — Feature Registry Boundary Cleanup + cumulative hardware regression.
- `v1_p32-A` — Dispatcher Boundary Audit; Run `34703403975` passed with no p31 product-source changes.

## Current phase — v1_p32-B Dispatcher Source Split
Status: `ready_to_implement`.

### Goal
Move the seven active Dispatcher function bodies from `ZONFeatureDispatcher.h` into an independent Objective-C implementation while preserving every route, persistence key, destructive confirmation boundary and runtime side effect.

### Scope
- Change `VERSION` to `v1_p32` when the split source lands.
- Keep only public Dispatcher declarations in `ZONFeatureDispatcher.h`.
- Add `ZONFeatureDispatcher.m` with the audited function bodies.
- Register `ZONFeatureDispatcher.m` in the Xcode target Sources phase.
- Prove route/protected-marker equivalence against p31 before build.
- Rerun Registry and Module ABI smokes.
- Build both `A_customer` and `B_debug` for arm64 + arm64e on iOS 12 target.
- Define the p32 real-device regression before A_customer promotion.

### Out of scope
- No business-handler cleanup or rewrite.
- No Registry/EventBridge semantic change.
- No authorization/UDID/cloud-save protocol change.
- No destructive-action semantic change.
- No UI/layout/animation/keyboard change.

## Next Task
Implement the mechanical Dispatcher source split on an isolated p32-B work branch, then run source-equivalence and full A/B build CI.
