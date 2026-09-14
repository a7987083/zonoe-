# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p35`.
- Source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- CI Run `34825140580`: success.
- Real-device regression: user explicitly reported p35 passed.

## Current development candidate — v1_p38
Status: `ci_verified_device_pending`.

### Runtime lineage
- `v1_p36` introduced the UDID fallback fix: keep `zonoe://udid` first, and when the real `openURL` call fails, automatically start the existing web/profile UDID flow.
- `v1_p37` removed four root mirrors that were exactly identical to their `testmod/` counterparts.
- `v1_p38` audited and removed the four remaining divergent root mirrors after proving none is a PBX product source and none contains any root-only file.
- The complete `testmod/` tree and `testmod.xcodeproj` in p38 remain exactly identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- P38 A_customer dylib SHA256 is `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`, exactly matching p36 and p37.

### P38 implemented
- `VERSION`: `v1_p37` -> `v1_p38`.
- Audit Run `34840224717` proved all **76** PBX Sources resolve to `testmod/`; root product source count is **0**.
- `Bsphp/`: root 10 files vs canonical 39; 7 identical, 3 older divergent copies, 0 root-only files.
- `菜单/`: root/canonical 28 each; 25 identical, 3 older divergent copies, 0 root-only files.
- `导入导出/`: root/canonical 34 each; 32 identical, 2 older divergent copies, 0 root-only files.
- `视图菜单/`: root/canonical 2 each; 2 divergent older copies, 0 root-only files.
- Removed all four root mirrors and retained only `testmod/Bsphp`, `testmod/菜单`, `testmod/导入导出`, and `testmod/视图菜单`.
- Canonical product source surface is now **`testmod/` only**.
- All nine active product features and the p36 UDID fallback behavior remain byte-for-byte unchanged.

### Verification completed
- P38 divergent-source audit: success; artifact `10345433625`.
- P38 canonical-source guard: passed.
- Canonical `testmod/` tree equality against p36 runtime: passed.
- Xcode project equality against p36 runtime: passed.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Feature Registry smoke: passed with 9 features / 3 sections.
- Module ABI smoke/example: passed.
- A_customer full iOS 12 arm64/arm64e Xcode build/package: passed.
- A_customer exact SHA equivalence check against p36/p37: passed.
- B_debug full iOS 12 arm64/arm64e Xcode build/package: passed.
- Workflow Run `34840451436`: success.
- P38 runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.

## Cleanup backlog after p38
1. P39: audit the **active 76-source target inside canonical `testmod/` only** for obsolete helpers/dependencies.
2. Keep Objective-C `+load`, constructors, swizzles, fishhook/rebind, `dlopen`, current file/cloud/auth and runtime hook paths protected until explicit proof permits deletion.
3. Re-audit AFNetworking, MBProgressHUD/SCLAlertView/JDStatusBarNotification and other vendor/helper groups as complete dependency units rather than deleting isolated `.m` files by textual reference count.
4. After active-target slimming stabilizes, begin directory/naming cleanup and move remaining large header-owned implementation boundaries into `.m` files.

## Next task
Real-device test the `v1_p38` A_customer artifact. Because p38 runtime and the produced A_customer dylib are byte-identical to p36/p37, focus on the first-launch UDID behavior: test once with Zonoe installed and once without Zonoe. A successful p38 device result promotes p38 and covers the p36-p38 runtime lineage at the same time.
