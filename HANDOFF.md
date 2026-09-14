# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p37-canonical-mirrors`.
- Current development version: `v1_p37`.
- Current p37 runtime/source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- P37 documentation HEAD is newer than the runtime/source commit; do not confuse docs-only commits with the p37 code baseline.
- Device-verified baseline: `v1_p35` / `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- P35 real-device regression was explicitly reported passed by the user.

## Runtime lineage
### v1_p36 — UDID fallback fix
- Preferred path remains `zonoe://udid` with callback + nonce.
- If the actual `openURL` attempt cannot open Zonoe, the stable UDID API falls back to the existing `WX_NongShiFu123 getUDID:` web/profile acquisition flow.
- The legacy server/profile protocol was not redesigned: HTTP 404 opens `udid.php?...` and exits; a later app launch checks `udid<id>.txt`, stores `DZUDID`, and resumes the existing authorization flow.
- P36 runtime commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- CI Run `34829714958`: success.
- Device status: pending.

### v1_p37 — canonical mirror cleanup
- Repository-only cleanup on top of the documented p36 state.
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` only after each Git tree SHA exactly matched its `testmod/` counterpart.
- Kept divergent root trees `Bsphp/`, `菜单/`, `导入导出/`, and `视图菜单/` untouched.
- The entire p37 `testmod/` tree is identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- `testmod.xcodeproj` is also identical to p36.
- P37 A_customer dylib SHA256 `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9` is exactly the same as p36 A_customer.

## Protected active product behavior
- Remote download.
- VIP cloud save.
- Local-file browser.
- Backup / restore.
- Clear game data.
- Clear authorization records.
- IAP/no-ads runtime hook behavior.
- Ad-speed toggle and speed slider.
- Zonoe preferred UDID callback path and p36 web/profile fallback.

## Verification
- P37 source commit: `6a605489a5f3837301c2ed127088146538c4c849`.
- Workflow: `p37 Canonical Mirrors Build` / Run `34834303080` / success.
- Exact mirror SHA proof: passed for all four removed root mirrors.
- P37 canonical runtime tree equality against p36: passed.
- P36 UDID fallback behavior contract: passed under p37 inheritance.
- Registry smoke: passed with exactly 9 active features and 3 sections.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Module ABI smoke/example: passed.
- A_customer iOS 12 arm64 + arm64e full Xcode build/package: passed.
- B_debug iOS 12 arm64 + arm64e full Xcode build/package: passed.
- A artifact: `testmod-v1_p37-A_customer` / ID `10343388502` / digest `sha256:6396590bcb450aa8fb018e5c96883253136a629730625a144ca53c96b862a855`.
- B artifact: `testmod-v1_p37-B_debug` / ID `10343069444` / digest `sha256:efc025b8f3c816a262289a0b45da2c83bbb516cc12cec3aff72c5770f6a1fb52`.
- Real-device p37 validation: pending.

## Important cleanup rule
Do not delete files merely because textual references are zero. Objective-C `+load`, constructors, swizzles, fishhook/rebind and `dlopen` paths can be active without ordinary call sites. Active hook stacks (`JiangHuHook`, `HookClass`, `ImgTool`) and current file/cloud/auth paths are protected until explicit dependency proof says otherwise.

Do not mechanically delete the remaining divergent root trees. Audit file-by-file and prove which copy is canonical before any consolidation.

## Next task
Run the p37 A_customer device checklist from `DEVICE_TEST_MATRIX.md`. Because p37 runtime is byte-identical to p36, test the first-launch UDID flow with Zonoe installed and without Zonoe installed. A successful p37 device result promotes p37 and covers the inherited p36 runtime at the same time.
