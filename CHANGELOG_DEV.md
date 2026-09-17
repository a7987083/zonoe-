# CHANGELOG_DEV

## 2026-09-17 — v1_p48_1 StoreKit Residual Cleanup
- Work branch: `work/zonoemenu-v1-p48-storekit-cleanup`.
- Product source commit: `71eddfa0600112aa56a8bef45013d73f4673794a`.
- Test branch: `test/zonoemenu-v1-p48-storekit-cleanup-build`.
- Successful CI head: `efabe050194b87518c1442b4fe078ed7283db846`.
- CI Run `35180342515`: **success**.
- Removed residual StoreKit/App Store presentation surface from `YYYPicker` while preserving restore-save/import behavior.
- PBX unchanged versus P48; Active Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols are identical to P48.
- Load-library comparison differs from P48 by exactly one intended removal: `StoreKit.framework`; all other load libraries are unchanged.
- A_customer artifact ID `10480455519`, digest `sha256:beb2e1dd9b0b6ad913b5dc00911a890fd33293f9f33204196266474909b47dfe`.
- A_customer dylib SHA256 `36bbe4c32882d98b274fb7cfb40bf62f727502b4867765bee1f747c0e5fbe90d`.
- B_debug artifact ID `10480331340`, digest `sha256:fb21abd689eee241ae9331e24558756a342fd50a766fd8d4740bab5fde615e8e`.
- User explicitly reported P48.1 real-device validation normal.
- **P48.1 is promoted and is the current rollback/device baseline.**

## 2026-09-17 — v1_p47 Repository Hygiene / Generated Artifact Cleanup
- Repository candidate commit: `64f8575966d62695123b9f8444f89dbc98e796df`.
- Runtime source remained P46 `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- CI Run `35169166129`: success.
- Removed tracked generated package ZIP and added `Packages/*.zip` ignore rule without changing canonical runtime/product trees.
- Historical phase scripts/tests/workflows retained as reproducibility evidence.

## 2026-09-17 — v1_p46 Startup Side-Effect Instrumentation & Launch Contract
- Product source commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- CI Run `35167182449`: success.
- Added header-only launch instrumentation; no PBX source membership change.
- Behavior is covered by later promoted real-device baselines.

## 2026-09-16 — v1_p45 Legacy UDID Web/Profile Fallback Adapter Boundary
- Product source commit: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`.
- CI Run `35036655523`: success.
- Mechanically isolated the legacy `WX_NongShiFu123 getUDID:` fallback behind `ZONLegacyUDIDFallbackAdapter`.
- Behavior is covered by later promoted real-device baselines.

## 2026-09-16 — v1_p44 Authorization Orchestration Boundary
- Product source commit: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- CI Run `35020232205`: success.
- User explicitly reported real-device validation normal; later superseded by P48/P48.1.

## Earlier architecture cleanup
- P43 architecture audit: CI `35001000784` success.
- P42 Zonoe UDID API Boundary: CI `34995566144` success; device passed.
- P41 UDID Bridge Boundary: CI `34959813770` success; device passed.
- P40 zero-behavior cleanup: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`, CI `34915266733` success.
- P39 active target slimming: `613882da7068795533c530d45775f7ae5f79ed56`, device passed.
- P33 Bootstrap / ModuleLoader boundary: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- P32 Dispatcher split: `84f8b3898bee9d95ed4034d12842879cc56280d3`, device passed.
