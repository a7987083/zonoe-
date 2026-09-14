# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p38`.
- Runtime/source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`.
- Audit Run `34840224717`: success.
- CI Run `34840451436`: success.
- Real-device regression: user explicitly reported p38 passed.
- Because p38 `testmod/`, Xcode project and A_customer dylib are byte-identical to p36/p37 runtime, this device pass also covers the p36-p38 runtime lineage, including the Zonoe-to-web UDID fallback.

## P38 completed — Canonical Product Source Finalization
- All **76** PBX product Sources resolve under `testmod/`; root product source count is **0**.
- Removed the remaining root `Bsphp/`, `菜单/`, `导入导出/`, and `视图菜单/` mirrors after proving they contained no root-only files.
- Canonical product source surface is now **`testmod/` only**.
- All nine active product features remain verified.
- P38 A_customer SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`.

## Current development phase — v1_p39 active-target audit
Status: `audit_complete_cleanup_pending`.

### Audit completed
- P39 audit branch: `work/zonoemenu-v1-p39-active-target-audit`.
- Audit Run `34845492258`: success.
- Artifact `p39-active-target-audit` / ID `10347723184` / digest `sha256:2c75e6e4d7ec3fb0277a7a5f03b32f14ec2ffb30e1c3cc1a600f96974d45a5bd`.
- PBX Sources: **76**; resolved active sources: **76**.
- Classification: 25 protected architecture/product units, 2 runtime/dynamic-entry units, 16 referenced non-vendor units, 32 vendor/dependency units, 1 initial low-risk candidate.
- Detailed evidence is recorded in `P39_AUDIT.md`.

### P39-A — approved cleanup scope for build validation
Only one source pair is currently a strong deletion candidate:
- `testmod/category/NSString+Tools.m`
- `testmod/category/NSString+Tools.h`

Evidence:
- No auto-start/hook behavior.
- No product import of `NSString+Tools.h`.
- No use of the category-specific sizing selectors outside the category itself.
- The apparent `[attr fileSize]` hit in `daochucd.m` is on an `NSDictionary *` file-attributes object, not an `NSString` receiver.
- Removal must also prune Xcode PBX file/build references.

### Vendor/dependency decisions
Keep for now because active dependency evidence exists:
- AFNetworking: live through `NetWorkingApiClient : AFHTTPSessionManager` and AF serializer/security APIs.
- MBProgressHUD: live authorization/cloud-save importers.
- SCLAlertView: live authorization UI importer.
- SSZipArchive + bundled minizip: live backup/restore/import/cloud-save users.
- SVProgressHUD: live authorization/data/cloud/dispatcher users.

P39-B deeper audit only; no deletion yet:
- JDStatusBarNotification: audit exact public API and call sites as a complete 8-source dependency group.

### P39 cleanup rules
1. Do not delete files merely because ordinary textual call sites are zero.
2. Protect Objective-C `+load`, constructors, swizzles, fishhook/rebind, `dlopen`, runtime hook, authorization, UDID, file, cloud-save, backup/restore and menu-entry paths until explicit proof permits deletion.
3. Audit third-party stacks as dependency units rather than deleting isolated source files.
4. Preserve all nine verified menu features.
5. Every accepted deletion batch must pass contracts, Registry smoke, Module ABI, A_customer and B_debug full builds before device testing.

## Later backlog
- After P39 active-target slimming stabilizes, start directory/naming cleanup.
- Continue moving implementation-heavy headers into `.m` files only where it reduces coupling without adding unnecessary abstraction.
- Keep the rule: delete when possible, merge when appropriate, add interfaces only when a real extension boundary exists.

## Next task
Execute **P39-A** as a guarded cleanup: remove only `NSString+Tools.m/.h` plus PBX references, then run the full contract/build/binary-diff gate. Do not mix JDStatusBarNotification or other vendor changes into the same batch.
