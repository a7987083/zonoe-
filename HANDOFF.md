# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8h R3 Feature Access Provider
- VERSION: `v1_p79_8h`.
- Build HEAD: `b62e6ac71c6d58db48b75e8f3064b012b836571f`.
- CI Run `36734106358` / #62: success.
- Artifact ID `11106496611`, digest `sha256:1326c3f0b22e684964ab35c1d6cfb3d7a128dbe5eae10ad96dd965f6a58ccbac`.
- Raw CI SHA256: `ae3a3eee1fc53b0009f7c25ad4b37d9713ab2ef2f0fd34d1ad17dc78fd3c3457`.
- Controlled final SHA256: `8ac866a22d2bae372adb62f9cdcc67c1bfadf6b3a71fe7e8e2b927d8687caa26`.
- Controlled ZIP SHA256: `215be24ecbc1aa92441603dbaac3073523dd47254f1e36df7450327bf41681ae`.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / DEVICE PENDING.

## R3 architecture change
- Added `testmod/ZONServices/ZONFeatureAccessProvider.h/.m`.
- Public API:
  - `+currentServerPermissions`
  - `+currentAccessLevel`
  - `+isFeatureVisible:`
  - `+isFeatureActionAllowed:`
- Raw `ZONAuthV2Storage.lastVerify` permission/access-level parsing is centralized in this provider.
- `ZONSectionRenderer` no longer imports `ZONAuthV2Storage`; visibility is delegated to the provider.
- `ZONFeatureDispatcher` no longer owns a duplicate current-permissions helper; protected action access is delegated to the provider.
- Added optional registry metadata `requiredRuntimeCapability`.
- When present, the provider requires `ZONRuntimeCapabilityService.isCapabilityAvailable:` in addition to existing server permissions.
- P79.8h assigns this key to no existing feature, intentionally preserving all current feature behavior.

## Preserved behavior contracts
- Feature identifiers, legacy tags, section ordering and current renderer types are unchanged.
- `base.cloud-save` still requires `extra_menu` to render and `extra_features` to execute.
- `runtime.iap-noads` still preserves `NNGG`, `NNGGNNGG`, `ImgTool.NeiGou` and delegates passive activation to `ZONRuntimeCapabilityService`.
- P79.8g passive names/RVAs/signatures/mapped-range/PAC/one-shot/no-target behavior remain unchanged.
- P79.8f startup/reset/runtime-safety contracts remain inherited.

## Test / CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- CI materializes `ZONFeatureAccessProvider.h/.m` into the active target before build.
- Controlled final Verify Secret injection: placeholder remaining 0, occurrences 2, changed bytes 128.

## Device baselines / current gate
- P79.8f: DEVICE PASSED P0 baseline.
- P79.8g: DEVICE PASSED R2/runtime architecture baseline.
- P79.8h: DEVICE PENDING; short equivalence check only.

## P79.8h device check
1. Open menu and confirm sections/features appear normally for the current authorization.
2. Confirm no existing feature unexpectedly disappears or changes order.
3. Confirm any currently-available protected feature behaves as before.
4. Confirm `runtime.iap-noads` passive path remains normal.

## Deferred work
- The second/source-controlled external dylib interface and standalone button are intentionally deferred by request.
- Do not add exported-symbol probing yet.
- R3 infrastructure is ready for it later through `requiredRuntimeCapability`.

## Next engineering stage after P79.8h device pass
- R4 typed feature descriptors, incrementally and behavior-preserving.
- Then R5 AuthV2Flow decomposition, R6 startup measurement, R7 historical-test/repository hygiene.

## Remaining separate regressions
- P79.8c VIP cloud permission matrix remains independently pending.
- P79.8b full persistence regression remains independently pending beyond the P0 reset boundary.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
