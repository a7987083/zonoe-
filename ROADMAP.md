# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.10 Server-Authoritative Access Model — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_10`.
- Main branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `3177a4e8dc4ceeaabd97ecdac87a7266b201566a`.
- Build commit: `533af1abd09bb2fcf0701ca05c4370d740129459`.
- CI Run `36567247825` / #31: success.
- Artifact `11032596408`, digest `sha256:0afa2b4c1066b011f0cde87e03ca5680a8d635a0f5a3784b1e9565546d1f701a`.
- Raw CI dylib SHA256: `af13c7a69f4a30cb5333d1f04917998f738ba513ca19ea94cf6a24e1dc775552`.
- Controlled Secret-configured test dylib SHA256: `6e0a29487b5e5f8c2f9392203e306c59de8140eb2983e5f59f28821f42ebd9e5`.
- Raw CI still has `verify_secret_configured=0`; public source remains placeholder-only.

### P79.10 authorization contract
1. Acquire UDID first.
2. Bootstrap is fixed to `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`.
3. Bootstrap returns business API base `https://app3.zonoeios.xyz`.
4. Query `/index/index/apiface?udid=<UDID>` before local card state or any activation prompt.
5. Client consumes only server-calculated `access_level` and `permissions`; it must not infer card type from `scope/type/expire`.
6. Server priority is `global_plus > app_plus > basic > block`.
7. `global_plus`, `app_plus`, or `basic` means the UDID already has usable authorization and proceeds directly to Runtime Config + Verify.
8. `block` or a response without usable `access_level` follows the no-authorization/card-activation path.
9. Network/5xx lookup failures are not equivalent to “no authorization” and do not open the card prompt.
10. After first card activation, `/apiface` is queried again and the same server `access_level` gate decides whether activation succeeded.

### Why P79.9 is superseded
- P79.9 correctly introduced UDID-first startup, but incorrectly derived authorization from `scope/type/expire` and client-side scope priority.
- The API contract already computes the permission model and returns `access_level/permissions`.
- Real-device result showed an already-activated UDID still receiving the card prompt; P79.10 removes the client-side card-type inference.

### Device gates
- Fresh App + `global_plus`: no card prompt; Verify directly.
- Fresh App + `app_plus`: no card prompt; Verify decides current-App applicability.
- Fresh App + `basic`: no card prompt; Verify directly.
- `block` / no usable authorization: card prompt appears.
- Lookup failure: no card prompt.
- First card activation: after `/appstore`, `/apiface` must return one of the accepted access levels before Verify.

## Baselines
- P79.9: CI passed; device failed because client inferred authorization from legacy fields instead of server `access_level`.
- P79.8: CI passed, superseded by clarified UDID-first requirement.
- P79.7: CI passed, device failed same-card/same-UDID reuse; old `/authorization` probe is retired.
- Last promoted/device baseline remains P64a / `v1_p64a`, commit `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Verify protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API base: `https://app3.zonoeios.xyz`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; no force updates for normal promotion.
3. CI success does not equal device promotion.
4. Keep the five long-project state files synchronized.
5. Never commit or log the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_10` and verify a newly installed App on an already-activated UDID does not show the card prompt when `/apiface` returns `global_plus`, `app_plus`, or `basic`.
