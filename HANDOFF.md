# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current work target — P79.9
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- VERSION: `v1_p79_9`.
- Logic commit: `675621f8264e228fc1d578301b17f49e9101a16b`.
- Build commit: `77db45077f6e22e54b7fa9e8c5a0a3924a65747a`.
- CI Run `36564346565` / #29: success.
- Artifact ID `11031705119`.
- Raw CI dylib SHA256: `57a81062e35556b7092fbabaa6d98a8a90ea3796a3cbe8c3c27a3cc39f9e06c7`.
- Controlled final test dylib SHA256: `75b28c007ee6171fe506af68a76ccfd008f1dd07226deab7c227a54c3dec721b`.
- Raw CI reports `verify_secret_configured=0`; controlled artifact has placeholder `0`, Secret occurrences `2`.

## P79.9 behavior
1. Acquire UDID first.
2. Query `/apiface` by UDID before local card state or any prompt.
3. Priority is **Plus/全软件源 (scope 1) → 指定 App (scope 3) → 仅验证 (scope 2)**.
4. Any supported active scope goes directly to Runtime Config + Verify.
5. Specified-App applicability is decided by Verify using current App identity; client does not guess App mapping because `/apiface` summaries do not include app IDs.
6. Only a UDID with no active authorization shows the activation card prompt.
7. Network/5xx lookup errors never open the card prompt.
8. Legacy active licenses without `authorizations[]` are treated as source/Plus for backward compatibility.

## First activation fallback
- Card input remains only for a UDID with no active authorization.
- P79.6 strict first-activation gate is preserved: `/apiface before → /appstore → /apiface after → state change → Runtime Config → Verify`.
- Generic `解锁码已使用` is never sufficient authorization evidence.

## Carried behavior
- `app_not_authorized` returns to the existing card prompt instead of a standalone terminal alert.
- Authorization reset deletes complete authorization-related Keychain services visible to the current process.
- Cross-App reset still depends on shared Keychain access groups or a real server revoke/reset API.

## Verify protocol
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Required device checks
- Fresh App + Plus-authorized UDID: no card prompt.
- Fresh App + specified-App-authorized UDID: no card prompt; Verify determines applicability.
- Fresh App + verify-only-authorized UDID: no card prompt.
- No active UDID authorization: card prompt.
- Lookup failure: no card prompt.
- App mismatch: same card prompt.
- Verify success continues notice → update → icon.

## Last promoted/device baseline
- P64a / `v1_p64a`, commit `010f383da7f1429c4db93bfda559431e3c4080f9`, device passed.
