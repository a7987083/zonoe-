# CHANGELOG_DEV

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
- Device verification is pending; p32 remains the promoted runtime baseline.

## 2026-09-13 — v1_p32 Device Verification
- Final p32 source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Workflow Run `34723015809`: **success**.
- Dispatcher equivalence/PBX/contract, Registry and Module ABI checks passed; A/B builds passed.
- User explicitly reported the full p32 real-device checklist passed.
- `v1_p32` is the current device-verified baseline.

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
