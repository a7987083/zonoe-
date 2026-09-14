# CHANGELOG_DEV

## 2026-09-14 — v1_p37 Canonical Mirror Cleanup
- Built from the documented p36 head `ffb90dbdc0be28f90db7648f6ad3e7e09462109d`.
- Bumped `VERSION` to `v1_p37`.
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` only after exact Git tree-SHA equality proof against `testmod/category/`, `testmod/工具箱/`, `testmod/SVProgressHUD/`, and `testmod/Package/`.
- Left divergent root trees (`Bsphp/`, `菜单/`, `导入导出/`, `视图菜单/`) untouched.
- Added `Tests/canonical_mirror_cleanup_contract.py` and guarded cleanup script `scripts/p37_apply_canonical_mirror_cleanup.py`.
- P37 canonical `testmod/` tree and `testmod.xcodeproj` are byte/tree-identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- P37 runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow Run `34834303080`: **success**. Mirror proof, p36 UDID behavior contract, Bootstrap/ModuleLoader, Dispatcher, Registry, Module ABI and full A/B Xcode builds passed.
- `A_customer`: artifact `10343388502`, digest `sha256:6396590bcb450aa8fb018e5c96883253136a629730625a144ca53c96b862a855`.
- `B_debug`: artifact `10343069444`, digest `sha256:efc025b8f3c816a262289a0b45da2c83bbb516cc12cec3aff72c5770f6a1fb52`.
- A_customer dylib SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`, exactly matching p36 A_customer as expected for repository-only cleanup.
- Device verification pending; p35 remains the promoted device baseline until the p36/p37 UDID paths are explicitly verified.

## 2026-09-14 — v1_p36 UDID Web Fallback
- Started from device-verified p35 runtime `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Kept `zonoe://udid` as the preferred first-launch path.
- Fixed the missing fallback: when the actual Zonoe `openURL` call fails, start the existing `WX_NongShiFu123 getUDID:` web/profile flow instead of stopping.
- Kept the legacy 404/profile behavior unchanged: open `udid.php?...`, exit, then on a later launch consume `udid<id>.txt`, store `DZUDID`, and resume authorization.
- Avoided `canOpenURL` preflight to prevent false negatives in injected hosts without `LSApplicationQueriesSchemes`.
- P36 runtime/source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- Workflow Run `34829714958`: **success** after correcting the canonical `testmod/category/getKeychain.h` include path.
- `A_customer`: artifact `10342130206`; dylib SHA256 `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`.
- `B_debug`: artifact `10341329186`.
- Device verification pending; p37 carries this runtime unchanged.

## 2026-09-14 — v1_p35 Canonical Source Cleanup
- Started from device-verified p34 source `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Bumped `VERSION` to `v1_p35`.
- Removed `runtime.placeholder-203` / `暂无` from `ZONFeatureRegistry`, renderer and Dispatcher.
- Removed root-only retired copies already absent from canonical `testmod/` after p34.
- Preserved all nine active product features.
- Runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow Run `34825140580`: **success**.
- User explicitly reported p35 real-device validation passed; p35 is the current promoted device baseline.

## 2026-09-14 — v1_p34 Device Verification
- P34 source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- Workflow Run `34758839228`: **success**.
- User explicitly reported p34 real-device validation passed.

## 2026-09-13 — v1_p33 Bootstrap / ModuleLoader Boundary
- Started from device-verified p32 source `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Converted Bootstrap and ModuleLoader headers to declarations-only and moved implementations into `.m` translation units.
- Runtime/source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- Corrected CI Run `34733013479`: **success**.
- Direct p33 device verification was superseded by later p34 device regression.

## 2026-09-13 — v1_p32 Device Verification
- Final p32 source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`.
- Workflow Run `34723015809`: **success**.
- User explicitly reported the full p32 real-device checklist passed.

## Earlier architecture cleanup
- v1_p31 Feature Registry Boundary: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- v1_p30 EventBridge Boundary: `8e88b63611d19af6c42d9172c0f5741b34f51809`.
- v1_p29 Rendering Boundary: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- v1_p28 ZONCore Build Integration: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
