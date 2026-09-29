# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current target — P79.8a
- VERSION: `v1_p79_8a`.
- Rebuild base: P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- Main flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- Removed BindingProbe swizzle from build chain: `dce8c905960256d6e73dcdb62d42060f56660558`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`.
- CI/build HEAD: `3ab9fc3879930b7d89770ca95f6e7636dc0119d3`.
- CI Run `36572203902` / #32: success.
- Artifact ID `11036215202`.
- Raw CI SHA256: `188e25b8c8d76653baffb01e01cd8931302d2ca6d0e67a07d18fee1bd80a894a`.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

## Required authorization model
1. `ZONAuthorizationCoordinator` obtains or reuses the device UDID and writes `DZUDID`.
2. `ZONAuthV2Flow::startFromViewController:udid:` immediately queries `/index/index/apiface` using that UDID.
3. Do not use local card presence to decide startup activation.
4. `/apiface` is the device-activation check. Preserve the legacy working contract: `code=1`, `msg=ok`, unexpired `expire` means this UDID already has an active card.
5. If active, skip card entry and continue to Runtime Config + Verify.
6. Verify owns the current App decision and server-authoritative `access_level` / `permissions` result.
7. Only an explicit no-record or expired authorization opens the card input.
8. Network/5xx/unknown payloads are errors, not proof that activation is absent.

## First activation fallback
- Card input is only reached for a UDID without an active authorization, an expired authorization, or after Verify reports current-App mismatch and the user must provide another card.
- Activation keeps P79.6's strict sequence: `/apiface before → /appstore → /apiface after → active + stateChanged → Runtime Config → Verify`.
- Generic `解锁码已使用` is never converted into success.

## Removed behavior
- `ZONAuthV2BindingProbe.m` is no longer imported by `ZONAuthV2Storage.m`; its runtime swizzle does not participate in P79.8a.
- Final binary has zero `P79.8_BINDING_GATE` and `P79.8_LICENSE_PROBE` markers.
- P79.9/P79.10 startup experiments are not inherited into this branch.

## API topology
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API Base: `https://app3.zonoeios.xyz`
- Device auth: `/index/index/apiface?udid=<UDID>`
- Verify: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- Verify request uses UDID + current App identity + dylib identity; the card is not required for an already-active UDID startup.

## Device test order
1. Install a fresh App on a device whose UDID already has a valid card.
2. Confirm there is no card popup.
3. Confirm log contains `P79.8A_UDID_GATE state=active` and then `VERIFY`.
4. Confirm Verify returns/consumes the expected `access_level` and `permissions`.
5. Test a UDID with no record: card popup must appear.
6. Test expired authorization: replacement-card popup.
7. Test new card activation and App mismatch behavior.

## Rollback baseline
- Last device-passed baseline: P64a / `v1_p64a` / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized.
- Do not commit or print the real/test Verify Secret.
