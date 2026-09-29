# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.7 Auth Semantics + Reset Scope — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_7`.
- Main P79 work branch: `work/p79-server-driven-auth-isolation-v1`.
- Development branch: `work/p79.7-auth-semantics-reset-scope`.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / run #25: success.
- Raw artifact ID `11016299418`; raw CI dylib SHA256 `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- CI still reported `verify_secret_configured=0`; raw artifact is not the final Verify acceptance artifact.
- Controlled final test dylib has the user-provided test Verify Secret injected into both arm64/arm64e slices; placeholder remaining `0`; final SHA256 `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- Public source remains placeholder-only; never commit the real/test Secret.

### P79.7 behavior contract
1. **Same card + same UDID reuse**: when the UDID is already authorized, query the compatibility `/authorization` endpoint with `code + udid`. Only structured evidence that the submitted card is already bound to this UDID may skip `/appstore` and proceed to Runtime Config + Verify. Unknown/not-bound results retain P79.6 strict activation.
2. **App mismatch UX**: Verify `app_not_authorized` / `Authorization does not apply to this App` clears the saved card and returns to the original card input with the error message; it must not terminate in a separate standalone alert.
3. **Authorization reset scope**: reset deletes authorization-related Generic Password services visible to the current process, not only selected accounts. Cross-App isolated Keychain access groups remain outside the current App's entitlement boundary; a shared access group or server revoke API is required for true cross-App deletion.

### P79.7 device gates
- Same valid card + same UDID authenticates without being rejected as merely “used”.
- Different/used/mismatched/nonexistent card cannot borrow an existing UDID authorization.
- A card for another App returns to the same card prompt with “当前卡密不适用于此应用”.
- Valid current-App card reaches Verify and continues success → notice → update → icon.
- Clear authorization removes all current-process-visible legacy/AuthV2 authorization records and exits cleanly.
- Test reset behavior across at least two Apps; if the second App uses an isolated Keychain access group, record that as an entitlement/server scope limitation rather than claiming global deletion.

## P79.6 baseline retained beneath P79.7
- P79.6 restored `/apiface before → /appstore → /apiface after → authorized + stateChanged gate → Runtime Config → Verify v2`.
- `/appstore` HTTP success is transport success only; do not infer business activation from legacy numeric `code` alone.
- Saved-card `/apiface` HTTP 200 must still contain valid authorization before Verify.
- P79.7 layers binding reuse and prompt/reset semantics on top without removing this gate.

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
2. Preserve commit history; no force updates for normal stage promotion.
3. New functional stages increment numeric version; suffix letters are fixes only.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.
6. Real/test Verify Secret must not be committed to public source or printed in logs.

# Next Task
Install the controlled `v1_p79_7` Secret-configured dylib and run the same-card/same-UDID, App-mismatch prompt, and authorization-reset cross-App regression. Promote only after those checks pass.
