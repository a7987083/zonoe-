# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p32-dispatcher-split`
- Current source version: `v1_p32` (CI pending).
- Device-verified baseline remains `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.

## p32-A audit
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Run: `34703403975` / success.
- Detailed contract: `DISPATCHER_AUDIT.md`.

## p32-B implementation
- `ZONFeatureDispatcher.h` now declares the seven Dispatcher functions and no longer contains inline bodies.
- `ZONFeatureDispatcher.m` contains the mechanically moved bodies.
- Existing header imports are retained intentionally for this phase to avoid transitive-include cleanup being mixed with the source split.
- `ZONMenuEventBridge.m` remains behaviorally unchanged and still imports `ZONFeatureDispatcher.h`.
- `dispatcher_contract_smoke.py` locks route identifiers, handler calls, protected destructive markers, persistence keys and runtime-sync ownership.
- PBX registration is intentionally delegated to isolated build CI and must become part of the final p32 source head before the build is considered valid.

## Protected behavior
Do not change cloud-save tmp self-heal, clear-game-data confirmation/cleanup/delayed exit, clear-authorization confirmation/deletekm/delayed exit, legacy persistence keys, local-files presentation, or `ImgTool` runtime side effects during this phase.

## Verification gates
- p31 -> p32 implementation equivalence.
- Dispatcher PBX registration.
- Dispatcher contract smoke.
- Registry smoke.
- Module ABI smoke.
- A_customer and B_debug full Xcode build/package for arm64 + arm64e / iOS 12.
- Real-device p32 checklist and explicit user pass before promotion.

## Next task
Run isolated p32 build CI, let CI commit PBX integration back to this work branch, record final source commit/artifacts, then hand A_customer out for device regression.
