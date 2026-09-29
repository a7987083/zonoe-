# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_8c`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `4a2c35923c646917e912ca0758294df98460cccd`.
- CI Run `36591707184` / #37: success.
- Architectures: `arm64 + arm64e`.
- Artifact ID: `11043668689`.
- Raw CI SHA256: `de3be9f75f5fb6639c84c283252bd5e184b1cde0d512b1cc3ca6c48ba314c153`.
- Controlled final SHA256: `7d8c80d317810eb4331db02fa216697f3c869fdfa7cacbfb0499c936d60f1651`.
- Current-device validation: pending.
- Last device-passed baseline: P79.8a / controlled SHA256 `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.

## Open risks

### Permission-gated menu needs real-device confirmation
- `VIP云存档` is now hidden unless Verify `permissions.extra_menu` is true.
- Backend current model gives `extra_menu=false` to `basic` and true to `app_plus/global_plus`.
- Device test must confirm basic/verify-only does not render the button while app/global Plus does.

### Cloud-save action has three gates
- Menu rendering requires `extra_menu`.
- Action dispatch requires `extra_features` and prevents legacy fallthrough on denial.
- Actual cloud download selection performs a fresh Verify and again requires `extra_features=true`.
- Device testing should include a permission revoke/downgrade after the menu is already open.

### Old app.zonoeios.xyz string still exists in compatibility code
- The current P79.8c cloud-save coordinator no longer passes the legacy `https://app.zonoeios.xyz/index/index/apiface?udid=` endpoint.
- The final binary still contains two copies of the old string because legacy Bsphp/UDID fallback code remains compiled for compatibility.
- Do not remove stable fallback code solely to make the binary string count zero unless that legacy path is separately retired and regression-tested.

### Server permissions are authoritative
- Do not infer feature access from `scope`, card labels, or locally ranked `access_level`.
- Current menu/action logic consumes the server `permissions` dictionary.
- Missing permission keys fail closed for protected features such as cloud save.

### Persistence cleanup remains device-pending
- P79.8b storage semantics are inherited unchanged.
- Verify/menu testing for P79.8c should also confirm no regression in `DZUDID`, notice fingerprint, or menu/runtime preferences.

### Raw CI artifact has no Verify Secret
- CI Run `36591707184` produced the placeholder build.
- Controlled final artifact uses equal-length post-build injection into both architecture slices.
- Placeholder remaining `0`; Secret occurrences `2`; 128 bytes differ from raw CI.
- Public source remains placeholder-only.

## Corrected / removed

### Ungated VIP cloud-save menu — corrected in P79.8c
- `base.cloud-save` now declares `requiredMenuPermission=extra_menu` and `requiredActionPermission=extra_features`.
- Renderer consumes the current session Verify permissions before constructing the section.
- Dispatcher blocks direct/tag-based action entry without `extra_features`.

### Legacy cloud entitlement request — removed from the current cloud route in P79.8c
- Cloud downloads now re-run Verify v2 using current Runtime Config and `DZUDID`.
- After successful fresh Verify, legacy `/apiface` entitlement checking is bypassed because Verify already supplied the authoritative permission decision.

### Excess AuthV2 persistence — corrected in P79.8b
- AuthV2 response/config/card state is process-memory only; only notice fingerprint remains persistent.

### P79.8 saved-card-first startup — corrected in P79.8a
- Startup checks server authorization by UDID first; user confirmed the real-device scenario works.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Verify acceptance testing must use the Secret-configured controlled artifact.
