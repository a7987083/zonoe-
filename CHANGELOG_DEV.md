# CHANGELOG_DEV

## 2026-09-15 — v1_p39 Device Verification
- P39 runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Fixed verification Run `34891852090`: success.
- User explicitly reported p39 real-device validation passed.
- P39 is now the current promoted device baseline.
- Active PBX Sources are 75 after removing only `NSString+Tools.m/.h` plus PBX references.
- P38/P39 exported symbol sets are identical; retired NSString(Tools) unique selectors are absent in P39 as intended.
- Initial P39 CI failure was validation-only: `grep -q` terminated the pipeline early and `strings` returned SIGPIPE 141 under `pipefail`. CI fix commit `5364d440442474f540d90b8d52f69fabb2b1deb7` did not change runtime/source.
- Next phase: P39-B complete-unit audit of the 8-source `JDStatusBarNotification` dependency. No deletion is approved yet.

## 2026-09-14 — v1_p38 Device Verification
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Audit Run `34840224717`: success.
- Build Run `34840451436`: success.
- User explicitly reported p38 real-device validation passed.
- P38 became the promoted device baseline before P39.

## 2026-09-14 — v1_p38 Canonical Product Source Finalization
- All 76 PBX product Sources resolved under `testmod/`; zero root copies were active.
- Removed remaining root `Bsphp/`, `菜单/`, `导入导出/`, and `视图菜单/` mirrors after proving they contained no root-only files.
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Workflow Run `34840451436`: success.
- A_customer dylib SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`.

## 2026-09-14 — v1_p37 Canonical Mirror Cleanup
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` only after exact tree-SHA equality proof.
- P37 runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow Run `34834303080`: success.

## 2026-09-14 — v1_p36 UDID Web Fallback
- Kept `zonoe://udid` as the preferred first-launch path.
- When the actual Zonoe `openURL` call fails, start the existing `WX_NongShiFu123 getUDID:` web/profile flow instead of stopping.
- P36 runtime/source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- Workflow Run `34829714958`: success.

## 2026-09-14 — v1_p35 Canonical Source Cleanup
- Removed placeholder feature 203 and retired root-only copies already absent from canonical `testmod/`.
- Preserved all nine active product features.
- Runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow Run `34825140580`: success.
- User explicitly reported p35 real-device validation passed.

## 2026-09-14 — v1_p34 Device Verification
- P34 source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Workflow Run `34758839228`: success.
- User explicitly reported p34 real-device validation passed.

## 2026-09-13 — v1_p33 Bootstrap / ModuleLoader Boundary
- Runtime/source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- Corrected CI Run `34733013479`: success.

## 2026-09-13 — v1_p32 Device Verification
- Final p32 source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Workflow Run `34723015809`: success.
- User explicitly reported the full p32 real-device checklist passed.

## Earlier architecture cleanup
- v1_p31 Feature Registry Boundary: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- v1_p30 EventBridge Boundary: `8e88b63611f19af6c42d9172c0f5741b34f51809`.
- v1_p29 Rendering Boundary: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- v1_p28 ZONCore Build Integration: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
