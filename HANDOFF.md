# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p31-registry-boundary`
- Current version: `v1_p31`
- Current device-verified baseline: `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`
- p29 source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e` (hardware covered by p31 cumulative regression)
- p30 source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809` (hardware covered by p31 cumulative regression)
- p31 source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` (device verified)

## Device-validation policy
`DEVICE_TEST_MATRIX.md` is a required phase artifact. Every version must define its real-device checklist before the A_customer build is handed out. CI success alone does not promote a version; promotion requires the user to explicitly report the required checklist as passed.

The user reported the full cumulative p29 + p30 + p31 hardware regression passed with no issues. Therefore p31 is promoted and the same regression closes the pending p29 Renderer/Panel and p30 EventBridge hardware gates.

## Current phase — v1_p31 Feature Registry Boundary Cleanup — completed
p31 converts `ZONFeatureRegistry` from header-only implementation into a declaration header plus independent Objective-C implementation while preserving all registry data.

Changes:
- `VERSION`: `v1_p30` -> `v1_p31`.
- `ZONFeatureRegistry.h`: registry functions are declarations; string keys use `FOUNDATION_EXPORT`.
- Added `ZONFeatureRegistry.m` containing the unchanged key values, 3 section records, 10 feature records and lookup/validation functions.
- Registered `ZONFeatureRegistry.m` in the Xcode target Sources phase.
- Updated permanent `module-abi.yml` so `feature_registry_smoke.m` explicitly links `ZONFeatureRegistry.m`.

Intentionally untouched:
- `ZONFeatureDispatcher.h` and Dispatcher business handlers.
- `ZONMenuEventBridge.h/.m` behavior.
- authorization / BS-PHP, UDID, VIP cloud save, clear-game-data.
- `WX_NongShiFu123.mm`, actual `testmod/Bsphp/main.m`, AppDelegate / SceneDelegate.
- UI style, dimensions, colors, text or spacing.
- keyboard/presentation logic.

## Registry invariants proved by CI
The isolated p31 CI compares the p30 Registry header with the p31 implementation before compiling:
- all registry dictionary rows are byte-for-byte line-equivalent after relocation;
- all 12 string key names and string values are unchanged;
- `feature_registry_smoke` passes with `-Wall -Wextra -Werror`;
- 10 feature records remain present and migrated;
- legacy tag -> identifier mappings remain unchanged;
- 3 sections, section order, feature order, state keys and renderer names remain unchanged;
- existing Module ABI smoke also passes.

## Source commits
- Registry implementation split: `b6e43f11103f00381a90fe4ef42110a595d41bce`.
- Registry constants centralized: `0f4f8fab9131bd5e73f7fcf15919fb5ece44e6b7`.
- PBX integration / p31 source head: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.

## v1_p31 CI verification
- Workflow: `p31 Registry Boundary Build`
- Run ID: `34673034214`
- Validation branch: `test/zonoemenu-v1-p31-registry-build`
- Validation workflow commit: `57dbc4eca5131f9c0496806a9bd68d2d5f3eb716`
- Result: success
- Xcode: 16.4
- Deployment target: iOS 12.0
- Architectures: arm64 + arm64e

### A_customer
- Artifact: `testmod-v1_p31-A_customer`
- Artifact ID: `10291681640`
- Artifact ZIP SHA256: `5f1e106ef2d8a861b75ecaa7e7d44ca83b2c992122aa03e681ec399cc6ae9602`
- Dylib SHA256: `579d721b6f2cfcb89b711ad676632851c84173d65f872259d26553bf180b6b68`

### B_debug
- Artifact: `testmod-v1_p31-B_debug`
- Artifact ID: `10291566984`
- Artifact ZIP SHA256: `c2b8b9b15d8dc732bf208f7d06d1edec1c74f5811ca8426305568ed2d3b312d6`
- Dylib SHA256: `ffe787f48c0ed5e6e3862692ccf279879831257ccdd7a8946af239d405927743`

Both variants passed protected-source checks, Registry data equivalence, Registry smoke, Module ABI smoke, compilation, linking, dylib packaging and universal arm64/arm64e Mach-O verification.

## v1_p31 real-device verification
- Status: **passed**.
- User report: cumulative p29 + p30 + p31 checklist tested with no issues.
- Result: p31 is the new device-verified baseline; p29 and p30 pending hardware status is implicitly closed by the same cumulative regression.

## ModuleLoader audit note
During p31 candidate selection, `ZONModuleLoader` was audited. The repository has legacy/duplicate loader headers, but the actual target compiles `testmod/Bsphp/main.m`, which does not reference `ZONModuleLoader`, and `project.pbxproj` has no ModuleLoader source reference. Therefore no ModuleLoader code was added to the p31 product target; forcing an inactive path into the build would create unnecessary behavior surface.

## Runtime verification state
- `v1_p28`: device/runtime verified; historical fallback baseline.
- `v1_p29`: device/runtime passed via cumulative p31 regression.
- `v1_p30`: device/runtime passed via cumulative p31 regression.
- `v1_p31`: CI/static/smoke/device verified; current baseline.

## Current compile relationship
```text
ZONMenuCoordinator.m
  -> ZONMenuPanelController.h
  -> ZONMenuChromeRenderer.h
  -> ZONSectionRenderer.h
       -> ZONFeatureRenderer.h
       -> ZONFeatureRegistry.h
            -> implemented by ZONFeatureRegistry.m
  -> ZONMenuEventBridge.h
       -> implemented by ZONMenuEventBridge.m
           -> ZONFeatureDispatcher.h
           -> ImgTool.h

Xcode target Sources
  -> ZONMenuCoordinator.m
  -> ZONMenuPanelController.m
  -> ZONMenuChromeRenderer.m
  -> ZONFeatureRenderer.m
  -> ZONSectionRenderer.m
  -> ZONMenuEventBridge.m
  -> ZONFeatureRegistry.m
```

## Next task
Start `v1_p32` with a **Dispatcher boundary audit**, not an immediate rewrite: inspect the active `ZONFeatureDispatcher.h` call/data flow, protected business handlers and Xcode compilation ownership; define source-equivalence, protected-route CI smoke and the p32 real-device checklist before moving any implementation into a `.m` file.
