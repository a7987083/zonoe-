# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.8c Server-Driven Menu Permissions — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8c`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline: P79.8b persistence cleanup on top of device-passed P79.8a UDID-first authorization.
- Feature permission metadata commit: `dffe27a0f5101591d0a57774cf0041b64f06349d`.
- Menu filtering commit: `0d7c93c434084c260e240b824980cdb684fd25c9`.
- Action enforcement commit: `dd75f3f6267390268b12e467b03efa83d78f5d7d`.
- Fresh cloud Verify commit: `dbe02798bd0e2d5e4d55bde950100d510d40a93e`.
- VERSION/build HEAD: `4a2c35923c646917e912ca0758294df98460cccd`.
- CI Run `36591707184` / run #37: success.
- Artifact ID `11043668689`, digest `sha256:c6e1f80c902508e27d527a4079f2d72ad53767438ca24278405010d93f22a66e`.
- Raw CI dylib SHA256: `de3be9f75f5fb6639c84c283252bd5e184b1cde0d512b1cc3ca6c48ba314c153`.
- Controlled final test dylib SHA256: `7d8c80d317810eb4331db02fa216697f3c869fdfa7cacbfb0499c936d60f1651`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

### Server-authoritative permission contract
The backend `DylibRuntimeAccessService` owns the permission model:
- `basic`: `normal_menu=true`, `extra_menu=false`, `extra_features=false`.
- `app_plus`: `normal_menu=true`, `extra_menu=true`, `extra_features=true`.
- `global_plus`: `normal_menu=true`, `extra_menu=true`, `extra_features=true`.
- Client consumes `permissions`; it does not derive feature access from card scope/type.

### P79.8c behavior
1. `base.cloud-save` / `VIP云存档` requires `extra_menu` to be rendered.
2. Action dispatch independently requires `extra_features`; denied actions are handled and cannot fall through to legacy tag routes.
3. Opening the cloud-save surface also checks the current session Verify result.
4. Selecting a cloud-save download action performs a fresh Verify v2 request using the current Runtime Config.
5. Download proceeds only when fresh Verify is successful and `extra_features=true`.
6. The current cloud-save route no longer uses the legacy `https://app.zonoeios.xyz/index/index/apiface?udid=` entitlement request.
7. Legacy Bsphp/UDID fallback code remains compiled for compatibility and may still contain the old hostname string; it is not the P79.8c cloud-save authorization route.
8. P79.8a UDID-first startup and P79.8b persistence semantics remain unchanged.

### Device gates for P79.8c
- Verify-only / `basic`: menu opens normally but `VIP云存档` is absent; base section count is reduced accordingly.
- `app_plus`: `VIP云存档` is visible for the matched App and opens normally.
- `global_plus`: `VIP云存档` is visible and opens normally.
- Revoke/downgrade permission after menu creation, then trigger cloud save: fresh Verify must deny before download.
- P79.8b persistence cleanup and menu preference persistence must remain unchanged.

## Device-passed baseline — P79.8a
- VERSION: `v1_p79_8a`.
- CI Run `36572203902` / #32: success.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Real-device validation: PASS — fresh App + already-activated UDID skips card input and continues to Verify.

## Protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API base: `https://app3.zonoeios.xyz`
- UDID authorization path: `/index/index/apiface`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_8c` and validate `basic` vs `app_plus/global_plus` menu visibility plus fresh Verify denial before cloud download.
