# zonoemenu HANDOFF

## Repository
- Repository: a7987083/zonoe-
- Stable branch: main
- Production branch: dev/zonoemenu-production-v1
- Stable baseline commit: 68329ee5844f3899d369a778073e5586d8bc4e1f
- User source-completion commit on main: 89507e1cd2f7c27184931e875adca02b043cfb36
- Last device-verified code commit: 7120f92f978b99931444903b6f95b2e56a1bd594

## Product goal
Build zonoemenu as a production-grade universal iOS injected dylib menu.

## Hard constraints
- Primary runtime: non-jailbroken IPA injection.
- Secondary runtime: jailbreak injection (MobileSubstrate/ElleKit compatible path).
- Minimum iOS: 12.0.
- Architectures: arm64 + arm64e.
- Existing features must remain functional during migration.
- Existing BS/PHP authorization is compatibility baseline; replace later behind a service abstraction.
- zonoemenu is the universal host/core menu, not a game-specific implementation.
- Game/project-specific functionality must be loadable later via dlopen() as external dylib modules.
- Prefer minimal-risk migration over rewrite.

## Existing functional baseline
- Floating menu entry.
- PopupMenuVC menu UI.
- Remote download.
- VIP cloud save.
- Local file browser.
- Import/export.
- Backup/restore.
- Memory tooling.
- Hook tooling.
- Speed controls.
- Authorization/config persistence.

## Production work completed
- Added versioned C module ABI and bundle-scoped external dylib loader.
- Added module ABI smoke test and example module.
- Recovered the physical `testmod/` source layout expected by `project.pbxproj` without deleting root safety copies.
- Integrated the user's original AFNetworking, MBProgressHUD, SCLAlertView and WX_NongShiFu123.h into `testmod/Bsphp/`.
- Changed vendor bootstrap to verification-only; checked-in user sources are authoritative.
- Fixed Xcode 16.4 compilation caused by Theos shadowing Apple's MobileCoreServices umbrella by explicitly importing the public UTI subheaders.
- CI disables MonkeyDev Release device deployment while preserving the Release dylib build.
- Restored the floating-icon tap chain: JHDragView distinguishes tap vs drag, `vip菜单显示` presents PopupMenuVC, and the legacy `vipaa` alias is retained.

## Build verification
- Workflow: iOS Dylib Build
- Run: 34271970872
- Result: success
- Verified code commit: 7120f92f978b99931444903b6f95b2e56a1bd594
- Artifact: zonoemenu-testmod-dylib
- Artifact ID: 10074199433
- Product: testmod.dylib
- SHA256: c19c792e25f9cf65792992098f15b43621c7e3022a33781daddf5cc102970c71
- Mach-O: universal dynamic library
- Architectures: arm64 + arm64e
- Deployment target used by CI: iOS 12.0
- Xcode: 16.4
- iPhoneOS SDK: 18.5

## Device runtime verification
User verified the IPA-injection path on device for commit `7120f92f978b99931444903b6f95b2e56a1bd594`:
- App launches without crash.
- Floating icon is visible.
- Tapping the floating icon opens PopupMenuVC.
- Dragging the floating icon works and does not falsely open the menu.

This commit is the current verified floating-menu runtime baseline.

## Important build/runtime root causes already resolved
1. Original Git upload did not match Xcode's `testmod/` physical group path.
2. Original upload omitted WX_NongShiFu123.h and dependency source trees; user later supplied the authoritative originals.
3. Theos `vendor/include/MobileCoreServices/MobileCoreServices.h` shadows Apple's SDK umbrella and lacks legacy UTI declarations required by old AFNetworking.
4. MonkeyDev `md --xcbp` attempts Release package/device installation when `VALIDATE_PRODUCT=YES`; CI now uses `VALIDATE_PRODUCT=NO` and disables install/profile/package flags.
5. The floating icon had no single-tap path to the menu; `NSObject+UI.h` declared `vip菜单显示` while the implementation only had `vipaa`.

## Current important files
- testmod/Bsphp/main.m: current dylib +load bootstrap.
- testmod/Bsphp/Config.h: legacy BS/PHP client configuration.
- testmod/Bsphp/WX_NongShiFu123.mm: legacy auth/business logic.
- testmod/菜单/JHDragView.m: floating icon input/drag handling.
- testmod/视图菜单/NSObject+UI.m: floating icon creation and menu presentation.
- testmod/菜单/PopupMenuVC.m: current main menu UI.
- testmod/工具箱/: hook/memory/runtime tooling.
- testmod/ZONCore/ZONModuleABI.h: external module ABI.
- testmod/ZONCore/ZONModuleLoader.h: bundle-local module loader.
- testmod/testmod-Prefix.pch: common build compatibility imports.
- testmod.xcodeproj/project.pbxproj: Xcode dylib target.

## Verification state
- Source/dependency recovery: verified by CI.
- Module ABI smoke: passed.
- Full production dylib build: passed.
- Binary arm64 + arm64e verification: passed.
- IPA injection launch smoke: passed on device.
- Floating icon/menu presentation smoke: passed on device.
- Full legacy feature regression: partial; feature-by-feature verification remains as modularization proceeds.

## Next Task
Continue production bootstrap, feature registry and legacy BS/PHP service-adapter modularization without changing the verified floating-menu runtime behavior. Keep commit `7120f92f978b99931444903b6f95b2e56a1bd594` as the device-verified runtime baseline for regression comparison.
