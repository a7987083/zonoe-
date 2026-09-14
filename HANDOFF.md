# zonoemenu HANDOFF

## Repository / current baseline
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p39-active-target-audit`.
- Current development version: `v1_p39`.
- Current runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Device-verified baseline: `v1_p39` / `613882da7068795533c530d45775f7ae5f79ed56`.
- User explicitly reported p39 real-device validation passed.
- CI verification fix commit `5364d440442474f540d90b8d52f69fabb2b1deb7` changes validation only; it does not change runtime/source.

## P39-A completed
- Removed unused `testmod/category/NSString+Tools.m/.h` plus PBX references.
- Active PBX Sources reduced 76 → 75.
- Fixed verification Run `34891852090`: success.
- A_customer artifact ID `10367415741`, digest `sha256:15f128ffbd98a25b30cc365a7b48191330ae12ba0e400b3938d6c2c9637a6ec3`.
- A_customer dylib SHA256 `4e5f26da846bc4d9af0f9fce11f55dadf109074b49c9c8ab54f519fb2b89cdd2`.
- B_debug artifact ID `10367146287`, digest `sha256:d357fec51a71632803db598d0f71309cb8cf0d12997b68f106175088d3f2329b`.
- P38/P39 exported symbol sets are identical; only the retired NSString(Tools) unique selectors disappear as intended.
- Initial failed CI was a shell-verification bug (`grep -q` + `pipefail` causing SIGPIPE 141), not a runtime regression.

## Protected active product behavior
- Floating entry and menu stack.
- Remote download.
- VIP cloud save.
- Local-file browser.
- Backup / restore.
- Clear game data.
- Clear authorization records.
- IAP/no-ads runtime hook behavior.
- Ad-speed toggle and speed slider.
- Zonoe preferred UDID callback path and web/profile fallback.
- Active hook stacks `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind.

## Next phase — P39-B
Audit `JDStatusBarNotification` as one complete 8-source dependency unit.

Required before deletion:
- enumerate all active files and headers;
- map imports and public API calls;
- search dynamic/runtime references and automatic entry points;
- identify feature-path reachability;
- decide keep whole group, replace dependency boundary, or remove whole group;
- never delete individual files from the group based only on zero textual references.

If removal is proven safe, use a guarded change and repeat contracts, Registry smoke, Module ABI, A/B Xcode builds, arm64/arm64e checks, ObjC/export diff and real-device verification.

P39 remains the fallback baseline until a later candidate passes those gates.
