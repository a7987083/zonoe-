
## v1_p79_8j — Auth Verification Residue Cleanup
- Removed detached `ZONAuthV2BindingProbe` compatibility/swizzle source.
- Removed duplicate `ZONAuthV2API` Verify transport; `ZONAuthV2Verify` exclusively owns `/challenge` and `/verify`.
- Removed card propagation/storage from Verify; card remains activation-only.
- Removed write-only `lastActivation` and duplicate `lastBootstrap` session caches.
- Kept `lastRuntimeConfig` because cloud-save fresh Verify still consumes it.
- Kept legacy `WX_NongShiFu123`/Config source because the live legacy-UDID fallback and cloud-save purchase/config paths still reference it; it is not dead code yet.
- Replaced card-centric generic Verify errors with v3 protocol-aware messages.
# CHANGELOG_DEV

## 2026-10-01 — v1_p79_8i UDID auth-proof enrollment cutover — CLIENT CI PASSED / SERVER PENDING / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Preserved the existing UDID-first business activation model: active UDID skips card and `/appstore`; missing/expired UDID uses card activation then a second `/apiface` confirmation.
- Removed the accidental second `/index/dylib_verify/config` hop; signed GitHub bootstrap is used directly as Runtime Config after RSA-2048/SHA-256 verification.
- Removed the secondary `设备安全升级`/card enrollment UI.
- Added session-only `auth_proof` storage: header commit `e9b38e18aea65420e49d1171d1278040ffd72407`, implementation commit `9b7053ac431bd87fb32736d30436f983433cac17`.
- `ZONAuthV2API.fetchLicenseForUDID` now captures/refreshed top-level `/apiface` `auth_proof` and clears it on lookup failure: `fa0c5f6860f763492ecd80f65e0f4c83d9634f31`.
- `ZONAuthV2Verify` now fails closed with `auth_proof_unavailable` if the proof is absent, includes `auth_proof` in `/challenge`, clears it after challenge acceptance, and no longer sends `license_code` to `/verify`: `78effa63a4a66d7a91cadd40d3024d8ce61d2e9d`.
- Updated v3 contract to require auth-proof challenge enrollment and forbid card-backed Verify enrollment: `980bc43656c8f609ea1c1c8f596d6128c5ae623e`.
- Functional auth-proof HEAD before documentation synchronization: `980bc43656c8f609ea1c1c8f596d6128c5ae623e`.
- CI Run `36856203863` / #84: success.
- Artifact ID `11157763459`, digest `sha256:18fd793a2d930f63774e244e8c88d75849702e0542f6791b89f5d7033acdc35f`.
- CI dylib SHA256 `a30afd52caf5640ab27aa907b5da70b4450c8b336b115a43ae0a3cf0184525af`, size 3,321,952 bytes, universal arm64 + arm64e PAC00.
- Contract suite and Xcode 16.4 build passed.
- Matching server contract is still required before device promotion: active `/apiface` must return `auth_proof`/expiry; `/challenge` must validate it and bind the challenge to the submitted public-key fingerprint; `/verify` must allow first-key enrollment without `license_code`.
- Multi-App rule is explicit: once a UDID is active, additional Apps on that UDID may enroll their own P-256 keys using fresh `/apiface` proofs without card re-entry.
- Latest device-passed baseline remains P79.8g.

