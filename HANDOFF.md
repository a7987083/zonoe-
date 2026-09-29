# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current target — P79.8b Persistence Cleanup
- VERSION: `v1_p79_8b`.
- Functional baseline: device-passed `v1_p79_8a`.
- Storage contract: `78da327ef11946d8502e77b023d1f8b823c2fad1`, `1b099d83da7ae00a5773279f755110f0c441b4d3`.
- Cleanup integration: `d97e78c8bdedbf8efa0b87b77a0c18bf8b9266ea`.
- Reset integration: `4a5888613f7c2c5b76e5191d2c42a9a60e491890`.
- Build HEAD: `19d5d1e0204c84f56fc2ee330bb2371d3511d367`.
- CI Run `36585791709` / #36: success.
- Artifact ID `11041556869`.
- Raw CI SHA256: `b6c3333cbce0b0ff508a11ac31a6d81ce180db4c1afd3360e86d0ed5a9ce7045`.
- Controlled final dylib SHA256: `e363256b06e7842090103f95cc5edd14066b7eb50f144768fcd38882255bd62c`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

## Required authorization model — unchanged from P79.8a
1. `ZONAuthorizationCoordinator` obtains or reuses the device UDID and writes `DZUDID`.
2. `ZONAuthV2Flow::startFromViewController:udid:` immediately queries `/index/index/apiface` using that UDID.
3. Do not use local card presence to decide startup activation.
4. `/apiface` is the device-activation check: `code=1`, `msg=ok`, unexpired `expire` means active UDID authorization.
5. Active UDID skips card entry and continues to Runtime Config + Verify.
6. Verify owns current-App applicability plus `access_level` / `permissions`.
7. Only explicit no-record or expired authorization opens card input.
8. Network/5xx/unknown payloads are errors, not proof activation is absent.

## P79.8b persistence rules
- Long-lived UDID: only legacy Keychain `DZUDID`.
- AuthV2 session-only values: `udid`, `card`, `lastVerify`, `lastActivation`, `lastRuntimeConfig`, `lastBootstrap`.
- Only persistent AuthV2 preference: `zonoe.auth.v2.lastNoticeFingerprint` for notice de-duplication.
- After `DZUDID` is confirmed, remove completed bridge keys: `zonoe.udid.bridge.value`, `zonoe.udid.bridge.scheme`, `zonoe.udid.bridge.requestTimestamp`, `zonoe.udid.bridge.requestNonce`.
- Upgrade cleanup removes old authorization defaults: `到期时间`, `卡密`, `公告`, `zonoeudid`, `解锁码到期时间`, `到期弹窗`.
- Do NOT remove or rename menu/runtime preferences such as fold-state, IAP toggle, ad toggle, and ad-speed keys.

## API topology
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API Base: `https://app3.zonoeios.xyz`
- Device auth: `/index/index/apiface?udid=<UDID>`
- Verify: `https://app3.zonoeios.xyz/index/dylib_verify/verify`

## Device test order for P79.8b
1. Install over a device that has previously used P79.8a/older builds.
2. Confirm existing valid `DZUDID` still goes directly to `/apiface` and Verify without card input.
3. Inspect Preferences after startup: AuthV2 response/config/activation/card/bridge residue should be absent; only notice fingerprint may remain from AuthV2.
4. Confirm menu fold state remains persistent.
5. Confirm IAP/ad toggles and ad-speed remain persistent.
6. Trigger a notice, relaunch, and confirm the same notice does not reappear.
7. Test fresh activation and verify no card value is persisted after success.

## Device-passed rollback baseline
- P79.8a / `v1_p79_8a`.
- CI Run `36572203902` / #32: success.
- Controlled final SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- User reported real-device test normal, including fresh App + already-activated UDID skipping card input.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized.
- Do not commit or print the real/test Verify Secret.
