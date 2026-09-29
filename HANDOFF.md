# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current work target — P79.10
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- VERSION: `v1_p79_10`.
- Logic commit: `3177a4e8dc4ceeaabd97ecdac87a7266b201566a`.
- Build commit: `533af1abd09bb2fcf0701ca05c4370d740129459`.
- CI Run `36567247825` / #31: success.
- Artifact ID `11032596408`.
- Raw CI dylib SHA256: `af13c7a69f4a30cb5333d1f04917998f738ba513ca19ea94cf6a24e1dc775552`.
- Controlled final test dylib SHA256: `6e0a29487b5e5f8c2f9392203e306c59de8140eb2983e5f59f28821f42ebd9e5`.
- Raw CI reports `verify_secret_configured=0`; controlled artifact has placeholder `0`, Secret occurrences `2`.

## P79.10 server contract
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`.
- Business API base from Bootstrap: `https://app3.zonoeios.xyz`.
- UDID authorization query: `/index/index/apiface?udid=<UDID>`.
- Client authorization decision consumes only `access_level` and `permissions` returned by the server.
- Do **not** infer card type from `scope`, `type`, `expire`, or local ordering.
- Server priority: `global_plus > app_plus > basic > block`.
- Accepted/usable levels: `global_plus`, `app_plus`, `basic`.
- `block` or missing usable access level follows the no-authorization/card-prompt path.

## Startup flow
1. Acquire and persist UDID.
2. Query `/apiface` immediately, before local card state and before any activation prompt.
3. If `access_level` is `global_plus`, `app_plus`, or `basic`, continue Runtime Config + Verify with no `/appstore` call.
4. If the response has no usable authorization, clear stale local card state and show the activation card prompt.
5. Network/5xx lookup errors show an error and do not masquerade as an unactivated UDID.

## First activation flow
- Card input exists only for the no-authorization path.
- Before activation the client rechecks `/apiface`; if the server already returns an accepted access level, `/appstore` is skipped.
- Otherwise call `/appstore`, then query `/apiface` again.
- Only an accepted server `access_level` permits Runtime Config + Verify.
- Generic `解锁码已使用` is not authorization evidence.

## Carried behavior
- `app_not_authorized` returns to the existing card prompt instead of a standalone terminal alert.
- Authorization reset deletes complete authorization-related Keychain services visible to the current process.
- Cross-App reset still depends on shared Keychain access groups or a real server revoke/reset API.

## Required device checks
- Fresh App + already-activated UDID + `global_plus`: no card prompt.
- Fresh App + already-activated UDID + `app_plus`: no card prompt; Verify determines current-App applicability.
- Fresh App + already-activated UDID + `basic`: no card prompt.
- `block`/no usable authorization: card prompt.
- Lookup failure: no card prompt.
- First activation: `/appstore` followed by `/apiface` accepted only when server returns a usable access level.
- Verify success continues notice → update → icon.

## Superseded behavior
- P79.9 client-side `scope/type/expire` derivation is invalid and must not be restored.
- P79.8 card+UDID startup probe and P79.7 `/authorization` probe are also retired.

## Last promoted/device baseline
- P64a / `v1_p64a`, commit `010f383da7f1429c4db93bfda559431e3c4080f9`, device passed.