## 2026-09-30 — v1_p79_8h R3 Feature Access Provider — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Added `ZONFeatureAccessProvider.h`: `25b8eb453dee2ed3e5ad7328bc1726b57649d583`.
- Added provider implementation centralizing `lastVerify → permissions/access_level` plus optional runtime-capability checks: `b50daa7b75b2bcae8ab67f81f63a46b201ad8369`.
- Added optional registry key `requiredRuntimeCapability` declaration/definition: `b00105f51618b159a3c4b83ca3a4077722e9c475`, `364ffdb66b692cde5d087a394dea56fff8a6b033`.
- Migrated `ZONSectionRenderer` from raw `ZONAuthV2Storage` parsing to `ZONFeatureAccessProvider.isFeatureVisible:`: `b213626cc4494f80a1f357ae72c09be4b46d90ab`.
- Migrated protected action access in `ZONFeatureDispatcher` to `ZONFeatureAccessProvider.isFeatureActionAllowed:` and removed its duplicate current-permissions parser: `37008e3d749e0ff58e0c66fcab7c90d544f9604b`.
- Added `Tests/p79_8h_feature_access_provider.py`: `fdaafd8898662ff9aadbfbff8c94883d0c018012`.
- Updated active CI to run the R3 contract and materialize `ZONFeatureAccessProvider.h/.m` into the target: `ebec8155f7ba983f234447d07bc7df9cd76a09d9`.
- VERSION/build commit: `b62e6ac71c6d58db48b75e8f3064b012b836571f`; VERSION=`v1_p79_8h`.
- CI Run `36734106358` / #62: success.
- Artifact ID `11106496611`, digest `sha256:1326c3f0b22e684964ab35c1d6cfb3d7a128dbe5eae10ad96dd965f6a58ccbac`.
- Raw CI dylib SHA256: `ae3a3eee1fc53b0009f7c25ad4b37d9713ab2ef2f0fd34d1ad17dc78fd3c3457`, size 3,266,336 bytes.
- Controlled final dylib SHA256: `8ac866a22d2bae372adb62f9cdcc67c1bfadf6b3a71fe7e8e2b927d8687caa26`.
- Controlled final ZIP SHA256: `215be24ecbc1aa92441603dbaac3073523dd47254f1e36df7450327bf41681ae`.
- Controlled final injection changed exactly 128 bytes in the two equal-length Verify Secret placeholder regions; placeholder remaining `0`, Secret occurrences `2`.
- No existing feature is assigned `requiredRuntimeCapability` in P79.8h; current visibility/action behavior is intentionally preserved.
- Existing `base.cloud-save` permission metadata remains `extra_menu` for visibility and `extra_features` for action.
- P79.8g passive runtime path remains owned by `ZONRuntimeCapabilityService`; no exported-symbol probing/new external-dylib button was added in this version.
- CI contract results: `dispatcher-contract: PASS`, `p79.8d-passive-contract: PASS`, `p79.8f-p0-safety: PASS`, `p79.8g-runtime-capability: PASS`, `p79.8h-feature-access: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Latest device-passed baseline remains P79.8g until the short P79.8h equivalence check is reported.
- The source-controlled external dylib interface/button is intentionally deferred per current requirement.

## 2026-09-30 — v1_p79_8g R2 Runtime Capability Extraction — CI PASSED / DEVICE PASSED
- Branch: `work/p79.8-udid-first-rebuild`.
- Added `ZONRuntimeCapabilityService.h`: `e2ae02388d1990cefa0160d61d04d530e65556c3`.
- Added passive capability implementation and stable `passive.satella` identifier: `3cecb5791bae8aa22a52681cbc54dfd405a098a6`.
- Reduced `ZONFeatureDispatcher` to runtime toggle routing + capability delegation: `7441e424aadd1453762741e7b8666a7196cca330`.
- Migrated exact P79.8d passive contract test to the capability service without weakening behavior requirements: `4cbe15a61b61659e5110a7a14956c44ddb8766fa`.
- Migrated P79.8f mapped-range P0 contract to the capability service: `3b902b1dc17b46b098f7aea45919aef70b85abbf`.
- Added `Tests/p79_8g_runtime_capability_boundary.py`: `4953e357c2f33b0eae20434b8bc6f3d24fe59109`.
- Updated CI to materialize `ZONRuntimeCapabilityService.h/.m` into the `testmod` target and execute the R2 boundary test: `06be0e0a7f23b61d88fbe71752f9625822566a2f`.
- VERSION/build commit: `9702183f97304e62939d528f7bec64c46417510a`; VERSION=`v1_p79_8g`.
- CI Run `36727105080` / #53: success.
- Artifact ID `11103866499`, digest `sha256:0d41293824d72804b263385b51e50f59dac69b3adaf1adad2e43a2b9203792ef`.
- Raw CI dylib SHA256: `e5a7f07ed4a5bf980113382f72eca11782fc163b80f64a05754843b0b3bede`, size 3,264,304 bytes.
- Controlled final dylib SHA256: `4172ac0881f6885b1ac620a486ba9b8eadd153c9b11f26a3647607737c028863`.
- Controlled final ZIP SHA256: `b7e6d9eea2cfb347e1868457e43f54c5b4673b9d28486998433aa44b7b749ad1`.
- Controlled final injection changed exactly 128 bytes in the two equal-length Verify Secret placeholder regions; placeholder remaining `0`, Secret occurrences `2`.
- `ZONRuntimeCapabilityService` exposes `isCapabilityAvailable:` and `activateCapability:`; current registered capability is `passive.satella`.
- Passive implementation preserves P79.8f/P79.8d accepted names, `__TEXT vmaddr=0`, `0x847C`, `0x888C`, exact signatures, mapped-range safety, no-dlopen ownership, main-thread invocation, arm64e PAC and one-shot state.
- Existing `runtime.iap-noads` still writes `NNGG`/`NNGGNNGG` and updates `ImgTool.NeiGou` before delegating passive activation.
- CI contract results: `dispatcher-contract: PASS`, `p79.8d-passive-contract: PASS`, `p79.8f-p0-safety: PASS`, `p79.8g-runtime-capability: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- **Device validation:** user reported P79.8g testing normal on 2026-09-30. R2 runtime-capability extraction is promoted as the latest device-passed runtime/architecture baseline.
- P79.8f remains the closed P0 safety baseline and its contracts remain inherited by P79.8g.
- Separate P79.8c cloud-permission matrix and full P79.8b persistence regression remain independently tracked.

