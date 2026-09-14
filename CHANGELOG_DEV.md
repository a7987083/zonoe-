# CHANGELOG_DEV

## 2026-09-14 — v1_p38 Device Verification
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Audit Run `34840224717`: success.
- Build Run `34840451436`: success.
- User explicitly reported p38 real-device validation passed.
- P38 is now the current promoted device baseline.
- Because p38 `testmod/`, `testmod.xcodeproj`, and A_customer dylib are byte-identical to p36/p37 runtime, this device pass also covers the inherited p36 UDID web-fallback behavior and p37 repository-only cleanup.
- Next phase: `v1_p39` active-target obsolete-helper/dependency audit inside canonical `testmod/` only.

## 2026-09-14 — v1_p38 Canonical Product Source Finalization
- Built from p37 documented head `5f9d3844bff98314e0af109a6803a4642e685cb7`.
- Bumped `VERSION` to `v1_p38`.
- Audit Run `34840224717` proved all 76 PBX product Sources resolve under `testmod/`; zero root copies are active.
- Audited the remaining divergent root mirrors: `Bsphp/`, `菜单/`, `导入导出/`, `视图菜单/`.
- Each root tree contained **zero root-only files**; all root files had canonical `testmod/...` counterparts. Divergence was limited to older copies of same-path files.
- Removed all four remaining root source mirrors. `testmod/` is now the unique product source surface.
- Added guarded cleanup `scripts/p38_apply_canonical_source_finalize.py` and `Tests/p38_canonical_source_contract.py`.
- P38 canonical `testmod/` tree and `testmod.xcodeproj` remain exactly identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Workflow Run `34840451436`: **success**. Canonical-source guard, Bootstrap/ModuleLoader, Dispatcher, Registry, Module ABI and full A/B Xcode builds passed.
- `A_customer`: artifact `10345384325`, digest `sha256:e1d1d37af6b0dd8bbb77f17f5bda9bfe95f7a30a321fdff647ae1aa97ce22c38`.
- `B_debug`: artifact `10345514011`, digest `sha256:a934a5c2d81782a27398b72d0a390c3117df7d64d0eb00c45c431d619f81c02a`.
- A_customer dylib SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`, exactly matching p36 and p37.

## 2026-09-14 — v1_p37 Canonical Mirror Cleanup
- Built from the documented p36 head `ffb90dbdc0be28f90db7648f6ad3e7e09462109d`.
- Bumped `VERSION` to `v1_p37`.
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` only after exact Git tree-SHA equality proof against their `testmod/` counterparts.
- P37 runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow Run `34834303080`: **success**.
- A_customer dylib SHA256 exactly matched p36.

## 2026-09-14 — v1_p36 UDID Web Fallback
- Started from device-verified p35 runtime `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Kept `zonoe://udid` as the preferred first-launch path.
- When the actual Zonoe `openURL` call fails, start the existing `WX_NongShiFu123 getUDID:` web/profile flow instead of stopping.
- Kept the legacy 404/profile behavior unchanged.
- P36 runtime/source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- Workflow Run `34829714958`: **success**.
- Later covered by the byte-identical p38 real-device pass.

## 2026-09-14 — v1_p35 Canonical Source Cleanup
- Started from device-verified p34 source `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Removed `runtime.placeholder-203` / `暂无` from Registry, renderer and Dispatcher.
- Removed root-only retired copies already absent from canonical `testmod/`.
- Preserved all nine active product features.
- Runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow Run `34825140580`: **success**.
- User explicitly reported p35 real-device validation passed.

## 2026-09-14 — v1_p34 Device Verification
- P34 source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Workflow Run `34758839228`: **success**.
- User explicitly reported p34 real-device validation passed.

## 2026-09-13 — v1_p33 Bootstrap / ModuleLoader Boundary
- Runtime/source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- Corrected CI Run `34733013479`: **success**.
- Direct p33 device verification was superseded by later p34 device regression.

## 2026-09-13 — v1_p32 Device Verification
- Final p32 source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Workflow Run `34723015809`: **success**.
- User explicitly reported the full p32 real-device checklist passed.

## Earlier architecture cleanup
- v1_p31 Feature Registry Boundary: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- v1_p30 EventBridge Boundary: `8e88b63611f19af6c42d9172c0f5741b34f51809`.
- v1_p29 Rendering Boundary: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- v1_p28 ZONCore Build Integration: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
