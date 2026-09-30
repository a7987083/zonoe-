# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.8h R3 Feature Access Provider — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8h`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `b62e6ac71c6d58db48b75e8f3064b012b836571f`.
- CI Run `36734106358` / #62: success.
- Artifact ID `11106496611`, digest `sha256:1326c3f0b22e684964ab35c1d6cfb3d7a128dbe5eae10ad96dd965f6a58ccbac`.
- Raw CI dylib SHA256: `ae3a3eee1fc53b0009f7c25ad4b37d9713ab2ef2f0fd34d1ad17dc78fd3c3457`.
- Controlled final dylib SHA256: `8ac866a22d2bae372adb62f9cdcc67c1bfadf6b3a71fe7e8e2b927d8687caa26`.
- Controlled final ZIP SHA256: `215be24ecbc1aa92441603dbaac3073523dd47254f1e36df7450327bf41681ae`.
- Universal `arm64 + arm64e (PAC00)`.

### R3 delivered in P79.8h
1. Added `ZONFeatureAccessProvider` as the single feature-access decision boundary.
2. Centralized current `lastVerify → permissions/access_level` parsing in the provider.
3. `ZONSectionRenderer` no longer imports or parses `ZONAuthV2Storage`; it calls `isFeatureVisible:`.
4. `ZONFeatureDispatcher` no longer parses raw server permissions; protected actions call `isFeatureActionAllowed:`.
5. Added optional feature metadata key `requiredRuntimeCapability`.
6. The provider combines existing server permission checks with `ZONRuntimeCapabilityService.isCapabilityAvailable:` when that optional metadata is present.
7. No existing feature receives a runtime-capability requirement in P79.8h, so current feature visibility/order/action behavior is intentionally unchanged.
8. `base.cloud-save` remains `extra_menu` for visibility and `extra_features` for action.
9. P79.8g passive runtime activation remains unchanged and still runs through `ZONRuntimeCapabilityService`.

### P79.8h verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- Xcode 16.4 `arm64 + arm64e` build: PASS.
- Controlled final injection changed exactly 128 bytes across the two Verify Secret placeholder regions; placeholder remaining `0`, Secret occurrences `2`.

## Latest device-passed baselines
- P79.8f: closed P0 startup/reset/runtime-safety baseline — DEVICE PASSED.
- P79.8g: R2 Runtime Capability extraction — DEVICE PASSED and current latest device-verified runtime/architecture baseline.
- P79.8h: CI PASSED / DEVICE PENDING; requires only a short equivalence check because no existing feature metadata semantics were changed.

## P79.8h short device-equivalence gate
1. Menu opens normally and current sections/features appear in the same order/count expected for the current authorization.
2. Existing server-permission visibility remains unchanged for the current card/access level.
3. Existing protected action behavior remains unchanged.
4. `runtime.iap-noads`/passive capability path remains normal.
5. No existing feature disappears due to the newly optional `requiredRuntimeCapability` key.

## Remaining separate regression gates
- P79.8c cloud permission matrix remains independently pending: `basic` hides `VIP云存档`; `app_plus/global_plus` expose it; actual action still requires fresh Verify.
- P79.8b full persistence regression remains independently pending beyond the P0 protected-key reset boundary.

## Deferred external-dylib integration
- The source-controlled external dylib exported interface and standalone button are intentionally deferred per current requirement.
- Infrastructure is now ready: a future feature can set `requiredRuntimeCapability`, and the same provider will enforce both render visibility and protected action access.

## Next refactor stage after P79.8h device acceptance
- R4 — migrate weak dictionary feature metadata toward typed descriptors while preserving identifiers, tags, section ordering and behavior exactly.
- R5 — decompose `ZONAuthV2Flow`, starting from pure authorization-decision parsing.
- R6 — measure startup/preflight/module-load timing before optimization or reordering.
- R7 — classify historical tests/workflows/generated artifacts before cleanup.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Run the short P79.8h R3 device-equivalence check. Keep the external-dylib interface/button deferred until explicitly resumed.
