# zonoemenu HANDOFF

## Repository / current baseline
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p39b-jdstatus-audit`.
- Current promoted version: `v1_p39`.
- Runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Device-verified baseline: `v1_p39` / `613882da7068795533c530d45775f7ae5f79ed56`.
- User explicitly reported p39 real-device validation passed.
- Active PBX Sources: **75**.
- CI verification fix commit `5364d440442474f540d90b8d52f69fabb2b1deb7` changes validation only; it does not change runtime/source.

## P39-A completed — NSString(Tools) retirement
- Removed unused `testmod/category/NSString+Tools.m/.h` plus PBX references.
- Active PBX Sources reduced 76 → 75.
- Fixed verification Run `34891852090`: success.
- A_customer artifact ID `10367415741`, digest `sha256:15f128ffbd98a25b30cc365a7b48191330ae12ba0e400b3938d6c2c9637a6ec3`.
- A_customer dylib SHA256 `4e5f26da846bc4d9af0f9fce11f55dadf109074b49c9c8ab54f519fb2b89cdd2`.
- B_debug artifact ID `10367146287`, digest `sha256:d357fec51a71632803db598d0f71309cb8cf0d12997b68f106175088d3f2329b`.
- P38/P39 exported symbol sets are identical; only the retired NSString(Tools) unique selectors disappear as intended.
- Initial failed CI was a shell-verification bug (`grep -q` + `pipefail` causing SIGPIPE 141), not a runtime regression.
- P39 device regression passed and P39 is promoted.

## P39-B completed — JDStatusBarNotification audit
- Audit branch: `work/zonoemenu-v1-p39b-jdstatus-audit`.
- Test branch: `test/zonoemenu-v1-p39b-jdstatus-audit`.
- Audit script commit: `c4c1fce90549bc587e63d6e8d99d0ef42c8700e0`.
- CI trigger commit: `1f5960a1e979dfe46d996ef3e94252580fef3490`.
- Audit Run `34894434619`: **success**.
- Artifact ID `10368133245`, digest `sha256:5b46890e7594493ba4a2ee89e3c1b1a9e77dd66e09134d33577d49adf9ebf5ef`.
- Decision: **KEEP_LIVE_DEPENDENCY**.
- Eight Objective-C implementation files are PBX-active; the repository Swift wrapper is not compiled.

Live product dependencies:
- `testmod/菜单/PubgLoad.mm`: save/download status, progress updates, success/failure UI.
- `testmod/Bsphp/main.m`: startup and UDID acquisition/write/continuation status.
- `testmod/Bsphp/WX_NongShiFu123.mm`: first activation, authorization query, software-source/ad-speed authorization and completion status.

Stale include-only candidates:
- `testmod/导入导出/PreferenceManager.m`
- `testmod/工具箱/Hook/JiangHuHook.m`

These two stale imports do not make the JDStatus library removable. Do not delete any of its eight active source units.

## P39 active-target deletion audit closure
Retain these vendor/dependency units based on direct live evidence:
- AFNetworking
- MBProgressHUD
- SCLAlertView
- SSZipArchive/minizip
- SVProgressHUD
- JDStatusBarNotification

`NSString+Tools` is the only accepted active-target deletion from this audit cycle and is already device-verified in P39. Active-target slimming is complete at 75 Sources unless new evidence appears.

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

## Next phase — v1_p40
Audit canonical `testmod/` source layout, naming and include/dependency hygiene before making changes. Start with low-risk stale imports and structural debt, but do not bulk move/rename active product sources without an exact PBX/import map and guarded atomic transformation.

P39 remains the fallback/device baseline until a later runtime candidate passes contracts, A/B arm64+arm64e builds and real-device verification.
