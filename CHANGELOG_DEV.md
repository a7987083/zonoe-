# CHANGELOG_DEV

## 2026-09-15 — v1_p41 UDID Bridge Boundary
- Promoted fallback baseline remains device-verified `v1_p39` / `613882da7068795533c530d45775f7ae5f79ed56`.
- P41 work branch: `work/zonoemenu-v1-p41-udidbridge-boundary`.
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- Test branch: `test/zonoemenu-v1-p41-udidbridge-boundary-build`.
- CI trigger/head: `925cd9b11364278e1927f300cc46e13dace2a239`.
- CI Run `34959813770`: **success**.
- Refactored `testmod/ZONServices/ZONUDIDBridge.h` from an implementation-heavy header into a declaration-only boundary.
- Added `testmod/ZONServices/ZONUDIDBridge.m` and mechanically moved the existing callback/nonce/storage/socket/request implementation without changing function bodies or state-machine constants.
- All formerly callable bridge names remain declared; bridge symbols are hidden from the dynamic export surface.
- PBX active Sources intentionally changed **75 → 76**; the sole addition is `ZONUDIDBridge.m`, and none of the previous 75 active sources was removed.
- Added `Tests/p41_udidbridge_boundary_contract.py` to prove product-diff scope, exact implementation migration, 75→76 source delta, protected-source identity, startup/authorization markers and UDID state-machine constants.
- `ZONUDIDBridge.m` compiled independently against the iPhoneOS SDK with `-Wall -Wextra -Werror`.
- A_customer and B_debug both fully built for arm64 + arm64e.
- P41/P40 exported dylib symbol sets are identical; no `ZONUDIDBridge*` symbol leaked into the public export surface.
- P41/P40 load-library sets are identical.
- A_customer artifact ID `10392947122`, digest `sha256:8b5ed743e7d9c958fa695fce7cdb4f0cf48984dc94a2162b539a75698392a336`.
- B_debug artifact ID `10393041635`, digest `sha256:4d9123c5df4554e71c4d33ba11ddcec15fb3adcc3c5470daaf21505ed6f4afd0`.
- **Real-device validation has not yet been reported; P41 is not promoted.**

## 2026-09-15 — v1_p40 Zero-Behavior Architecture Cleanup
- Source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`.
- Successful CI head: `8eeb3212f9236bea9eeb6be2f8ca88d71c2a0e5b`.
- CI Run `34915266733`: **success**.
- Moved implementation-only Dispatcher imports from `ZONFeatureDispatcher.h` into `.m`.
- Removed uncompiled `JDStatusBarNotification/Public/NotificationPresenter.swift`.
- Removed a stale JDStatus umbrella import from `PreferenceManager.m`.
- Active Sources remained 75.
- A_customer and B_debug outputs were byte-identical to promoted P39 binaries.
- P40 was not separately promoted by a real-device report.

## 2026-09-15 — P39-B JDStatusBarNotification Dependency Audit
- Baseline remained device-verified `v1_p39` runtime/source `613882da7068795533c530d45775f7ae5f79ed56`.
- No product runtime source or PBX membership was changed by the audit.
- Audit Run `34894434619`: **success**.
- Final decision: **KEEP_LIVE_DEPENDENCY**.
- Eight Objective-C implementation units are PBX-active; the Swift wrapper was not compiled.
- Direct live uses were proved in `PubgLoad.mm`, `main.m`, and `WX_NongShiFu123.mm`.
- Active-target deletion audit closed at 75 Sources.

## 2026-09-15 — v1_p39 Device Verification
- P39 runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Fixed verification Run `34891852090`: success.
- User explicitly reported P39 real-device validation passed.
- P39 is the current promoted device baseline.
- Active PBX Sources are 75 after removing only `NSString+Tools.m/.h` plus PBX references.
- P38/P39 exported symbol sets are identical; retired NSString(Tools) unique selectors are absent in P39 as intended.

## 2026-09-14 — v1_p38 Device Verification
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Build Run `34840451436`: success.
- User explicitly reported P38 real-device validation passed.

## 2026-09-14 — v1_p37 Canonical Mirror Cleanup
- Removed root mirrors only after exact tree-SHA equality proof.
- P37 runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow Run `34834303080`: success.

## 2026-09-14 — v1_p36 UDID Web Fallback
- Kept `zonoe://udid` as the preferred first-launch path.
- When the actual Zonoe `openURL` call fails, start the existing `WX_NongShiFu123 getUDID:` web/profile flow instead of stopping.
- Runtime/source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- Workflow Run `34829714958`: success.

## 2026-09-14 — v1_p35 Canonical Source Cleanup
- Removed placeholder feature 203 and retired root-only copies already absent from canonical `testmod/`.
- Preserved all nine active product features.
- Runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow Run `34825140580`: success; device validation passed.

## 2026-09-14 — v1_p34 Device Verification
- Source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Workflow Run `34758839228`: success; device validation passed.

## Earlier architecture cleanup
- v1_p33 Bootstrap / ModuleLoader Boundary: `0f12e4353e8859c585fe2975812964a28b7410d1` / Run `34733013479` success.
- v1_p32 Dispatcher split: `84f8b3898bee9d95ed4034d12842879cc56280d3` / Run `34723015809` / device passed.
- v1_p31 Feature Registry Boundary: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- v1_p30 EventBridge Boundary: `8e88b63611f19af6c42d9172c0f5741b34f51809`.
- v1_p29 Rendering Boundary: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- v1_p28 ZONCore Build Integration: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