## 2026-09-30 — v1_p79_8f P0 Runtime/Authorization Safety Hardening — CI PASSED / P0 DEVICE PASSED
- Branch: `work/p79.8-udid-first-rebuild`.
- Passive mapped-range hardening: `b75adaa66982cbc3bf1b43aa13c441e88bf0c85b`.
- Authorization reset boundary guard: `033ff7f8f18b4e4894d582b5b02165d84d24bacc`.
- P0 contract test: `9a9a797db06c910e5f31633126fe7f8006585b66`.
- CI contract/workflow update: `7b1412434e13b56304d9c609c0b5b277259f8766`.
- VERSION/build commit: `67fbf755cf00623f3d0136668e103461d5189dae`; VERSION=`v1_p79_8f`.
- CI Run `36723643520` / #44: success.
- Artifact ID `11101797212`, digest `sha256:e16aa4bb55eb9e776c283d02da67eef78010f7f07df012c764e7a452a029ba6e`.
- Raw CI dylib SHA256: `b124e544b32674844bf7e9be9a35e0259e512063ce7b0113e5450c3a61535970`, size 3,263,040 bytes.
- Controlled final dylib SHA256: `18c443fb67440e7030b1b85fb82813c6d5aad52347cbf4aa3358313e00a84a6a`.
- Controlled final ZIP SHA256: `1e6ba1e2b3576673e645e787b83cadde1b6833f200dc621d527273ab6fbe0778`.
- Added mapped `__TEXT` validation before passive RVA signature reads/call.
- Added authorization-reset protected preference snapshot/verify/restore guard.
- Added `Tests/p79_8f_p0_safety_contract.py` for startup/reset/runtime safety boundaries.
- CI contract results: `dispatcher-contract: PASS`, `p79.8d-passive-contract: PASS`, `p79.8f-p0-safety: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- **Device validation:** user reported P79.8f testing normal on 2026-09-30. P79.8f is the current P0 device baseline.
- Separate P79.8c cloud-permission matrix and full P79.8b persistence regression remain independently tracked.

## 2026-09-30 — v1_p79_8e Architecture/Test Hardening — CI PASSED / DEVICE PENDING
- Removed an orphan capability declaration, refreshed Dispatcher tests to current service/coordinator routing, added the exact P79.8d passive contract test, and expanded active CI coverage.
- VERSION/build commit: `3050a4337ef481f6955b5f9d2000fcde8bd327d3`; CI Run `36718795572` / #40: success.
- Raw P79.8e and P79.8d dylibs were byte-for-byte identical, proving this stage changed verification infrastructure only.

## 2026-09-30 — v1_p79_8d Injected Passive Satella Trigger — CI PASSED / DEVICE PENDING
- Trigger implementation commit: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- Build commit: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`; CI Run `36604169367` / #38: success.
- Added ON-triggered activation of an already-injected passive target while preserving the existing IAP/iGameGod toggle behavior.
- Target compatibility contract: accepted image names, ctor RVA `0x847C`, init RVA `0x888C`, exact signatures, main-thread call, arm64e PAC, one-shot semantics and no host `dlopen`.

## 2026-09-29 — v1_p79_8c Server-Driven Menu Permissions — CI PASSED / DEVICE PENDING
- `basic`: `normal_menu=true`, `extra_menu=false`, `extra_features=false`; `app_plus/global_plus` have all three true.
- `VIP云存档` requires `extra_menu` for visibility and `extra_features` for action; cloud download performs fresh Verify before archive resolution/download.

## 2026-09-29 — v1_p79_8b Persistence Cleanup — CI PASSED / DEVICE PENDING
- AuthV2 response/config/card state became session-only; `DZUDID` remains long-lived; existing menu/runtime defaults were deliberately preserved.

## 2026-09-29 — v1_p79_8a Clean UDID-First Rebuild — CI PASSED / DEVICE PASSED
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`; CI Run `36572203902` / #32: success.
- Real-device validation: PASS. Fresh App + already-activated UDID works without card re-entry.

## Earlier retained milestones
- P79.7 auth semantics/reset scope: CI passed, device pending.
- P79.6 server-driven auth activation gate: CI passed, device pending.
- P64a runtime directory cleanup fix: device passed/promoted.
- P60 UDID acquisition progress/manual retry: device passed.
- P58 download lifecycle hardening: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P51/P51-B feature routing and backup refactor: device passed.
- P50 architecture freeze: completed.
- P49 active-target/dependency audit: device passed.
