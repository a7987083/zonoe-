# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p38-divergent-audit`.
- Current development version: `v1_p38`.
- Current p38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Documentation HEAD is newer than the runtime/source commit; do not confuse docs-only commits with the p38 code baseline.
- Device-verified baseline: `v1_p38` / `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- User explicitly reported p38 real-device validation passed.

## Runtime lineage
### v1_p36 — UDID fallback fix
- Preferred path remains `zonoe://udid` with callback + nonce.
- If the actual `openURL` attempt cannot open Zonoe, fall back to the existing `WX_NongShiFu123 getUDID:` web/profile flow.
- Legacy server/profile protocol remains unchanged: HTTP 404 opens `udid.php?...` and exits; a later launch checks `udid<id>.txt`, stores `DZUDID`, and resumes authorization.
- Runtime commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- This runtime behavior is covered by the later byte-identical p38 device pass.

### v1_p37 — identical-root mirror cleanup
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` after exact tree-SHA equality proof.
- Product runtime remained byte-identical to p36.
- Covered by p38 device pass.

### v1_p38 — canonical product source finalization
- Audit Run `34840224717` proved all 76 PBX product Sources resolve under `testmod/`; zero root copies are active.
- Remaining root `Bsphp/`, `菜单/`, `导入导出/`, and `视图菜单/` contained no root-only files. Their differences were older same-path copies only.
- Removed all four remaining root source mirrors.
- `testmod/` is now the unique canonical product source surface.
- Complete `testmod/` tree and `testmod.xcodeproj` remain identical to p36 runtime.
- P38 A_customer dylib SHA256 `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9` exactly matches p36 and p37.
- Real-device validation: passed; p38 is the current promoted baseline.

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
- P38 source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Audit: `p38 Divergent Source Audit` / Run `34840224717` / success / artifact `10345433625`.
- Build workflow: `p38 Canonical Source Build` / Run `34840451436` / success.
- Canonical-source contract: passed.
- Canonical runtime tree equality against p36: passed.
- Registry smoke: passed with exactly 9 active features and 3 sections.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Module ABI smoke/example: passed.
- A_customer iOS 12 arm64 + arm64e full Xcode build/package: passed.
- A_customer exact SHA equality against p36/p37: passed.
- B_debug iOS 12 arm64 + arm64e full Xcode build/package: passed.
- A artifact: `testmod-v1_p38-A_customer` / ID `10345384325` / digest `sha256:e1d1d37af6b0dd8bbb77f17f5bda9bfe95f7a30a321fdff647ae1aa97ce22c38`.
- B artifact: `testmod-v1_p38-B_debug` / ID `10345514011` / digest `sha256:a934a5c2d81782a27398b72d0a390c3117df7d64d0eb00c45c431d619f81c02a`.
- Real-device p38 validation: passed.

## Important cleanup rule
From p38 onward, product-source audits operate on canonical `testmod/` only. Do not delete active target files merely because textual references are zero. Objective-C `+load`, constructors, swizzles, fishhook/rebind and `dlopen` paths can be active without ordinary call sites.

Active hook stacks (`JiangHuHook`, `HookClass`, `ImgTool`) and current file/cloud/auth paths remain protected until explicit dependency proof says otherwise.

## Next task — v1_p39
Audit the active 76-source target inside `testmod/` for obsolete helpers and dependency units. Start with evidence gathering only, then delete only proven-safe candidates. Preserve all nine verified product features and the p36/p38 UDID behavior.
