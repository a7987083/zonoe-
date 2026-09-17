# CHANGELOG_DEV

## 2026-09-18 — v1_p50 Refactor Stabilization / Architecture Freeze — IN PROGRESS
- Work branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- Runtime baseline remains promoted P49 commit `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- Added `P50_ARCHITECTURE_FREEZE.md`.
- Added `Tests/p50_architecture_freeze_contract.py`.
- Added `.github/workflows/p50-architecture-freeze.yml`.
- P50 policy: no runtime/product drift from P49; structural changes require a new explicitly scoped stage.

## 2026-09-18 — v1_p49 Active Target / Dead Code / Dependency Audit
- Work branch: `work/zonoemenu-v1-p49-active-target-audit`.
- Product source commit: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- Test branch: `test/zonoemenu-v1-p49-active-target-audit`.
- Successful CI head: `592aa64cd35307e358716d3f1517a75a41e986f3`.
- CI Run `35195152912`: **success**.
- Proved `Network.framework` had zero source consumers and removed it from PBX only.
- Active PBX Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols are identical to P48.1.
- Load-library comparison differs from P48.1 by exactly one intended removal: `Network.framework`.
- A_customer artifact ID `10485344383`, digest `sha256:33ae7fda25128e9d0bd6a167a82aedaf3a1272a8ceb13111bef23c58ff270c5d`.
- A_customer dylib SHA256 `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- B_debug artifact ID `10485622521`, digest `sha256:9156b57fd832461274f3c8d1625c8b8213d556c9862b32d1d461294783a23e27`.
- User explicitly reported P49 real-device validation normal.
- **P49 is promoted and is the current rollback/device baseline.**

## 2026-09-17 — v1_p48_1 StoreKit Residual Cleanup
- Product source commit: `71eddfa0600112aa56a8bef45013d73f4673794a`.
- CI Run `35180342515`: **success**.
- Removed residual StoreKit/App Store presentation surface from `YYYPicker` while preserving restore-save/import behavior.
- Active Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Load-library comparison differs from P48 by exactly one intended removal: `StoreKit.framework`.
- User explicitly reported P48.1 real-device validation normal.
- Superseded by P49.

## 2026-09-17 — v1_p47 Repository Hygiene / Generated Artifact Cleanup
- Repository candidate commit: `64f8575966d62695123b9f8444f89dbc98e796df`.
- Runtime source remained P46 `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- CI Run `35169166129`: success.

## Earlier architecture cleanup
- P46 Startup Side-Effect Instrumentation & Launch Contract: CI `35167182449` success.
- P45 Legacy UDID Web/Profile Fallback Adapter Boundary: CI `35036655523` success.
- P44 Authorization Orchestration Boundary: CI `35020232205` success; device passed.
- P43 architecture audit: CI `35001000784` success.
- P42 Zonoe UDID API Boundary: CI `34995566144` success; device passed.
- P41 UDID Bridge Boundary: CI `34959813770` success; device passed.
- P40 zero-behavior cleanup: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`, CI `34915266733` success.
- P39 active target slimming: `613882da7068795533c530d45775f7ae5f79ed56`, device passed.
- P33 Bootstrap / ModuleLoader boundary: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- P32 Dispatcher split: `84f8b3898bee9d95ed4034d12842879cc56280d3`, device passed.
