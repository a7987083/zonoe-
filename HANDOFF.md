# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p35-canonical-cleanup`.
- Current development version: `v1_p35`.
- Current p35 runtime/source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Current documentation HEAD is newer than the runtime/source commit; do not confuse docs-only commits with the p35 code baseline.
- Device-verified baseline: `v1_p34` / `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`.
- p34 device regression was explicitly reported passed by the user.

## p35 scope
P35 is a canonical-source cleanup built directly on the p34 device-verified baseline.

Intentional product change:
- Remove the obsolete `runtime.placeholder-203` / `暂无` control from the runtime menu.

Cleanup-only changes:
- Remove the tag-203 rendering branch and Dispatcher placeholder behavior (`人物血量`).
- Remove root-only remnants of stacks already removed from canonical `testmod/` in p34, including the old memory-editor/JRMemory stack and other retired helper/UI copies.
- Keep `testmod/` as the canonical product source surface.

Protected active product behavior:
- Remote download.
- VIP cloud save.
- Local-file browser.
- Backup / restore.
- Clear game data.
- Clear authorization records.
- IAP/no-ads runtime hook behavior.
- Ad-speed toggle and speed slider.

## Verification
- P35 source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- Workflow: `p35 Canonical Cleanup Build` / Run `34825140580` / success.
- Integration cleanup guard: passed.
- Registry smoke: passed with exactly 9 active features and 3 sections.
- Tag 203 absent from Registry/Renderer/Dispatcher.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Module ABI smoke/example exports: passed.
- A_customer iOS 12 arm64 + arm64e full Xcode build/package: passed.
- B_debug iOS 12 arm64 + arm64e full Xcode build/package: passed.
- A artifact: `testmod-v1_p35-A_customer` / ID `10340495885` / digest `sha256:df0983e3121db5fed1dc4092d7c6c5f36d781163b21bd2d9620f80b02e8e0735`.
- B artifact: `testmod-v1_p35-B_debug` / ID `10339941210` / digest `sha256:099d9560b38949558ecd56cc978f27d40970252683666f91ab5ea1b1fe407c65`.
- Real-device p35 validation: pending.

## Important repository-cleanup rule
Do not delete files merely because textual references are zero. Objective-C `+load`, constructors, swizzles, fishhook/rebind and `dlopen` paths can be active without ordinary call sites. Active hook stacks (`JiangHuHook`, `HookClass`, `ImgTool`) and current file/cloud/auth paths are protected until explicit dependency proof says otherwise.

## Next task
Run the p35 A_customer device checklist from `DEVICE_TEST_MATRIX.md`. Expected visible change: the `暂无` tag-203 row no longer exists. All nine retained product functions must still match p34 behavior. If that passes, promote p35 and continue the next root/testmod canonical-source cleanup batch.
