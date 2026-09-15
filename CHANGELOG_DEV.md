# CHANGELOG_DEV

## 2026-09-16 — v1_p44 Authorization Orchestration Boundary
- Work branch: `work/zonoemenu-v1-p44-authorization-orchestration-boundary`.
- Product source commit: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- Test branch: `test/zonoemenu-v1-p44-authorization-orchestration-boundary-build`.
- Successful CI head: `d6a110befbbc8c96dfffcae1f942c94b6011fe2d`.
- CI Run `35020232205`: **success**.
- Added `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m`.
- Mechanically moved authorization/reset orchestration from `testmod/Bsphp/main.m` into the coordinator; `main.m +load`, Bootstrap call position and framework preflight remain in `main.m`.
- The moved block includes `deletekm` compatibility IMP storage/call-through, UDID reset state, customer status helper, cached/fresh UDID authorization flow and `[auth loada]` continuation.
- `WX_NongShiFu123.mm`, `ZonoeUDIDAPI.m`, `ZONUDIDBridge.m`, Bootstrap, ModuleLoader, `PubgLoad.mm` and `JiangHuHook.m` remain protected/unchanged by the P44 contract.
- PBX active Sources changed **77 → 78**; sole new active source is `ZONAuthorizationCoordinator.m`.
- Added `Tests/p44_authorization_coordinator_contract.py` proving mechanical equivalence against P42 and unchanged `main.m` outside the extracted block/import.
- New coordinator translation unit independently compiles against iPhoneOS; strict warnings remain errors, with only the pre-existing third-party JDStatusBarNotification `UIWindowScene` availability warning suppressed in that isolated compile check.
- A_customer and B_debug full builds passed for `arm64 + arm64e`.
- P44/P42 exported symbol sets are identical.
- P44/P42 linked load-library sets are identical.
- A_customer artifact ID `10417242852`, digest `sha256:d9ce3432727b1c2ce5302ad4e732237ac7c45261ebd65cc3e7eda291ae2c71b8`.
- A_customer dylib SHA256 `f8d33f888ea5466217938af1cd338765252effb2cc4eda039a871579346e0435`.
- B_debug artifact ID `10417212790`, digest `sha256:2979768f150373160bffd1bddaf45e5d1ba1ee6d9ed1c8cdc05149485abd4a78`.
- P44 status is **CI verified / real-device pending**. P42 remains the promoted rollback/device baseline.

## 2026-09-16 — P43 Architecture State Refresh & Remaining Ownership Audit
- Created work branch `work/zonoemenu-v1-p43-architecture-audit` and test branch `test/zonoemenu-v1-p43-architecture-audit` from the post-P42 documentation head.
- Added `P43_ARCHITECTURE_AUDIT.md` with current P42 startup/auth/legacy ownership findings.
- Added `Tests/p43_architecture_audit.py` and `.github/workflows/p43-architecture-audit.yml`.
- P43 audit CI Run `35001000784`: **success**.
- Contract proves canonical product runtime/PBX (`testmod/` + `testmod.xcodeproj`) is unchanged from P42 product commit `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Active PBX Sources remain exactly **77**.
- Verified `main.m`, `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m`, `ZONUDIDBridge.m` and `ZonoeUDIDAPI.m` remain active target units.
- Selected P44 target: the authorization orchestration/reset helper block currently owned by `testmod/Bsphp/main.m`.
- Planned P44 boundary: `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m`.
- Explicitly excluded direct rewrite/split of `WX_NongShiFu123.mm` from P44 because it remains a broad high-risk legacy authorization/network/UI implementation.
- No runtime source, PBX, binary, authorization behavior, UDID behavior, UI, persistence, timing, threading, endpoint or protocol semantics changed in P43.
- Real-device validation is not required for P43 because the runtime tree is unchanged; P42 remains the promoted device/rollback baseline.

## 2026-09-16 — Canonical Post-P42 Refactor Plan
- Published the complete post-P42 refactor sequence in `ROADMAP.md` so future work does not depend on chat history.
- Defined P43 through P50 with explicit goals, scope, forbidden changes, verification gates, exit criteria and promotion rules.
- P43: Architecture State Refresh & Remaining Ownership Audit.
- P44: Authorization Orchestration Boundary.
- P45: Legacy UDID Web/Profile Fallback Adapter Boundary.
- P46: Startup Side-Effect Instrumentation & Launch Contract.
- P47: Repository Hygiene / Generated Artifact Cleanup.
- P48: Legacy God-Object Split #1, target selected only by P43 evidence.
- P49: Active Target / Dead Code / Dependency Audit.
- P50: Refactor Stabilization / Architecture Freeze.
- Updated `PROJECT_STATE.json` with the machine-readable P42 promoted baseline and the full planned phase list.
- Updated `HANDOFF.md` with takeover rules and the canonical-document precedence rule.
- Refreshed `KNOWN_ISSUES.md` to close obsolete P41/P42 ownership issues and track remaining startup/auth/legacy/hygiene risks.
- No product runtime source, PBX membership, binary, authorization/UDID behavior, UI behavior, timing or threading semantics changed by this documentation update.

## 2026-09-16 — v1_p42 Zonoe UDID API Boundary
- Work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Product source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- CI Run `34995566144`: **success**.
- Moved the existing `ZonoeUDIDAPI` implementation mechanically from `testmod/视图菜单/NSObject+UI.m` into `testmod/ZONServices/ZonoeUDIDAPI.m`.
- `NSObject+UI.m` now retains UI ownership only for this boundary.
- PBX active Sources changed **76 → 77**; the sole addition is `ZonoeUDIDAPI.m`.
- Added exact migration contract and independent `ZonoeUDIDAPI.m` iPhoneOS compile with `-Wall -Wextra -Werror`.
- A_customer and B_debug both fully built for arm64 + arm64e.
- P42/P41 exported dylib symbol sets are identical.
- P42/P41 load-library sets are identical.
- A_customer artifact ID `10407391591`, digest `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- A_customer dylib SHA256 `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- B_debug artifact ID `10406554164`, digest `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.
- User explicitly reported P42 real-device validation normal.
- **P42 is now the promoted device-verified baseline.**

