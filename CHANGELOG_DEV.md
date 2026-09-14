# CHANGELOG_DEV

## 2026-09-14 — v1_p35 Canonical Source Cleanup
- Started from device-verified p34 source `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Bumped `VERSION` to `v1_p35`.
- Removed `runtime.placeholder-203` / `暂无` from `ZONFeatureRegistry`.
- Removed the tag-203 branch from `ZONFeatureRenderer` and the placeholder Dispatcher behavior (`人物血量`) from `ZONFeatureDispatcher`.
- Updated Registry/Dispatcher tests to require exactly nine active product features and to reject tag 203.
- Removed root-only retired copies already absent from canonical `testmod/` after p34, including JRMemory/memory-editor remnants, old alternate-icon UI, drag/screenshot helpers, empty categories/helpers and the retired AppStore helper.
- Preserved all nine active menu features and protected their supporting hook/file/cloud/auth stacks.
- Final p35 runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow Run `34825140580`: **success**. Integration guard, Bootstrap/ModuleLoader contract, Dispatcher contract, Registry smoke (9 features / 3 sections), Module ABI smoke and full A/B Xcode builds passed.
- `A_customer`: artifact `10340495885`, digest `sha256:df0983e3121db5fed1dc4092d7c6c5f36d781163b21bd2d9620f80b02e8e0735`.
- `B_debug`: artifact `10339941210`, digest `sha256:099d9560b38949558ecd56cc978f27d40970252683666f91ab5ea1b1fe407c65`.
- Device verification pending; p34 remains the promoted device baseline until explicit p35 pass.

## 2026-09-14 — v1_p34 Device Verification
- P34 source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Workflow Run `34758839228`: **success**.
- A_customer and B_debug full Xcode builds passed after the first retired-feature cleanup.
- User explicitly reported p34 real-device validation passed.
- `v1_p34` is the current device-verified baseline and implicitly covers the earlier p33 Bootstrap/ModuleLoader refactor.

## 2026-09-13 — v1_p33 Bootstrap / ModuleLoader Boundary
- Started from device-verified p32 source `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Bumped `VERSION` to `v1_p33`.
- Converted `testmod/ZONBootstrap/ZONBootstrap.h` to declarations-only and moved the verified body to `ZONBootstrap.m`.
- Converted `testmod/ZONCore/ZONModuleLoader.h` to declarations-only and moved loader implementation to `ZONModuleLoader.m`.
- Corrected prior documentation: ModuleLoader is active because Bootstrap calls `ZONLoadBundledModules()`; before p33 it was compiled transitively from the header.
- Registered both new `.m` translation units in the Xcode target; final p33 source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- Added `Tests/bootstrap_moduleloader_contract.py`, comparing all moved function bodies against p32 and locking module-loader ABI/safety invariants.
- Permanent Module ABI CI now includes the bootstrap/module-loader contract.
- Initial p33 build Run `34732947582` failed only because standalone `clang -c` validation passed a linker-only `-framework Foundation` flag under `-Werror`; source contracts had already passed.
- Corrected CI Run `34733013479`: **success**. Independent compilation, symbol checks, Dispatcher contract, Registry smoke, Module ABI smoke and full A/B Xcode builds passed.
- `A_customer`: artifact `10309833185`, digest `sha256:f9de22ed5a35ea4c40b27968499ffe1d50bdaa13b3a7511dc4bbeef07aa3a111`.
- `B_debug`: artifact `10309663469`, digest `sha256:63f77461e5338d07ea2399ca2600c238374414ddcef4c6d096c860aac887207e`.
- Direct p33 device verification was superseded by the later p34 device regression, which includes the p33 code.

## 2026-09-13 — v1_p32 Device Verification
- Final p32 source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Workflow Run `34723015809`: **success**.
- Dispatcher equivalence/PBX/contract, Registry and Module ABI checks passed; A/B builds passed.
- User explicitly reported the full p32 real-device checklist passed.

## 2026-09-12 — v1_p32-B Dispatcher Source Split
- Converted `ZONFeatureDispatcher.h` to declarations-only and added `ZONFeatureDispatcher.m` with mechanically moved bodies.
- Added permanent Dispatcher contract tests and completed PBX/A-B verification.

## 2026-09-12 — v1_p32-A Dispatcher Boundary Audit
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Workflow Run `34703403975`: success.

## 2026-09-12 — v1_p31 Feature Registry Boundary Cleanup
- Integrated source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- CI Run `34673034214`: success.

## 2026-09-12 — v1_p30 EventBridge Boundary Cleanup
- Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`.

## 2026-09-12 — v1_p29 Rendering Boundary Cleanup
- Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.

## 2026-09-12 — v1_p28 ZONCore Build Integration
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
