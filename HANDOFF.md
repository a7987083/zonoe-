# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current baseline — P79.8g R2 Runtime Capability Extraction
- VERSION: `v1_p79_8g`.
- Build HEAD: `9702183f97304e62939d528f7bec64c46417510a`.
- CI Run `36727105080` / #53: success.
- Artifact ID `11103866499`, digest `sha256:0d41293824d72804b263385b51e50f59dac69b3adaf1adad2e43a2b9203792ef`.
- Raw CI SHA256: `e5a7f07ed4a5bf980113382f72eca11782fc163b80f64a05754843b0b3a3bede`.
- Controlled final SHA256: `4172ac0881f6885b1ac620a486ba9b8eadd153c9b11f26a3647607737c028863`.
- Controlled ZIP SHA256: `b7e6d9eea2cfb347e1868457e43f54c5b4673b9d28486998433aa44b7b749ad1`.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / DEVICE PASSED.
- User reported P79.8g testing normal on 2026-09-30.

## R2 architecture now promoted
- Added `testmod/ZONServices/ZONRuntimeCapabilityService.h/.m`.
- Public API:
  - `+isCapabilityAvailable:`
  - `+activateCapability:`
- First registered identifier: `passive.satella`.
- `ZONFeatureDispatcher` no longer owns `_dyld_*`, Mach-O parsing, RVAs, signatures, PAC or passive one-shot state.
- Dispatcher preserves `NNGG`, `NNGGNNGG`, `ImgTool.NeiGou` first and then delegates ON activation to the capability service.
- Capability service only consumes already-loaded targets; it does not `dlopen`/`dlclose` external modules.

## Preserved runtime contract
- Accepted target names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- `__TEXT vmaddr=0` remains required.
- ctor RVA `0x847C` and init RVA `0x888C` remain unchanged.
- Exact ctor/init signatures remain unchanged.
- P79.8f mapped-`__TEXT` readable/executable/range checks still execute before dereference/call.
- Main-thread invocation, arm64e PAC, one-shot semantics and no-target no-rollback behavior remain unchanged.
- P79.8g real-device test was reported normal after moving this implementation behind the service boundary.

## Test/CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final Verify Secret injection touched only the two equal-length placeholder regions: 128 changed bytes, placeholder remaining 0, occurrences 2.

## Device baselines
- P79.8f remains the closed P0 safety baseline.
- P79.8g is now the latest device-passed runtime/architecture baseline.
- Remaining independent gates are still P79.8c full VIP cloud permission matrix and P79.8b full persistence regression.

## Next engineering stage — P79.8h / R3 Feature Access Provider
- Introduce one access provider that combines server `permissions` with `ZONRuntimeCapabilityService.isCapabilityAvailable:`.
- Stop `ZONSectionRenderer` and related menu code from independently parsing raw AuthV2 session schema.
- Add optional runtime-capability requirement metadata to feature definitions while preserving identifiers/tags/order.
- Apply the same access decision to both render visibility and action/toggle dispatch so a hidden feature cannot be reached by a legacy/direct route.
- This becomes the final infrastructure layer before adding the future standalone external-dylib button: compatible target loaded → show; missing/incompatible → hide.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
