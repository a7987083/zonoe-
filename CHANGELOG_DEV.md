# CHANGELOG_DEV

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
- Binary validation: universal arm64 + arm64e (PAC00); `P79.8D_SATELLA` marker count 18; all three target image names present in both slices.
- Controlled final artifact: placeholder remaining `0`, Verify Secret occurrences `2`, 128 bytes differ from raw CI binary.
- Device test priority: matching injected passive build starts exactly once; absent/mismatched build does not crash or break the existing toggle; verify arm64e invocation and inherited P79.8c/P79.8b/P79.8a regressions.

## 2026-09-29 — v1_p79_8c Server-Driven Menu Permissions — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Feature permission metadata commit: `dffe27a0f5101591d0a57774cf0041b64f06349d`.
- Menu filter commit: `0d7c93c434084c260e240b824980cdb684fd25c9`.
- Action permission commit: `dd75f3f6267390268b12e467b03efa83d78f5d7d`.
- Fresh cloud Verify commit: `dbe02798bd0e2d5e4d55bde950100d510d40a93e`.
- VERSION/build commit: `4a2c35923c646917e912ca0758294df98460cccd`; VERSION=`v1_p79_8c`.
- CI Run `36591707184` / #37: success.
- Artifact ID `11043668689`, digest `sha256:c6e1f80c902508e27d527a4079f2d72ad53767438ca24278405010d93f22a66e`.
- Raw CI dylib SHA256: `de3be9f75f5fb6639c84c283252bd5e184b1cde0d512b1cc3ca6c48ba314c153`.
- Controlled final dylib SHA256: `7d8c80d317810eb4331db02fa216697f3c869fdfa7cacbfb0499c936d60f1651`.
- Verified backend permission semantics from `DylibRuntimeAccessService`: `basic` has `normal_menu=true`, `extra_menu=false`, `extra_features=false`; `app_plus/global_plus` have all three true.
- Client consumes the server `permissions` dictionary rather than deriving cloud-save rights from card scope/type.
- `base.cloud-save` requires `extra_menu` for menu visibility and `extra_features` for action execution.
- Cloud download performs fresh Verify v2 before archive URL resolution/download.
- Current cloud route no longer uses the legacy `app.zonoeios.xyz /apiface` entitlement request; legacy compatibility code may still contain the old hostname string.
- P79.8a UDID-first authorization and P79.8b persistence semantics were preserved.

## 2026-09-29 — v1_p79_8b Persistence Cleanup — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline is the device-passed P79.8a UDID-first authorization flow.
- Storage contract commit: `78da327ef11946d8502e77b023d1f8b823c2fad1`.
- Storage implementation commit: `1b099d83da7ae00a5773279f755110f0c441b4d3`.
- Authorization cleanup integration: `d97e78c8bdedbf8efa0b87b77a0c18bf8b9266ea`.
- Reset-service cleanup integration: `4a5888613f7c2c5b76e5191d2c42a9a60e491890`.
- VERSION/build commit: `19d5d1e0204c84f56fc2ee330bb2371d3511d367`; VERSION=`v1_p79_8b`.
- CI Run `36585791709` / #36: success.
- Controlled final dylib SHA256: `e363256b06e7842090103f95cc5edd14066b7eb50f144768fcd38882255bd62c`.
- AuthV2 `udid`, `card`, `lastVerify`, `lastActivation`, `lastRuntimeConfig`, and `lastBootstrap` became session-only.
- `DZUDID` remains the sole long-lived device identity used by authorization.
- Existing menu/runtime `NSUserDefaults` keys were deliberately untouched.
- Only `zonoe.auth.v2.lastNoticeFingerprint` is retained persistently by AuthV2 for notice de-duplication.

## 2026-09-29 — v1_p79_8a Clean UDID-First Rebuild — CI PASSED / DEVICE PASSED
- Branch: `work/p79.8-udid-first-rebuild`.
- Rebuilt directly from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`; P79.9/P79.10 startup experiments are not inherited.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- Removed `ZONAuthV2BindingProbe.m` swizzle from the compiled runtime path: `dce8c905960256d6e73dcdb62d42060f56660558`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`; VERSION=`v1_p79_8a`.
- CI Run `36572203902` / #32: success.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Restored the legacy-proven startup contract: obtain/persist UDID first, then query `/index/index/apiface` by UDID before consulting local card state.
- Active device authorization proceeds directly to Runtime Config + Verify without card prompt.
- Real-device validation: PASS. User confirmed a freshly installed App on an already-activated UDID no longer prompts for a card and the flow works normally.

## 2026-09-29 — v1_p79_7 Auth Semantics + Reset Scope — CI PASSED / DEVICE PENDING
- Development branch: `work/p79.7-auth-semantics-reset-scope`.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / #25: success.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.

## 2026-09-29 — v1_p79_6 Server-Driven Auth Activation Gate — CI PASSED / DEVICE PENDING
- Main work branch: `work/p79-server-driven-auth-isolation-v1`.
- Restored activation contract: `/apiface before → /appstore → /apiface after → authorization + state-change gate → Runtime Config → Verify v2`.
- CI Run `36523256192` / #24: success.
- Controlled final test dylib SHA256: `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / PROMOTED
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- P64a remains an older known-good rollback point, superseded for authorization behavior by device-passed P79.8a.

## Version naming rule correction
- New stage increments the number: `P63 → P64 → P65`.
- Same-stage fixes use suffixes: `P64a → P64b → P64c`.
- Existing commits/artifacts are not rewritten; canonical project records correct mistaken historical labels.

## Earlier architecture cleanup
- P60 UDID acquisition progress/manual retry: device passed.
- P58 download lifecycle hardening: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P51/P51-B feature routing and backup refactor: device passed.
- P50 architecture freeze: completed.
- P49 active-target/dependency audit: device passed.
