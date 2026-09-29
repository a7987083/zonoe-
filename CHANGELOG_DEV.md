# CHANGELOG_DEV

## 2026-09-29 — v1_p79_8a Clean UDID-First Rebuild — CI PASSED / DEVICE PENDING
- Branch: `work/p79.8-udid-first-rebuild`.
- Rebuilt directly from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`; P79.9/P79.10 startup experiments are not inherited.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- Removed `ZONAuthV2BindingProbe.m` swizzle from the compiled runtime path: `dce8c905960256d6e73dcdb62d42060f56660558`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`; VERSION=`v1_p79_8a`.
- CI enable/build HEAD: `3ab9fc3879930b7d89770ca95f6e7636dc0119d3`.
- CI Run `36572203902` / #32: success.
- Artifact ID `11036215202`, digest `sha256:639403f138acece3089e3460e7606752d55364115b3e1e8c404cdb8f941033b2`.
- Raw CI dylib SHA256: `188e25b8c8d76653baffb01e01cd8931302d2ca6d0e67a07d18fee1bd80a894a`.
- Restored the legacy-proven startup contract: obtain/persist UDID first, then query `/index/index/apiface` by UDID before consulting local card state.
- Active device authorization is recognized from the existing signed API response contract (`code=1`, `msg=ok`, unexpired `expire`). A fresh App with an already-active UDID proceeds directly to Runtime Config + Verify and does not show a card prompt.
- `/apiface` is only the device-activation check. Current-App applicability, `access_level` and `permissions` remain server/Verify-owned and are consumed after Verify.
- Explicit no-record or expired authorization opens the card prompt. Network/server/unknown payloads are not treated as proof of missing activation.
- First activation still uses `/apiface before → /appstore → /apiface after → active + stateChanged → Runtime Config → Verify`, allowing a replacement card to add authorization even when the UDID already has another active scope.
- App-mismatch handling was moved into the direct `ZONAuthV2Flow` implementation so it no longer depends on the retired swizzle.
- Binary validation: arm64 + arm64e; `P79.8A_UDID_GATE` present in both slices; old `P79.8_BINDING_GATE` marker count `0`; old `P79.8_LICENSE_PROBE` marker count `0`.
- Raw CI reported `verify_secret_configured=0`; controlled final artifact uses equal-length test Verify Secret injection in both slices. Placeholder remaining `0`, Secret occurrences `2`.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Device priority test: fresh App + previously activated UDID must skip card input and reach Verify.

## 2026-09-29 — v1_p79_7 Auth Semantics + Reset Scope — CI PASSED / DEVICE PENDING
- Development branch: `work/p79.7-auth-semantics-reset-scope`; main P79 work branch fast-forwarded without force.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / run #25: success.
- Artifact ID `11016299418`, digest `sha256:048d839f1080890618f342885f12ae2e28d30884463f3f0e29c74f20af77aa1e`.
- Raw CI dylib SHA256: `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- Added `ZONAuthV2BindingProbe`: before re-activating a card on an already-authorized UDID, query the compatibility `/authorization` endpoint with `code + udid`; only structured same-binding evidence may skip `/appstore` and continue to Verify. Unknown/not-bound results keep the strict P79.6 activation path.
- `Authorization does not apply to this App` / `app_not_authorized` is now treated as a card-input validation failure: clear the saved card and return to the original card prompt instead of showing a separate terminal alert.
- Authorization reset now deletes complete authorization-related Generic Password services visible to the current process rather than only selected accounts. This can cover records exposed through an actually shared Keychain access group, but cannot delete another App's isolated access group without matching entitlements or a server-side revoke API.
- Raw CI build still reported `verify_secret_configured=0`; source remains placeholder-only.
- Controlled final test artifact received equal-length post-build injection of the user-provided test Verify Secret into both arm64/arm64e slices: placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ from raw CI binary.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- Real/test Verify Secret is intentionally not committed to public Git history.
- Device validation required for: same card + same UDID reuse, wrong/nonexistent card prompt behavior, App mismatch returning to the same prompt, and authorization reset behavior across Apps/access groups.

## 2026-09-29 — v1_p79_6 Server-Driven Auth Activation Gate — CI PASSED / DEVICE PENDING
- Main work branch: `work/p79-server-driven-auth-isolation-v1`.
- Development branch: `work/p79.6-saved-card-ci-contract`.
- Restored the successful standalone auth flow's activation contract: `/apiface` before state → `/appstore` transport request → `/apiface` after state → authorization + state-change gate → Runtime Config → Verify v2.
- Added `ZONLicenseIsAuthorized`, authorization projection/fingerprint comparison, and explicit `stateChanged` gating before Verify.
- Invalid/unchanged activation no longer falls through to Verify and gets collapsed into `Authorization does not apply to this App`.
- Saved-card flow now also rejects HTTP-200 `/apiface` payloads whose authorization content is invalid; card is cleared while UDID is preserved.
- Transient network/server failures still preserve the saved card.
- Added stage logs: `BEFORE_LICENSE`, `APPSTORE`, `AFTER_LICENSE`, `ACTIVATION_GATE`, `VERIFY_CONFIG`, `VERIFY`; logs do not print Verify Secret/signature.
- Activation-gate commit: `ad7fc577bb52b02a1c5cecaa74ef263c1f19a6a9`.
- Build/version commit: `ac948369ceba488ece11deb8730d8a9510687f44`.
- VERSION: `v1_p79_6`.
- CI Run `36523256192` / run #24: success.
- Artifact ID `11014190087`, digest `sha256:f5170fc97de9990c5be38ad04cb9d59831ca6ffc00cea796da6876cc3aa169f3`.
- CI artifact dylib SHA256: `73ace8affac76960efc6f4fb060d4551a9c111ff3208e97ea0c64d7ff1dbc444`.
- CI reported `verify_secret_configured=0`; therefore the raw CI artifact is not the final Verify test artifact.
- Controlled final test artifact uses equal-length post-build injection of the user-provided test Verify Secret into both arm64/arm64e slices; placeholder remaining: 0; final SHA256: `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.
- Real/test Verify Secret is intentionally not committed to the public repository.
- Device validation is still required before promotion.

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / PROMOTED
- Branch: `work/p64a-clear-game-data-runtime-directory-fix`.
- Actual build SHA: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Fixed P64 device failure where `Library/Caches` could not be removed while the process was alive.
- Replaced the invalid success criterion “Library/tmp must contain zero child directories” with payload-aware verification.
- Standard/runtime directory skeletons may remain when empty.
- `Library/Caches` and `tmp` are volatile runtime locations: cleanup is attempted, but runtime-created cache residue is not treated as user/game payload.
- Non-volatile business files still produce a real failure if they remain after cleanup/verification.
- `Documents` payload deletion remains strict.
- Existing stage display, background execution, no-5-second behavior, completion-controlled exit and error reporting are preserved.
- Added `Tests/p64a_game_data_runtime_directory_contract.py`.
- Added dedicated P64a A/B CI workflow.
- A_customer `arm64 + arm64e`: PASS. Artifact `10608274021`, digest `sha256:5cc2772e8fb2794a1301ca79526ea9a375ae5686c92e9040609eb9009ab20302`, dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug `arm64 + arm64e`: PASS. Artifact `10608289075`, digest `sha256:c6296cb2d5ee1114501e9f35eda7e5c9cef76e9bc2657d126accb79e9bdedff8`, dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- User explicitly reported the P64a real-device regression fully normal.
- **P64a is promoted/device-passed and remains the last device-verified rollback baseline.**

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
