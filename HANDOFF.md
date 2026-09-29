# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current target — P79.8c Server-Driven Menu Permissions
- VERSION: `v1_p79_8c`.
- Permission metadata: `dffe27a0f5101591d0a57774cf0041b64f06349d`.
- Menu filter: `0d7c93c434084c260e240b824980cdb684fd25c9`.
- Action gate: `dd75f3f6267390268b12e467b03efa83d78f5d7d`.
- Fresh cloud Verify: `dbe02798bd0e2d5e4d55bde950100d510d40a93e`.
- Build HEAD: `4a2c35923c646917e912ca0758294df98460cccd`.
- CI Run `36591707184` / #37: success.
- Artifact ID `11043668689`, digest `sha256:c6e1f80c902508e27d527a4079f2d72ad53767438ca24278405010d93f22a66e`.
- Raw CI SHA256: `de3be9f75f5fb6639c84c283252bd5e184b1cde0d512b1cc3ca6c48ba314c153`.
- Controlled final dylib SHA256: `7d8c80d317810eb4331db02fa216697f3c869fdfa7cacbfb0499c936d60f1651`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

## Authorization model — unchanged
1. Acquire/reuse `DZUDID` first.
2. Query `/index/index/apiface?udid=<UDID>` before any card prompt.
3. Active UDID authorization skips card entry and continues to Runtime Config + Verify.
4. Verify owns current-App applicability plus `access_level` and `permissions`.
5. Only explicit missing/expired authorization opens card input.
6. Network/server/unknown payloads are not treated as missing activation.

## Server permission model used by P79.8c
Backend currently returns:
- `basic`: `normal_menu=true`, `extra_menu=false`, `extra_features=false`.
- `app_plus`: `normal_menu=true`, `extra_menu=true`, `extra_features=true`.
- `global_plus`: `normal_menu=true`, `extra_menu=true`, `extra_features=true`.

Client rule: consume `permissions` only. Do not infer cloud-save visibility/action from `scope`, card type, or `access_level` ranking.

## VIP cloud-save routing
- Registry feature: `base.cloud-save`, legacy tag `2`.
- Menu visibility requires server permission `extra_menu`.
- Action dispatcher requires server permission `extra_features` and returns handled-on-denial to block legacy fallthrough.
- `ZONSaveTransferCoordinator` checks the session Verify result before opening cloud-save UI.
- Each actual cloud download selection performs a fresh Verify v2 request using `DZUDID` + current session Runtime Config.
- Only fresh Verify success with `extra_features=true` resolves/downloads the archive.
- The new cloud route no longer uses the legacy `app.zonoeios.xyz /apiface` entitlement request.
- Old Bsphp/UDID fallback compatibility code is still compiled and may contain the old hostname string; do not confuse binary-string presence with the active P79.8c cloud route.

## Persistence model inherited from P79.8b
- Long-lived identity: Keychain `DZUDID` only.
- AuthV2 `udid`, `card`, `lastVerify`, `lastActivation`, `lastRuntimeConfig`, `lastBootstrap`: process-memory only.
- Persistent AuthV2 UserDefaults: only `zonoe.auth.v2.lastNoticeFingerprint` for notice de-duplication.
- Menu/runtime preference keys remain untouched.

## Device test order
1. Verify-only/basic card: menu should open, `VIP云存档` should not exist.
2. App-specific card matched to current App: `VIP云存档` should exist and work.
3. Global Plus card: `VIP云存档` should exist and work.
4. Open menu while entitled, then revoke/downgrade server permission and attempt a cloud download; fresh Verify must deny before archive resolution/download.
5. Confirm normal menu items and P79.8b persistence behavior are unchanged.

## Device-passed rollback baseline
- P79.8a / `v1_p79_8a`.
- CI Run `36572203902` / #32.
- Controlled final SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- User confirmed fresh App + already-activated UDID behavior works correctly.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized.
- Do not commit or print the real/test Verify Secret.
