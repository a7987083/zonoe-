# CHANGELOG_DEV

## 2026-09-29 — v1_p79_8b Persistence Cleanup — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline is the device-passed P79.8a UDID-first authorization flow; authorization decision semantics were intentionally not changed.
- Storage contract commit: `78da327ef11946d8502e77b023d1f8b823c2fad1`.
- Storage implementation commit: `1b099d83da7ae00a5773279f755110f0c441b4d3`.
- Authorization cleanup integration: `d97e78c8bdedbf8efa0b87b77a0c18bf8b9266ea`.
- Reset-service cleanup integration: `4a5888613f7c2c5b76e5191d2c42a9a60e491890`.
- VERSION/build commit: `19d5d1e0204c84f56fc2ee330bb2371d3511d367`; VERSION=`v1_p79_8b`.
- CI Run `36585791709` / #36: success.
- Artifact ID `11041556869`, digest `sha256:18b44f1ff221d9a2582291c30a5b145166f4e954e831158bd82bf0a41716a82a`.
- Raw CI dylib SHA256: `b6c3333cbce0b0ff508a11ac31a6d81ce180db4c1afd3360e86d0ed5a9ce7045`.
- AuthV2 `udid`, `card`, `lastVerify`, `lastActivation`, `lastRuntimeConfig`, and `lastBootstrap` are now session-only and do not survive process exit.
- `DZUDID` remains the sole long-lived device identity used by authorization.
- Upgrade migration purges old AuthV2 response/config persistence plus legacy authorization defaults (`到期时间`, `卡密`, `公告`, `zonoeudid`, `解锁码到期时间`, `到期弹窗`).
- Completed UDID bridge residue (`value`, `scheme`, request nonce/timestamp) is removed after `DZUDID` is confirmed.
- Existing menu/runtime `NSUserDefaults` keys are deliberately untouched.
- The only AuthV2 preference intentionally retained across launches is `zonoe.auth.v2.lastNoticeFingerprint`, used only to suppress repeated presentation of the same notice.
- Raw CI build still contains the placeholder Verify Secret; controlled final artifact received equal-length injection into both arm64/arm64e slices. Placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ from raw CI binary.
- Controlled final dylib SHA256: `e363256b06e7842090103f95cc5edd14066b7eb50f144768fcd38882255bd62c`.
- Device test priority: verify Preferences cleanup, menu-state persistence, one-time notice behavior, and no regression of P79.8a UDID-first authorization.

## 2026-09-29 — v1_p79_8a Clean UDID-First Rebuild — CI PASSED / DEVICE PASSED
- Branch: `work/p79.8-udid-first-rebuild`.
- Rebuilt directly from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`; P79.9/P79.10 startup experiments are not inherited.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- Removed `ZONAuthV2BindingProbe.m` swizzle from the compiled runtime path: `dce8c905960256d6e73dcdb62d42060f56660558`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`; VERSION=`v1_p79_8a`.
- CI Run `36572203902` / run #32: success.
- Artifact ID `11036215202`, digest `sha256:639403f138acece3089e3460e7606752d55364115b3e1e8c404cdb8f941033b2`.
- Raw CI dylib SHA256: `188e25b8c8d76653baffb01e01cd8931302d2ca6d0e67a07d18fee1bd80a894a`.
- Restored the legacy-proven startup contract: obtain/persist UDID first, then query `/index/index/apiface` by UDID before consulting local card state.
- Active device authorization is recognized from `code=1`, `msg=ok`, unexpired `expire`; active UDID proceeds directly to Runtime Config + Verify without card prompt.
- `/apiface` remains the device-activation check; Verify owns current-App applicability, `access_level`, and `permissions`.
- Explicit no-record or expired authorization opens the card prompt; network/server/unknown payloads do not.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Real-device validation: PASS. User confirmed a freshly installed App on an already-activated UDID no longer prompts for a card and the flow works normally.

## 2026-09-29 — v1_p79_7 Auth Semantics + Reset Scope — CI PASSED / DEVICE PENDING
- Development branch: `work/p79.7-auth-semantics-reset-scope`; main P79 work branch fast-forwarded without force.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / run #25: success.
- Artifact ID `11016299418`, digest `sha256:048d839f1080890618f342885f12ae2e28d30884463f3f0e29c74f20af77aa1e`.
- Raw CI dylib SHA256: `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- Added `ZONAuthV2BindingProbe`: before re-activating a card on an already-authorized UDID, query the compatibility `/authorization` endpoint with `code + udid`; only structured same-binding evidence may skip `/appstore` and continue to Verify.
- `Authorization does not apply to this App` / `app_not_authorized` is treated as a card-input validation failure: clear the saved card and return to the original card prompt instead of showing a separate terminal alert.
- Authorization reset deletes complete authorization-related Generic Password services visible to the current process rather than only selected accounts.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.

## 2026-09-29 — v1_p79_6 Server-Driven Auth Activation Gate — CI PASSED / DEVICE PENDING
- Main work branch: `work/p79-server-driven-auth-isolation-v1`.
- Restored activation contract: `/apiface` before state → `/appstore` → `/apiface` after state → authorization + state-change gate → Runtime Config → Verify v2.
- VERSION: `v1_p79_6`.
- CI Run `36523256192` / run #24: success.
- Artifact ID `11014190087`.
- Controlled final test dylib SHA256: `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / PROMOTED
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Fixed P64 device failure where `Library/Caches` could not be removed while the process was alive.
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
