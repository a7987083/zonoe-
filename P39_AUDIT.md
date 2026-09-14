# P39 Active Target Audit

## Baseline
- Device-verified baseline: `v1_p38` / runtime source commit `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Canonical product source surface: `testmod/` only.
- P39 audit branch: `work/zonoemenu-v1-p39-active-target-audit`.
- Audit CI Run `34845492258`: success.
- Audit artifact: `p39-active-target-audit` / ID `10347723184` / digest `sha256:2c75e6e4d7ec3fb0277a7a5f03b32f14ec2ffb30e1c3cc1a600f96974d45a5bd`.
- Audit is analysis-only; no runtime/product source has been removed yet.

## Active target inventory
- PBX Sources: **76**.
- Resolved active sources: **76**.
- `KEEP_PROTECTED`: **25**.
- `KEEP_RUNTIME_ENTRY`: **2**.
- `KEEP_REFERENCED`: **16**.
- `AUDIT_VENDOR_GROUP`: **32**.
- Initial `LOW_RISK_CANDIDATE`: **1**.

## P39-A — first cleanup candidate
### `testmod/category/NSString+Tools.m` + `NSString+Tools.h`
Status: **strong deletion candidate, pending guarded build removal**.

Evidence:
- No `+load`, constructor, hook/swizzle, fishhook/rebind or `dlopen` behavior.
- No active product source imports `NSString+Tools.h`.
- No product source outside the category uses the category-specific `sizeOfFontSize:` or `sizeWithString:...` selectors.
- The currently packaged dylib contains those selectors only because the category is presently compiled; that is not call-site evidence.
- The semantic scan also found `[attr fileSize]` in `daochucd.m`, but manual review shows `attr` is an `NSDictionary *` returned by `attributesOfItemAtPath:`. This is not an `NSString (Tools)` receiver and therefore is not evidence that the category is live.
- The `.m` and `.h` are still represented in the Xcode project, so a cleanup must remove the implementation/header PBX references and the Sources build entry together.

Required P39-A verification after removal:
1. PBX inventory resolves cleanly with 75 active Sources.
2. No stale `NSString+Tools` import/file reference remains.
3. P38 contracts stay green: UDID fallback, Bootstrap/ModuleLoader, Dispatcher, Registry (9 features / 3 sections), Module ABI.
4. Full A_customer and B_debug arm64/arm64e Xcode builds pass.
5. Inspect binary/ObjC metadata diff and confirm only the retired `NSString (Tools)` category selectors/metadata disappear; no protected product symbol changes.
6. Real-device smoke before promotion.

## Protected product / architecture sources
Do not remove in P39 cleanup without a new explicit proof:
- `testmod/Bsphp/main.m` — startup/bootstrap owner.
- `testmod/Bsphp/WX_NongShiFu123.mm` — authorization + web/profile UDID flow.
- all current `testmod/ZONBootstrap/` and `testmod/ZONCore/` implementation units.
- `testmod/视图菜单/NSObject+UI.m` — floating/menu UI + stable UDID C API.
- `testmod/菜单/JHDragView.m`, `PopupMenuVC.m`, `PubgLoad.mm`, `SandboxBrowserVC.m`.
- `testmod/导入导出/daochucd.m`, `fuhzu.m`, `UIDocumentPickerDelegate/YYYPicker.m`.
- `testmod/工具箱/Hook/JiangHuHook.m`.
- `testmod/工具箱/变速器/HookClass.m`, `ImgTool.m`, `fishhook/fishhook.c`.
- `testmod/工具箱/UISlider+VDTrackHeight.m`.

## Runtime/dynamic protected sources
- `testmod/菜单/ZIP/JHUIViewControllerDecoupler.m` uses `NSClassFromString`; keep.
- `testmod/Bsphp/AFNetworking/AFURLSessionManager.m` contains runtime class lookup inside the live AFNetworking unit; do not judge it by ordinary direct-call count.

## Referenced non-vendor sources — keep for now
- `testmod/Bsphp/Config.m`.
- `testmod/category/DES3Util.m`.
- `testmod/category/MF_Base64Additions.m`.
- `testmod/category/NSDictionary+StichingStringkeyValue.m`.
- `testmod/category/NSString+MD5.m`.
- `testmod/category/NSString+URLCode.m`.
- `testmod/category/NetWorkingApiClient.m`.
- `testmod/category/UIDevice+VKKeychainIDFV.m`.
- `testmod/category/getKeychain.m`.
- `testmod/导入导出/PreferenceManager.m`.
- `testmod/导入导出/UIDocumentPickerDelegate/NKOtherFilesModel.m`.
- `testmod/导入导出/UIDocumentPickerDelegate/NKSeleDocumentTool.m`.
- `testmod/导入导出/UIDocumentPickerDelegate/OtherFilesViewCell.m`.
- `testmod/菜单/FoldSectionView.m`.
- `testmod/菜单/SFHFKeychainUtils.m`.
- `testmod/菜单/ZIP/JHPP.m`.

## Vendor/dependency-unit decisions
### Keep — live evidence exists
- **AFNetworking (6 active source units)**: `NetWorkingApiClient` subclasses `AFHTTPSessionManager` and uses `AFSecurityPolicy` / `AFHTTPResponseSerializer`. Keep as a complete dependency unit.
- **MBProgressHUD (2)**: direct live importers include authorization and cloud-save code. Keep.
- **SCLAlertView (8)**: directly used by authorization UI. Keep.
- **SSZipArchive + bundled minizip (5)**: directly used by backup, restore, document import and cloud-save paths. Keep.
- **SVProgressHUD (4)**: directly used by authorization, backup/export, cloud-save and dispatcher/UI paths. Keep.

### P39-B — deeper group audit, no deletion yet
- **JDStatusBarNotification (8 active source units)**: first-pass token evidence reaches current data/file/UI paths, but direct importer resolution is weak because of the library's umbrella/public/private header structure. Audit the group API entry points and actual selector/class call sites before any removal decision.

## P39 decision rule
- Do not remove a file because textual reference count is zero.
- Objective-C categories, runtime selectors, `+load`, constructors, swizzles, fishhook/rebind and `dlopen` require semantic/runtime-aware review.
- Vendor libraries are kept/removed as dependency units, not by isolated `.m` count.
- The nine device-verified product features and the P36-P38 UDID behavior remain protected.

## Planned execution order
1. **P39-A:** guarded removal of `NSString+Tools.m/.h` + PBX references only.
2. Run full contracts + A/B build + binary metadata diff.
3. Device smoke and promote if clean.
4. **P39-B:** exact API/call-site audit of JDStatusBarNotification as a complete group.
5. Re-run the full 75-source inventory before considering any additional helper deletion.
