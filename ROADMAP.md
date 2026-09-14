# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p34`.
- Source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- CI Run `34758839228`: success.
- Real-device regression: user explicitly reported p34 passed.
- p34 is the fallback baseline until p35 device verification passes.

## Current development candidate — v1_p35
Status: `ci_verified_device_pending`.

### Goal
Continue repository slimming without removing any of the nine active menu features. Establish `testmod/` as the canonical product source surface and remove the retired tag-203 placeholder plus root-only remnants of feature stacks already removed from `testmod/` in p34.

### Implemented
- `VERSION`: `v1_p34` -> `v1_p35`.
- Removed `runtime.placeholder-203` / `暂无` from `ZONFeatureRegistry`.
- Removed the tag-203 renderer branch from `ZONFeatureRenderer`.
- Removed the tag-203 Dispatcher behavior (`人物血量`) from `ZONFeatureDispatcher`.
- Updated Registry/Dispatcher tests to require exactly nine active features and to reject tag 203.
- Removed root-only retired copies of the old memory-editor stack, JRMemory.framework, old alternate-icon UI, old drag/screenshot helpers, empty helpers/categories, and retired AppStore helper.
- Preserved all nine active product features: remote download, cloud save, local files, backup, restore, clear game data, clear authorization, IAP/no-ads, ad speed.

### Verification completed
- Canonical-cleanup guard: passed.
- All nine active Registry identifiers preserved.
- Tag 203 absent from Registry, Renderer and Dispatcher.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Feature Registry smoke: passed with 9 features / 3 sections.
- Module ABI smoke/example exports: passed.
- A_customer full iOS 12 arm64/arm64e Xcode build/package: passed.
- B_debug full iOS 12 arm64/arm64e Xcode build/package: passed.
- Workflow Run `34825140580`: success.
- P35 runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.

### Promotion gate
P35 requires A_customer real-device regression. The expected intentional visual change is that the `203 / 暂无` runtime placeholder is gone. The other nine product functions must behave the same as p34.

## Next cleanup backlog after p35 promotion
1. Continue canonical-source consolidation for remaining root vs `testmod/` duplicate trees, but only after CI/scripts/reference proof.
2. Audit remaining 76 active p34-era target sources for unused helpers without touching active hooks or file/cloud features.
3. Keep `AFNetworking`, `MBProgressHUD`, `SCLAlertView`, `JDStatusBarNotification`, `SSZipArchive/minizip`, `JHDragView`, `PubgLoad`, `NSObject+UI`, authorization and runtime hook stacks until explicit dependency proof says otherwise.
4. Only after repository cleanup stabilizes, do directory/naming reorganization and UDID boundary cleanup.

## Next task
Run the v1_p35 device checklist in `DEVICE_TEST_MATRIX.md`. If passed, promote p35 as the new device-verified baseline and continue the next canonical-source cleanup batch.
