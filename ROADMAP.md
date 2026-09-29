# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.6 Server-Driven Auth Activation Gate — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_6`.
- Main branch: `work/p79-server-driven-auth-isolation-v1`.
- Development branch: `work/p79.6-saved-card-ci-contract`.
- Core fix: restore the standalone-project activation state machine before Verify v2.
- Required sequence: `/apiface before → /appstore → /apiface after → authorized + stateChanged gate → Runtime Config → Verify v2`.
- `/appstore` HTTP success is transport success only; do not infer business activation from legacy numeric `code` alone.
- Saved-card `/apiface` HTTP 200 must still contain a valid authorization before Verify is entered.
- Activation-gate commit: `ad7fc577bb52b02a1c5cecaa74ef263c1f19a6a9`.
- Build/version commit: `ac948369ceba488ece11deb8730d8a9510687f44`.
- CI Run `36523256192`: success.
- Raw CI artifact ID `11014190087`; raw CI dylib SHA256 `73ace8affac76960efc6f4fb060d4551a9c111ff3208e97ea0c64d7ff1dbc444`.
- CI did not have a repository Verify Secret (`verify_secret_configured=0`).
- Controlled test dylib uses post-build equal-length injection of the user-provided test Verify Secret; placeholder remaining = 0; final SHA256 `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.
- Public source remains placeholder-only; do not commit the real/test Secret.

### P79.6 promotion gates
- Invalid/nonexistent card does not enter Verify and stays in card prompt.
- Used/mismatched card shows the server-derived activation error.
- Valid new card changes `/apiface` authorization state before Verify starts.
- Valid activation passes Verify v2 and continues success → notice → update → icon.
- Saved valid card runs `/apiface → Verify` without reactivation.
- Expired/revoked saved authorization clears card but preserves UDID.
- Transient network/5xx/408/425/429 does not clear saved card.
- If a genuinely authorized card still fails with `Authorization does not apply to this App`, audit server app-identity/bundle mapping; do not bypass Verify.
- Real-device validation required before promotion.

## Verify protocol baseline
- Bootstrap URL: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- Dylib key: `zonoe.main`
- Dylib version: `1`
- Dylib build: empty string
- Protocol version: `2`

## Last promoted runtime baseline — P64a / DEVICE PASSED
- Version: `v1_p64a`.
- Runtime/build source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- A_customer dylib SHA256 `34ef87c5be956e81764984a524c0c04428bbc83a4949e23dbc4ba19f10cfbaf9`.
- B_debug dylib SHA256 `335f0e3028a6bf2f9e202681487822065bdda6598a853889f9c973cd9616b379`.
- Real-device validation: PASS.
- P64a remains the rollback/device baseline until a later stage is explicitly promoted.

## Historical planned/refactor stages
### P65 — Backup Engine Refactor
- Extract backup execution from `daochucd` behind a clean `ZONBackupService` boundary.
- Preserve archive/restore compatibility.
- Consolidate scanning/copy/staging policy and surface filesystem errors.

### Follow-on
- P66 — Restore engine extraction from `YYYPicker`.
- P67 — Remote Download engine extraction from `PubgLoad`.
- P68 — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history.
3. New functional stages increment numeric version; suffix letters are fixes only.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.
6. Real/test Verify Secret must not be committed to public source or printed in logs.

# Next Task
Install the controlled `v1_p79_6` secret-configured dylib on device and run the scoped card activation + saved-card + Verify regression. Promote only after those checks pass.
