# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.9 UDID-First Authorization Gate — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_9`.
- Main branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `675621f8264e228fc1d578301b17f49e9101a16b`.
- Build commit: `77db45077f6e22e54b7fa9e8c5a0a3924a65747a`.
- CI Run `36564346565` / #29: success.
- Artifact `11031705119`, digest `sha256:05393223053e999500028f64d8143c84191666016a4441adf4b4cf5f35b5bd23`.
- Raw CI dylib SHA256: `57a81062e35556b7092fbabaa6d98a8a90ea3796a3cbe8c3c27a3cc39f9e06c7`.
- Controlled Secret-configured test dylib SHA256: `75b28c007ee6171fe506af68a76ccfd008f1dd07226deab7c227a54c3dec721b`.
- Raw CI still has `verify_secret_configured=0`; public source remains placeholder-only.

### P79.9 startup contract
1. Acquire UDID first.
2. Query `/apiface` by UDID before checking local card state or presenting any activation prompt.
3. Evaluate active authorization scopes in priority order: **Plus/全软件源 (1) → 指定 App (3) → 仅验证 (2)**.
4. If any supported active scope exists, go directly to Runtime Config + Verify. Verify decides whether a specified-App authorization applies to the current App.
5. Only when the UDID has no active authorization does the client clear stale local card state and show the card activation prompt.
6. Network/5xx lookup failures are not equivalent to “no authorization”; they show an error and do not open the card prompt.
7. Legacy active licenses without `authorizations[]` remain compatible and are treated as source/Plus authorization.

### Why P79.8 is superseded
- P79.8 solved exact `card + UDID` reuse but still modeled the card as part of startup decision-making.
- Requirement clarified: a newly installed App must authenticate by UDID first. Card input is only for a UDID that has no active authorization.
- P79.8 is therefore superseded before device promotion, not considered a device-passed stage.

### Device gates
- Fresh App + Plus-authorized UDID: no card prompt; Verify directly.
- Fresh App + specified-App-authorized UDID: no card prompt; Verify decides current-App applicability.
- Fresh App + verify-only-authorized UDID: no card prompt; Verify directly.
- UDID with no active authorization: card prompt appears.
- Lookup failure: no card prompt.
- App mismatch returns to the same card prompt.
- Cross-App authorization reset remains limited by real Keychain access-group/server revoke boundaries.

## Baselines
- P79.8: CI passed, superseded by clarified UDID-first requirement.
- P79.7: CI passed, device failed same-card/same-UDID reuse; old `/authorization` probe is retired.
- P79.6: restored strict `/apiface before → /appstore → /apiface after → state-change gate → Verify` for first activation.
- Last promoted/device baseline remains P64a / `v1_p64a`, commit `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Verify protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; no force updates for normal promotion.
3. CI success does not equal device promotion.
4. Keep the five long-project state files synchronized.
5. Never commit or log the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_9` and verify fresh-App behavior for Plus → specified App → verify-only, then test the no-authorization prompt path.
