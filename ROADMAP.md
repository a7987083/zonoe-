# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p35`.
- Source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`.
- CI Run `34825140580`: success.
- Real-device regression: user explicitly reported p35 passed.

## Current development candidate — v1_p37
Status: `ci_verified_device_pending`.

### Runtime lineage
- `v1_p36` introduced the UDID fallback fix: keep `zonoe://udid` first, and when the real `openURL` call fails, automatically start the existing web/profile UDID flow.
- `v1_p37` is repository-only canonical-source cleanup on top of the documented p36 state.
- The complete `testmod/` tree and `testmod.xcodeproj` in p37 are exactly identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
- The produced p37 A_customer dylib SHA256 is also identical to p36: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`.

### P37 implemented
- `VERSION`: `v1_p36` -> `v1_p37`.
- Removed root `category/` after proving its Git tree SHA exactly equals `testmod/category/`.
- Removed root `工具箱/` after proving its Git tree SHA exactly equals `testmod/工具箱/`.
- Removed root `SVProgressHUD/` after proving its Git tree SHA exactly equals `testmod/SVProgressHUD/`.
- Removed root `Package/` after proving its Git tree SHA exactly equals `testmod/Package/`.
- Kept divergent root trees (`Bsphp/`, `菜单/`, `导入导出/`, `视图菜单/`) untouched for later audited consolidation.
- Preserved all nine active product features and the p36 UDID fallback behavior byte-for-byte.

### Verification completed
- Exact mirror tree-SHA proof: passed for all four removed root mirrors.
- Canonical `testmod/` tree equality against p36 runtime: passed.
- Xcode project equality against p36 runtime: passed.
- P36 UDID fallback behavior contract inherited and passed.
- Bootstrap/ModuleLoader contract: passed.
- Dispatcher contract: passed.
- Feature Registry smoke: passed with 9 features / 3 sections.
- Module ABI smoke/example: passed.
- A_customer full iOS 12 arm64/arm64e Xcode build/package: passed.
- B_debug full iOS 12 arm64/arm64e Xcode build/package: passed.
- Workflow Run `34834303080`: success.
- P37 source commit: `6a605489a5f3837301c2ed127088146538c4c849`.

## Cleanup backlog after p37
1. Audit the remaining divergent root vs `testmod/` trees individually: `Bsphp/`, `菜单/`, `导入导出/`, `视图菜单/`.
2. Do not delete or mass-replace a divergent tree until exact file/reference/runtime proof exists.
3. Continue auditing the active target for obsolete helpers, while protecting Objective-C `+load`, constructors, swizzles, fishhook/rebind, `dlopen`, file/cloud/auth and runtime hook paths.
4. After canonical-source consolidation is complete, begin directory/naming cleanup and move large header-owned implementation boundaries into `.m` files where appropriate.

## Next task
Real-device test the `v1_p37` A_customer artifact. Because its runtime is byte-identical to p36, focus on the p36 first-launch UDID behavior: test once with Zonoe installed and once without Zonoe. A successful p37 device result promotes p37 and covers the p36 runtime behavior at the same time.
