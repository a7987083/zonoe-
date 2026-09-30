# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.8g R2 Runtime Capability Extraction — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8g`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `9702183f97304e62939d528f7bec64c46417510a`.
- CI Run `36727105080` / #53: success.
- Artifact ID `11103866499`, digest `sha256:0d41293824d72804b263385b51e50f59dac69b3adaf1adad2e43a2b9203792ef`.
- Raw CI dylib SHA256: `e5a7f07ed4a5bf980113382f72eca11782fc163b80f64a05754843b0b3a3bede`.
- Controlled final dylib SHA256: `4172ac0881f6885b1ac620a486ba9b8eadd153c9b11f26a3647607737c028863`.
- Controlled final ZIP SHA256: `b7e6d9eea2cfb347e1868457e43f54c5b4673b9d28486998433aa44b7b749ad1`.
- Universal `arm64 + arm64e (PAC00)`.

### R2 delivered in P79.8g
1. Added `ZONRuntimeCapabilityService` with stable APIs:
   - `isCapabilityAvailable:`
   - `activateCapability:`
2. Registered first capability: `passive.satella`.
3. Moved passive image enumeration, Mach-O validation, P79.8f mapped-`__TEXT` safety gate, RVA/signature checks, PAC signing, main-thread handoff and one-shot state out of `ZONFeatureDispatcher`.
4. `ZONFeatureDispatcher` now only applies the existing `NNGG/NNGGNNGG` + `ImgTool.NeiGou` toggle behavior and delegates passive activation to the capability service.
5. The capability service remains preload-only: no `dlopen`/`dlclose` ownership was introduced.
6. Added `Tests/p79_8g_runtime_capability_boundary.py`; it forbids dyld/Mach-O/PAC implementation from returning to Dispatcher.
7. Migrated P79.8d passive and P79.8f P0 tests to follow the implementation into the capability service, preserving the old behavior contracts instead of weakening them.

### P79.8g CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- Xcode 16.4 `arm64 + arm64e` build: PASS.
- Controlled final injection changed exactly 128 bytes across the two Verify Secret placeholder regions; placeholder remaining `0`, Secret occurrences `2`.

## Device-passed baseline retained — P79.8f
- P79.8f remains the current P0 real-device baseline.
- User reported P79.8f device testing normal on 2026-09-30.
- P79.8g is an architecture move, so CI success does not automatically promote it over that device baseline.

## P79.8g short device-equivalence gate
1. Existing `runtime.iap-noads` behavior remains unchanged (`NNGG`, `NNGGNNGG`, `ImgTool.NeiGou`).
2. Matching injected passive dylib still produces `validated → init → started` and the feature activates.
3. Second ON in the same process still logs `already_started` and does not run init twice.
4. No passive dylib still logs `image_not_loaded_or_invalid`, does not crash, and does not roll back the original toggle.
5. Same-name malformed/incompatible passive target still fails closed via mapped-range or signature checks before call.
6. arm64e PAC-signed indirect invocation still works on device.

## Remaining separate regression gates
- P79.8c cloud permission matrix remains separately pending: `basic` hides `VIP云存档`; `app_plus/global_plus` expose it; actual action still requires fresh Verify.
- P79.8b full persistence regression remains separately pending beyond the P0 protected-key reset boundary.

## Next stage after P79.8g device acceptance — R3 Feature Access Provider
1. Introduce one feature-access provider that combines server permissions with local runtime capability availability.
2. Stop menu renderers from independently parsing raw `ZONAuthV2Storage` permission schema.
3. Extend feature metadata with an optional runtime-capability requirement.
4. Use that for the future standalone external-dylib button:
   - server/access rules satisfied + compatible target loaded → render button;
   - target missing/incompatible → do not render button.

## Later refactor sequence
- R4 — migrate weak dictionary feature metadata toward typed descriptors while preserving identifiers/tags/order.
- R5 — decompose `ZONAuthV2Flow`, starting from pure authorization-decision parsing.
- R6 — measure startup/preflight/module-load timing before optimization or reordering.
- R7 — classify historical tests/workflows/generated artifacts before cleanup.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Run the P79.8g short R2 device-equivalence matrix. If it passes, begin R3 feature-access provider and then integrate the future new external-dylib standalone button through `isCapabilityAvailable:`.