## 2026-09-16 — v1_p41 Device Verification
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI Run `34959813770`: success.
- User explicitly reported P41 real-device validation normal before P42 development started.
- P41 was promoted and then superseded by the later P42 device pass.

## 2026-09-15 — v1_p41 UDID Bridge Boundary
- Work branch: `work/zonoemenu-v1-p41-udidbridge-boundary`.
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- Test branch: `test/zonoemenu-v1-p41-udidbridge-boundary-build`.
- CI trigger/head: `925cd9b11364278e1927f300cc46e13dace2a239`.
- CI Run `34959813770`: **success**.
- Refactored `testmod/ZONServices/ZONUDIDBridge.h` from an implementation-heavy header into a declaration-only boundary.
- Added `testmod/ZONServices/ZONUDIDBridge.m` and mechanically moved the existing callback/nonce/storage/socket/request implementation without changing function bodies or state-machine constants.
- PBX active Sources intentionally changed **75 → 76**; the sole addition is `ZONUDIDBridge.m`.
- A_customer artifact ID `10392947122`, digest `sha256:8b5ed743e7d9c958fa695fce7cdb4f0cf48984dc94a2162b539a75698392a336`.
- B_debug artifact ID `10393041635`, digest `sha256:4d9123c5df4554e71c4d33ba11ddcec15fb3adcc3c5470daaf21505ed6f4afd0`.

## 2026-09-15 — v1_p40 Zero-Behavior Architecture Cleanup
- Source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`.
- Successful CI head: `8eeb3212f9236bea9eeb6be2f8ca88d71c2a0e5b`.
- CI Run `34915266733`: **success**.
- Active Sources remained 75.
- A_customer and B_debug outputs were byte-identical to promoted P39 binaries.

## 2026-09-15 — P39-B JDStatusBarNotification Dependency Audit
- Audit Run `34894434619`: **success**.
- Final decision: **KEEP_LIVE_DEPENDENCY**.

## 2026-09-15 — v1_p39 Device Verification
- P39 runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Fixed verification Run `34891852090`: success.
- User explicitly reported P39 real-device validation passed.

## 2026-09-14 — v1_p38 Device Verification
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Build Run `34840451436`: success.
- User explicitly reported P38 real-device validation passed.

## 2026-09-14 — v1_p37 Canonical Mirror Cleanup
- Runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow Run `34834303080`: success.

## 2026-09-14 — v1_p36 UDID Web Fallback
- Runtime/source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- Workflow Run `34829714958`: success.

## 2026-09-14 — v1_p35 Canonical Source Cleanup
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
