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

## Current phase — v1_p32-A Dispatcher Boundary Audit
Status: `implementation_complete_ci_pending`.

### Goal
Prove the active `ZONFeatureDispatcher` ownership, route invariants and protected business boundaries before moving any Dispatcher function body out of the header.

### Scope
- Confirm `ZONMenuEventBridge.m` is the active translation unit importing the header-only Dispatcher.
- Confirm no `ZONFeatureDispatcher.m` is currently registered in the Xcode target.
- Inventory all seven inline functions and their dependencies.
- Lock seven action routes, three toggle routes, persistence keys and `ImgTool` side effects.
- Lock destructive confirmation boundaries and tmp-directory invariant.
- Add an automated audit that fails if those assumptions drift.
- Prove the audit phase itself makes no product-source diff from the p31 device-verified baseline.

### Out of scope
- No Dispatcher source split yet.
- No business-handler changes.
- No Registry/EventBridge behavior changes.
- No authorization/UDID/cloud-save/destructive-action semantic changes.
- No UI, layout, animation, keyboard or presentation changes.

### Plan
1. Run `p32 Dispatcher Boundary Audit` CI on the audit branch.
2. If green, mark p32-A complete and retain `v1_p31` as the runtime baseline.
3. Start p32-B as an isolated source split: declaration header + `ZONFeatureDispatcher.m` + PBX registration.
4. Run source-equivalence checks, permanent smokes and full A/B Xcode builds.
5. Define/execute the p32 device checklist before promoting any p32 runtime build.

## Next Task
Wait for the p32-A audit workflow. If it passes, implement p32-B Dispatcher source split without changing route or protected business semantics.
