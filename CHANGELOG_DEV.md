# CHANGELOG_DEV

## 2026-09-29 — v1_p79_8 Same-Card/Same-UDID License Query — CI PASSED / DEVICE PENDING
- Main P79 work branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- Build/version commit: `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36560746520` / run #27: success.
- Artifact ID `11028839445`, digest `sha256:e76c0494f8c69668ab99001eea0a9a502ec46d47f96596742bbbeb2b8577a1f3`.
- Raw CI dylib SHA256: `590f6a67e5e4faf9d6c9a2c6f6910884cbff4a15e5cf6c205fe3536be20fb9cc`.
- P79.7 device result showed the same card already bound to the current UDID still returned `解锁码已使用`.
- Root cause: P79.7 used the retired `/authorization` compatibility surface as a binding probe. It did not yield the structured Bound evidence expected by the client, so the flow fell back to `/appstore`, whose current one-time activation contract rejects any `jh=1` card as `解锁码已使用`.
- P79.8 replaces that probe with POST `/index/index/license`; the server controller uses `AuthorizationLicense::query(code, udid)`, requiring exact `kami + udid + jh=1` and an active authorization.
- Only that exact active binding may skip `/appstore` and continue to Runtime Config + Verify. New/unused/mismatched/expired cards retain the canonical P79.6 activation path.
- A generic `解锁码已使用` response is never treated as authorization evidence.
- App-mismatch prompt routing and broadened current-process-visible Keychain reset behavior from P79.7 remain in place.
- Raw CI build reported `verify_secret_configured=0`; source remains placeholder-only.
- Controlled final test artifact received equal-length post-build injection of the user-provided test Verify Secret into both arm64/arm64e slices: placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ from the raw CI binary.
- Controlled final test dylib SHA256: `12cac6f3a9b7ce9da1ad5f27f9364606c42f52eb3311dd36e2308c5cd8a8f723`.
- Real/test Verify Secret is intentionally not committed to public Git history.
- Device validation starts with same-card + same-UDID reuse, then wrong/unused card, App mismatch, success continuation, and authorization reset scope.

## 2026-09-29 — v1_p79_7 Auth Semantics + Reset Scope — CI PASSED / DEVICE FAILED
- Development branch: `work/p79.7-auth-semantics-reset-scope`; main P79 work branch fast-forwarded without force.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / run #25: success.
- Artifact ID `11016299418`, digest `sha256:048d839f1080890618f342885f12ae2e28d30884463f3f0e29c74f20af77aa1e`.
- Raw CI dylib SHA256: `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- Added `ZONAuthV2BindingProbe` using the compatibility `/authorization` endpoint. This choice was invalid for the formal auth flow and is superseded by P79.8.
- Device failure: same card + same UDID still returned `解锁码已使用` because the probe did not confirm Bound and the flow fell back to `/appstore`.
- `Authorization does not apply to this App` / `app_not_authorized` is treated as a card-input validation failure: clear the saved card and return to the original card prompt instead of showing a separate terminal alert.
- Authorization reset deletes complete authorization-related Generic Password services visible to the current process rather than only selected accounts. This can cover records exposed through an actually shared Keychain access group, but cannot delete another App's isolated access group without matching entitlements or a server-side revoke API.
- Raw CI build reported `verify_secret_configured=0`; source remained placeholder-only.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.

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

## 2026-09-21 — P64 Clear Game Data Dedicated Service — CI PASSED / DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; this was a naming error. Canonical stage is P64.
- Actual build SHA: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- CI Run `35522283236`: success.
- Added `ZONGameDataResetService` as a pure Foundation reset engine.
- Removed both historical 5-second clear-game-data timers.
- Added background cleanup, real stage display, explicit NSError propagation, verification, and success-controlled exit.
- Device test found that `Library/Caches` may remain/in-use while the app was alive; P64 incorrectly treated that runtime directory removal failure as fatal.
- P64 was not promoted and is superseded by P64a.

## 2026-09-20 — P63 Six Button Service Boundary — DEVICE PASSED
- Historical built VERSION string: `v1_p63a`; canonical stage is P63.
- Runtime source commit: `170f006d7bdf3aa1ef0f51df7f81d21a86b73b7d`.
- CI Run `35483209464`: success.
- Added `ZONSixButtonActionService` and routed all six scoped actions through it.
- A_customer and B_debug `arm64 + arm64e`: PASS.
- User explicitly reported all six scoped buttons normal on device.
- Superseded as promoted baseline by P64a.

## 2026-09-20 — P62 Authorization Reset Service — DEVICE PASSED / SUPERSEDED
- Source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: success.
- Authorization reset extracted into `ZONAuthorizationResetService`.
- Device validation passed; superseded by P63 and later P64a.

## Version naming rule correction
- New stage increments the number: `P63 → P64 → P65`.
- Same-stage fixes use suffixes: `P64a → P64b → P64c`.
- Existing commits/artifacts are not rewritten; canonical project records correct the mistaken historical P63a/P63b labels.

## Earlier architecture cleanup
- P60 UDID acquisition progress/manual retry: device passed.
- P58 download lifecycle hardening: device passed.
- P56 PubgLoad temp-boundary cleanup: device passed.
- P51/P51-B feature routing and backup refactor: device passed.
- P50 architecture freeze: completed.
- P49 active-target/dependency audit: device passed.
