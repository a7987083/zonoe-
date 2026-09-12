# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current audit branch: `work/zonoemenu-v1-p32-dispatcher-audit`
- Runtime version/baseline: `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` (device verified)
- Current development phase: `v1_p32-B Dispatcher Source Split`.

## p32-A audit result
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Workflow: `p32 Dispatcher Boundary Audit`.
- Run: `34703403975`.
- Result: `success`.
- Product source difference from p31 during audit: none.
- Registry smoke: passed.
- Module ABI smoke: passed.

## Active Dispatcher ownership before p32-B
- Xcode target compiles `testmod/ZONCore/ZONMenuEventBridge.m`.
- `ZONMenuEventBridge.m` imports `ZONFeatureDispatcher.h`.
- Xcode target does not register `ZONFeatureDispatcher.m` yet.
- All seven `static inline` Dispatcher bodies are therefore compiled into EventBridge.

Detailed invariants are in `DISPATCHER_AUDIT.md`.

## Dispatcher-owned behavior that must not drift
- Actions: remote download, cloud save, local files, backup, restore, clear game data, clear authorization.
- Toggles: IAP/no-ads, ad-speed enable, placeholder 203.
- Persistent keys: `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`.
- EventBridge numeric speed key remains `AADDssppeedd`.
- Runtime side effects remain `ImgTool.NeiGou`, `ImgTool.ADSpeed`, `ImgTool.ADBiansu`.
- Cloud save must self-heal sandbox `tmp` before status handling.
- Destructive routes must retain confirmation boundaries and delayed exit behavior.

## p32-B implementation rule
Do a mechanical source split only. Move bodies without rewriting conditions, selectors, strings, timing or side effects. Register the new `.m` in PBX and verify the complete target. Do not mix business cleanup/refactoring into this phase.

## Verification policy
- Source/route equivalence against p31 is required before build.
- Registry and Module ABI smokes remain required.
- A_customer and B_debug must both compile/link/package as arm64 + arm64e with iOS 12 deployment target.
- CI success does not promote p32. Real-device protected-path regression and explicit user pass are still required.

## Next task
Create the p32-B source branch, split `ZONFeatureDispatcher`, register its `.m`, run A/B CI, then provide A_customer for hardware regression.
