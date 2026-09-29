# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → scoped tests/workflow.

## Current work target — P79.6 Server-Driven Auth Activation Gate
- Main work branch: `work/p79-server-driven-auth-isolation-v1`.
- Development branch: `work/p79.6-saved-card-ci-contract`.
- VERSION: `v1_p79_6`.
- Activation-gate commit: `ad7fc577bb52b02a1c5cecaa74ef263c1f19a6a9`.
- Build/version commit: `ac948369ceba488ece11deb8730d8a9510687f44`.
- CI Run `36523256192` / run #24: SUCCESS.
- Artifact ID: `11014190087`.
- CI artifact digest: `sha256:f5170fc97de9990c5be38ad04cb9d59831ca6ffc00cea796da6876cc3aa169f3`.
- Raw CI dylib SHA256: `73ace8affac76960efc6f4fb060d4551a9c111ff3208e97ea0c64d7ff1dbc444`.
- Raw CI build info reported `verify_secret_configured=0`; do **not** use the raw CI dylib for Verify acceptance testing.
- Controlled final test dylib has the user-provided test Verify Secret injected into both arm64/arm64e slices with equal-length replacement; placeholder remaining = 0.
- Controlled final test dylib SHA256: `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.
- Real/test Verify Secret must never be committed to the public repository; keep source placeholder-only and inject in the controlled final artifact or via Actions Secret.

## P79.6 auth contract
First activation must remain:

`/apiface before → /appstore → /apiface after → authorized + stateChanged gate → Runtime Config → Verify v2 → success/notice/update/icon`

The gate restored from the successful standalone auth project is mandatory:
- Determine `beforeAuthorized` from the pre-activation `/apiface` payload.
- Fingerprint authorization-relevant fields before activation.
- Treat `/appstore` HTTP success as transport success only; do not infer business activation from legacy numeric `code` alone.
- Fetch `/apiface` again.
- Require `afterAuthorized == YES`.
- Require authorization fingerprint change when the UDID was already authorized before activation.
- Only then enter Runtime Config + Verify v2.

Saved-card flow:
- `/apiface` 4xx authorization rejection clears card only and preserves UDID.
- `/apiface` HTTP 200 with invalid authorization content also clears card only and returns to card input.
- Network failures, 5xx, 408, 425 and 429 preserve the saved card.
- Valid saved authorization proceeds to Verify v2 without `/appstore` reactivation.

## Verify protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key`: `zonoe.main`
- `dylib_version`: `1`
- `dylib_build`: empty string
- Protocol version: `2`
- Source file `ZONAuthV2Verify.m` intentionally retains a fixed-length placeholder Secret.

## P79.6 logs added
- `[AUTH][BEFORE_LICENSE]`
- `[AUTH][APPSTORE]`
- `[AUTH][AFTER_LICENSE]`
- `[AUTH][ACTIVATION_GATE]`
- `[AUTH][VERIFY_CONFIG]`
- `[AUTH][VERIFY]`
- Do not log Verify Secret or HMAC signature.

## Required real-device verification before promotion
1. Nonexistent/invalid card remains in card input and does not enter Verify.
2. Used/mismatched card remains in card input with server-derived message.
3. Valid new card produces an authorization-state change before Verify starts.
4. Valid activation reaches Verify v2, then success → notice → app_update → icon flow.
5. Saved valid card opens through `/apiface → Verify` without reactivation.
6. Expired/revoked/invalid saved authorization clears card but preserves UDID.
7. Network/server transient failure does not clear saved card.
8. If a valid authorization still receives `Authorization does not apply to this App`, inspect server `app_identity` / target bundle mapping rather than bypassing the Verify decision.

## Last promoted/device baseline — P64a
- VERSION: `v1_p64a`.
- Runtime/build source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- A_customer dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- Real-device validation: PASS, explicitly reported by user.
- P64a remains the rollback/device baseline until P79.6 is device-verified and explicitly promoted.

## Long-project rules
- Preserve commit history.
- Do not silently alter release policy.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
