# CHANGELOG_DEV

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
- Passive runtime safety: parse `LC_SEGMENT_64`, require matching `__TEXT`, `vmaddr=0`, readable + executable initial protections, and ensure ctor/init signature ranges are inside mapped `vmsize` before any `memcmp(base + RVA)`.
- Invalid/malformed target now fails closed with `[P79.8F_P0_SATELLA] text_range_mismatch` before signature dereference or indirect call.
- Exact P79.8d accepted names, `0x847C`, `0x888C`, signatures, no-dlopen ownership, main-thread invocation, arm64e PAC, one-shot behavior, and missing-target no-rollback semantics remain unchanged.
- Authorization reset snapshots `fold_base`, `fold_draw`, `fold_role`, `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`, `AADDssppeedd`; boundary crossing restores the snapshot and returns failure.
- Added `Tests/p79_8f_p0_safety_contract.py` covering passive mapped-range ordering, authorization-reset preference boundary, current game-data reset scope, startup network-error-before-card-prompt routing, and unknown-payload card-prompt suppression.
- CI contract results: `dispatcher-contract: PASS`, `p79.8d-passive-contract: PASS`, `p79.8f-p0-safety: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final injection changed exactly 128 bytes in the two equal-length Secret placeholder regions; placeholder remaining `0`, Secret occurrences `2`.
- **Device validation:** user reported P79.8f testing normal on 2026-09-30. P79.8f is promoted to the current P0 device baseline.
- P0 acceptance covers the startup/authorization safety path, authorization-reset protected-key boundary, intended game-data reset scope, and passive runtime safe-call/no-target behavior exercised in this test cycle.
- Separate P79.8c cloud-permission matrix and full P79.8b persistence regression remain independently tracked; they are not implicitly promoted by the P0 test result.
- Next engineering stage: P1/R2 Runtime Capability extraction, preserving the P79.8f device-passed contract exactly.

## 2026-09-30 — v1_p79_8e Architecture/Test Hardening — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- P79.8e intentionally changes verification infrastructure, not production runtime behavior.
- Removed the orphan `ZONInjectedPassiveSatellaAvailable` declaration that had been added after the P79.8d verified build without an implementation/use: `32897a07183d5edf5f92b869adaacbd1c51dd706`.
- Updated the active Dispatcher contract from obsolete direct legacy handlers to current service/coordinator routing: `3b515b2a8b8711b34a0ac50572483698a2ded4e7`.
- Added `Tests/p79_8d_passive_satella_contract.py` covering accepted image names, exact RVAs/signatures, dyld-only preload ownership, arm64e PAC, main-thread invocation, one-shot behavior and no rollback of the existing toggle: `4cde12d33974580357c4cff777bd98a6661365b4`.
- Expanded the active P79 workflow so `ZONCore`, `ZONServices`, project-file and current test changes trigger verification; the current contracts now execute before Xcode build: `afdb84de03eb012ab4fd93a0ebf307a9b06951d0`.
- VERSION/build commit: `3050a4337ef481f6955b5f9d2000fcde8bd327d3`; VERSION=`v1_p79_8e`.
- CI Run `36718795572` / #40: success.
- Artifact ID `11096879463`, digest `sha256:83c8e47a9eb1a679d8a56eef69bdc0c48e6e475042f526600d5070391ec88eef`.
- Dispatcher current-service-routing contract: PASS.
- P79.8d passive runtime contract: PASS.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Raw CI dylib SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`, size 3,246,160 bytes.
- Raw P79.8d and P79.8e dylibs were compared byte-for-byte with `cmp`; result is identical. This proves P79.8e did not alter product runtime bytes.
- Refreshed `ARCHITECTURE.md` and `REFACTOR_REVIEW.md` to the current P79 tree and recorded the next staged refactors: runtime capability boundary, feature-access context, typed registry descriptors, AuthV2Flow decomposition, startup measurement, then repository/test hygiene.

## 2026-09-30 — v1_p79_8d Injected Passive Satella Trigger — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Trigger implementation commit: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- VERSION/build commit: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`; VERSION=`v1_p79_8d`.
- CI Run `36604169367` / #38: success.
- Artifact ID `11050622646`, digest `sha256:16569dbb378372b5372dea8e3312549d1fe632f3b85b831dc3d8027ffb445b6e`.
- Raw CI dylib SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Controlled final dylib SHA256: `bd5b3ca738d6e8041d16b57c4515dffb6f47806da412b0b5f8bd512e1f09d6cd`.
- Controlled final ZIP SHA256: `242a461d27a16a8758c750dbc8ac65ac12f28704996d39d8df9051e5922da3d6`.
- Added an ON-trigger to existing `runtime.iap-noads` / `内购破解+ iGameGod去广告` without changing its original `NNGG`, `NNGGNNGG`, or `ImgTool.NeiGou` behavior.
- Per final requirement, P79.8d never `dlopen`s or loads Satella. The target passive dylib must already be injected and visible in dyld.
- Recognized target names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Before invocation, validate image base + `0x847C` is ARM64 `RET` (`C0 03 5F D6`) and image base + `0x888C` matches the supplied 16-byte init prologue.
- After validation, invoke image base + `0x888C` on the main thread. arm64e uses function-pointer PAC signing before the indirect call.
- Initialization is one-shot per process. Repeated ON events log `already_started`; OFF performs no unload/deinit.
- Missing/invalid target is fail-closed for the Satella call but does not revert the existing IAP/iGameGod toggle.

## 2026-09-29 — v1_p79_8c Server-Driven Menu Permissions — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Feature permission metadata commit: `dffe27a0f5101591d0a57774cf0041b64f06349d`.
- Menu filter commit: `0d7c93c434084c260e240b824980cdb684fd25c9`.
- Action permission commit: `dd75f3f6267390268b12e467b03efa83d78f5d7d`.
- Fresh cloud Verify commit: `dbe02798bd0e2d5e4d55bde950100d510d40a93e`.
- VERSION/build commit: `4a2c35923c646917e912ca0758294df98460cccd`; VERSION=`v1_p79_8c`.
- CI Run `36591707184` / #37: success.
- Artifact ID `11043668689`, digest `sha256:c6e1f80c902508e27d527a4079f2d72ad53767438ca24278405010d93f22a66e`.
- `basic`: `normal_menu=true`, `extra_menu=false`, `extra_features=false`; `app_plus/global_plus` have all three true.
- `VIP云存档` requires `extra_menu` for visibility and `extra_features` for action; cloud download performs fresh Verify before archive resolution/download.

## 2026-09-29 — v1_p79_8b Persistence Cleanup — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- AuthV2 `udid`, `card`, `lastVerify`, `lastActivation`, `lastRuntimeConfig`, and `lastBootstrap` became session-only.
- `DZUDID` remains the sole long-lived device identity used by authorization.
- Existing menu/runtime `NSUserDefaults` keys were deliberately untouched.
- Only `zonoe.auth.v2.lastNoticeFingerprint` is retained persistently by AuthV2 for notice de-duplication.

## 2026-09-29 — v1_p79_8a Clean UDID-First Rebuild — CI PASSED / DEVICE PASSED
- Branch: `work/p79.8-udid-first-rebuild`.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`; VERSION=`v1_p79_8a`.
- CI Run `36572203902` / #32: success.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
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
