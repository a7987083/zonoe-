# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current baseline — P79.8f P0 Runtime/Authorization Safety Hardening
- VERSION: `v1_p79_8f`.
- Build HEAD: `67fbf755cf00623f3d0136668e103461d5189dae`.
- CI Run `36723643520` / #44: success.
- Artifact ID `11101797212`, digest `sha256:e16aa4bb55eb9e776c283d02da67eef78010f7f07df012c764e7a452a029ba6e`.
- Raw CI SHA256: `b124e544b32674844bf7e9be9a35e0259e512063ce7b0113e5450c3a61535970`.
- Controlled final SHA256: `18c443fb67440e7030b1b85fb82813c6d5aad52347cbf4aa3358313e00a84a6a`.
- Controlled ZIP SHA256: `1e6ba1e2b3576673e645e787b83cadde1b6833f200dc621d527273ab6fbe0778`.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / P0 DEVICE PASSED.
- User reported P79.8f device testing normal on 2026-09-30.

## P79.8f device-passed P0 contract
1. Activated-UDID startup remains healthy and does not regress into unnecessary card prompting.
2. Offline/transport failure does not get treated as missing activation.
3. Authorization reset preserves unrelated menu/runtime preferences.
4. Game-data reset remains constrained to intended current-App container state.
5. Matching externally injected passive dylib remains callable through the existing runtime switch.
6. Missing/incompatible passive targets fail safely and do not break the original IAP/iGameGod toggle.
7. No device regression was reported for the P79.8f safety changes.

## P79.8f code changes
- `ZONFeatureDispatcher.m`: mapped `__TEXT` validation before reading passive ctor/init RVAs; malformed targets fail closed with `[P79.8F_P0_SATELLA]`.
- `ZONAuthorizationResetService.m`: snapshot/verify/restore protected menu/runtime keys around authorization cleanup.
- `Tests/p79_8f_p0_safety_contract.py`: locks network-error routing, unknown-payload behavior, reset boundaries, current game-data reset scope, and passive mapped-range validation.
- Active P79 workflow runs current Dispatcher, passive-runtime and P0 safety contracts before Xcode build.

## Current architecture ownership
- Startup: `Bsphp/main.m +load` → `ZONBootstrap`.
- Customer identity: `ZONAuthorizationCoordinator` + `ZonoeUDIDAPI`/bridge.
- Authorization state/orchestration: `ZONAuthV2Flow` → `ZONAuthV2API` → Runtime Config/`ZONAuthV2Verify`.
- Menu: `ZONMenuCoordinator` → renderers → `ZONMenuEventBridge` → `ZONFeatureDispatcher`.
- Business actions: `testmod/ZONServices` service/coordinator layer.
- Formal plugin loading: `ZONModuleLoader` ABI.
- Passive Satella: externally preloaded image; current probe/call still lives in Dispatcher pending R2.

## Remaining separate regressions
- P79.8c cloud permission behavior is not promoted by the P79.8f P0 test result; basic vs app/global Plus visibility/action/fresh-Verify still has its own regression gate.
- P79.8b full persistence regression remains separately tracked beyond the P0 protected-key reset boundary.

## Next engineering stage — P1 / R2 Runtime Capability
- Extract only the passive injected-image probe/validation/invocation from `ZONFeatureDispatcher` into a dedicated capability service/registry.
- Do not change accepted image names, RVAs, signatures, mapped-range guard, no-dlopen ownership, PAC, main-thread invocation, one-shot semantics, or original toggle behavior.
- Use that boundary for the future new external dylib: target loaded + compatible → show its standalone button; otherwise do not render it.
- Run source contracts + arm64/arm64e build + device regression before promoting R2.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
