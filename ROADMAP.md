# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.8 Same-Card/Same-UDID License Query — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8`.
- Main P79 work branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- Build/version commit: `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36560746520` / run #27: success.
- Raw artifact ID `11028839445`; raw CI dylib SHA256 `590f6a67e5e4faf9d6c9a2c6f6910884cbff4a15e5cf6c205fe3536be20fb9cc`.
- CI reported `verify_secret_configured=0`; raw artifact is not the final Verify acceptance artifact.
- Controlled final test dylib has the test Verify Secret injected into both arm64/arm64e slices; placeholder remaining `0`; final SHA256 `12cac6f3a9b7ce9da1ad5f27f9364606c42f52eb3311dd36e2308c5cd8a8f723`.
- Public source remains placeholder-only; never commit the real/test Secret.

### P79.8 correction over P79.7
- P79.7 device test failed: a card already bound to the same UDID still showed `解锁码已使用`.
- Root cause: P79.7 queried the retired `/authorization` compatibility surface. It did not provide the structured same-binding evidence expected by the client, so the client fell back to `/appstore`, whose one-time activation contract correctly returned `解锁码已使用` for `jh=1`.
- P79.8 removes that dependency and probes `/index/index/license`, whose server path uses `AuthorizationLicense::query(code, udid)`.
- The server query is exact: it requires the submitted card code, the submitted UDID, and `jh=1`; an active authorization is then required before the client may skip `/appstore`.
- New/unused/mismatched/expired results still run the canonical P79.6 `/appstore` activation flow. A generic `解锁码已使用` message is never sufficient to authorize.

### P79.8 device gates
- Same valid card + same UDID must reach Runtime Config + Verify without `/appstore` used-card rejection.
- Different used card must not borrow the existing UDID authorization.
- Unused valid card must still activate through `/appstore` and pass the P79.6 before/after authorization gate.
- Card for another App must return to the same card prompt with `当前卡密不适用于此应用`.
- Clear authorization must remove all current-process-visible legacy/AuthV2 authorization records; cross-App isolated Keychain access groups remain an entitlement/server boundary.

## P79.7 — DEVICE FAILED / SUPERSEDED
- VERSION: `v1_p79_7`.
- CI Run `36531465809`: success.
- Controlled final dylib SHA256 `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- App-mismatch prompt routing and broadened visible-Keychain reset remain carried forward.
- Same-card reuse implementation based on `/authorization` is retired and must not be restored.

## P79.6 baseline retained beneath P79.8
- P79.6 restored `/apiface before → /appstore → /apiface after → authorized + stateChanged gate → Runtime Config → Verify v2`.
- `/appstore` HTTP success is transport success only; do not infer business activation from legacy numeric `code` alone.
- Saved-card `/apiface` HTTP 200 must still contain valid authorization before Verify.
- P79.8 adds precise existing-card binding reuse without weakening this gate for new cards.

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
Install the controlled `v1_p79_8` Secret-configured dylib and test same-card/same-UDID reuse first. Promote only after the full scoped regression passes.
