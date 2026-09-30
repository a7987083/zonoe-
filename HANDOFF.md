# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8f P0 Runtime/Authorization Safety Hardening
- VERSION: `v1_p79_8f`.
- Build HEAD: `67fbf755cf00623f3d0136668e103461d5189dae`.
- CI Run `36723643520` / #44: success.
- Artifact ID `11101797212`, digest `sha256:e16aa4bb55eb9e776c283d02da67eef78010f7f07df012c764e7a452a029ba6e`.
- Raw CI SHA256: `b124e544b32674844bf7e9be9a35e0259e512063ce7b0113e5450c3a61535970`.
- Controlled final SHA256: `18c443fb67440e7030b1b85fb82813c6d5aad52347cbf4aa3358313e00a84a6a`.
- Controlled ZIP SHA256: `1e6ba1e2b3576673e645e787b83cadde1b6833f200dc621d527273ab6fbe0778`.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / DEVICE PENDING.

## P79.8f code changes
1. `ZONFeatureDispatcher.m`
   - Added mapped-`__TEXT` validation before reading `base + 0x847C` or `base + 0x888C`.
   - Requires `LC_SEGMENT_64`, `__TEXT vmaddr=0`, readable + executable initial protections, and both signature ranges fully inside `vmsize`.
   - Bad/malformed targets log `[zonoemenu][P79.8F_P0_SATELLA] text_range_mismatch` and are rejected before `memcmp`/call.
   - P79.8d file names, offsets, signatures, no-dlopen ownership, main-thread call, PAC and one-shot behavior are unchanged.
2. `ZONAuthorizationResetService.m`
   - Snapshots `fold_base/fold_draw/fold_role/NNGG/NNGGNNGG/AADD/AADDAADD/AADDssppeedd` before auth cleanup.
   - Verifies those unrelated menu/runtime keys are unchanged after cleanup.
   - If crossed, restores the snapshot and returns failure with `[P79.8F_P0_RESET]` logging.
3. `Tests/p79_8f_p0_safety_contract.py`
   - Locks mapped-range gating before passive signature reads.
   - Locks authorization reset/menu preference boundary.
   - Locks current game-data reset roots to current-container `Documents`, `Library`, `tmp` + current bundle defaults.
   - Locks startup network-error and unknown-payload behavior so neither is routed as “missing activation” card prompt.
4. Active P79 workflow now runs all three current contracts and triggers on `Tests/**`.

## CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Raw CI build intentionally has no configured Verify Secret.
- Controlled final injection changed exactly 128 bytes in the two placeholder regions; placeholder remaining 0, Secret occurrences 2.

## Exact device test order
1. **Activated UDID startup**: no card prompt; reaches Verify and floating/menu entry.
2. **Offline startup**: show network failure; no card prompt.
3. **Clear authorization**: auth state is removed; all protected menu/runtime keys retain their previous values.
4. **Clear game data**: only current App container Documents/Library/tmp/current bundle defaults are affected; no sandbox escape or bundle deletion.
5. **Matching passive dylib**: first ON logs `validated`, `init=...`, `started`; feature really activates.
6. **Second ON same process**: logs `already_started`; no second init.
7. **No passive dylib**: log `image_not_loaded_or_invalid`; no crash; original IAP/iGameGod toggle still works.
8. **Incompatible/same-name malformed target**: expect `text_range_mismatch` or ctor/prologue mismatch; no jump.
9. **arm64e hardware**: indirect PAC-signed call works.

## Current architecture ownership
- Startup: `Bsphp/main.m +load` → `ZONBootstrap`.
- Customer identity: `ZONAuthorizationCoordinator` + `ZonoeUDIDAPI`/bridge.
- Authorization state/orchestration: `ZONAuthV2Flow` → `ZONAuthV2API` → Runtime Config/`ZONAuthV2Verify`.
- Menu: `ZONMenuCoordinator` → renderers → `ZONMenuEventBridge` → `ZONFeatureDispatcher`.
- Business actions: `testmod/ZONServices` service/coordinator layer.
- Formal plugin loading: `ZONModuleLoader` ABI.
- Passive Satella: externally preloaded image; current probe/call still lives in Dispatcher pending R2.

## Last device-passed baseline
- P79.8a / `v1_p79_8a`.
- CI Run `36572203902` / #32.
- Controlled final SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- User confirmed fresh App + already-active UDID works without card re-entry.

## Next engineering stage
Do **not** start R2 yet. First accept or reject the P79.8f P0 device matrix. After P0 device acceptance, extract the passive runtime capability from Dispatcher and use that capability boundary for the future new external-dylib button/filter.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
