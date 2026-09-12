# ROADMAP

## Current baseline
- Device-verified version: `v1_p31`.
- Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- Validation workflow: `p31 Registry Boundary Build` / Run `34673034214` / success.
- `v1_p29` Rendering and `v1_p30` EventBridge device validation are considered covered by the successful cumulative `v1_p31` hardware regression.

## Completed phases
- `v1_p28` — ZONCore Build Integration.
- `v1_p29` — Rendering Boundary Cleanup.
- `v1_p30` — EventBridge Boundary Cleanup.
- `v1_p31` — Feature Registry Boundary Cleanup + cumulative hardware regression.

## Next phase candidate — v1_p32 Dispatcher Boundary Audit
Goal: determine whether `ZONFeatureDispatcher` can be moved from the remaining business-heavy header boundary to a declaration header + independent implementation without changing protected business behavior.

Planned audit scope:
- Confirm the actual compiled `ZONFeatureDispatcher` path and all active call sites from `ZONMenuEventBridge`.
- Inventory declarations, inline/static helpers, globals and function bodies currently owned by `ZONFeatureDispatcher.h`.
- Identify protected routes: remote download, VIP cloud save, local files, backup/restore, clear-game-data and clear-authorization.
- Define source-equivalence / route-smoke checks before moving any function body.
- Define the `v1_p32` real-device checklist before handing out an A_customer build.
- Do not alter authorization, UDID, cloud-save, destructive actions, UI, keyboard/presentation or runtime semantics as part of the boundary audit.

## Next Task
Audit `ZONFeatureDispatcher.h` against the active Xcode target and `ZONMenuEventBridge` call chain. Only start the `v1_p32` source split after the protected-path regression plan is complete.
