# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8g R2 Runtime Capability Extraction
- VERSION: `v1_p79_8g`.
- Build HEAD: `9702183f97304e62939d528f7bec64c46417510a`.
- CI Run `36727105080` / #53: success.
- Artifact ID `11103866499`, digest `sha256:0d41293824d72804b263385b51e50f59dac69b3adaf1adad2e43a2b9203792ef`.
- Raw CI SHA256: `e5a7f07ed4a5bf980113382f72eca11782fc163b80f64a05754843b0b3a3bede`.
- Controlled final SHA256: `4172ac0881f6885b1ac620a486ba9b8eadd153c9b11f26a3647607737c028863`.
- Controlled ZIP SHA256: `b7e6d9eea2cfb347e1868457e43f54c5b4673b9d28486998433aa44b7b749ad1`.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / DEVICE PENDING.

## R2 architecture change
- Added `testmod/ZONServices/ZONRuntimeCapabilityService.h/.m`.
- Public capability API:
  - `+isCapabilityAvailable:`
  - `+activateCapability:`
- First registered identifier: `passive.satella` (`ZONRuntimeCapabilityPassiveSatella`).
- `ZONFeatureDispatcher` no longer owns `_dyld_*`, Mach-O segment parsing, RVAs, binary signatures, PAC signing or one-shot passive state.
- Dispatcher still preserves the original toggle first: `NNGG`, `NNGGNNGG`, `ImgTool.NeiGou`; ON then delegates to `ZONRuntimeCapabilityService`.
- The capability service only consumes an already-loaded target. It does not `dlopen` or `dlclose` external modules.

## Exact P79.8f/P79.8d behavior preserved inside capability service
- Accepted target names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- `__TEXT vmaddr=0` contract preserved.
- ctor RVA `0x847C` must match ARM64 `RET` bytes `C0 03 5F D6`.
- init RVA `0x888C` must match the existing 16-byte prologue.
- P79.8f mapped-`__TEXT` readable/executable/range validation still runs before either signature dereference.
- Main-thread invocation, arm64e function-pointer PAC and process one-shot behavior are unchanged.
- Missing/invalid target still fails only the passive activation; it does not roll back the original IAP/iGameGod toggle.

## Test/CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS` after following implementation into capability service.
- `p79.8f-p0-safety: PASS` after following mapped-range safety into capability service.
- `p79.8g-runtime-capability: PASS`; this test forbids low-level image/PAC implementation from returning to Dispatcher.
- Xcode 16.4 arm64 + arm64e build: PASS.
- CI workflow materializes `ZONRuntimeCapabilityService.h/.m` into the `testmod` target before build, matching the existing AuthV2 project-materialization pattern.

## Current real-device baseline
- P79.8f remains the last device-passed baseline.
- User reported P79.8f testing normal on 2026-09-30.
- Do not mark P79.8g device-passed until the short equivalence matrix is run.

## P79.8g device test order
1. Toggle `runtime.iap-noads` with matching passive target: expect `validated`, `init=...`, `started`; feature actually activates.
2. OFF→ON again in same process: expect `already_started`; no second init.
3. Run with no passive target: expect `image_not_loaded_or_invalid`; no crash; original IAP/iGameGod toggle remains functional.
4. Run with incompatible/same-name malformed target: mapped-range or ctor/prologue failure; no jump.
5. Confirm arm64e device invocation still works.

## Next engineering stage after device pass — R3
- Add a feature-access provider that combines server `permissions` with `ZONRuntimeCapabilityService.isCapabilityAvailable:`.
- Add optional runtime-capability metadata to features.
- Then the future new external dylib can own a standalone feature/button that is rendered only when its target is actually loaded and compatible.

## Remaining separate regressions
- P79.8c VIP cloud permission matrix remains separately pending.
- P79.8b full persistence regression remains separately pending beyond the P0 reset boundary.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
