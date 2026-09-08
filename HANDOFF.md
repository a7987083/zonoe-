# zonoemenu HANDOFF

## Repository
- Repository: a7987083/zonoe-
- Stable branch: main
- Production branch: dev/zonoemenu-production-v1
- Stable baseline commit: 68329ee5844f3899d369a778073e5586d8bc4e1f
- User source-completion commit on main: 89507e1cd2f7c27184931e875adca02b043cfb36
- Last verified code commit: 095d8d0a3cb960686a30f410bfc6299a914f9ed4

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

## Build verification
- Workflow: iOS Dylib Build
- Run: 34270333942
- Result: success
- Verified code commit: 095d8d0a3cb960686a30f410bfc6299a914f9ed4
- Artifact: zonoemenu-testmod-dylib
- Artifact ID: 10073571157
- Product: testmod.dylib
- SHA256: eb3bedb670081760e45a4b8dd1da0222d579e52ebbb96c89b1e616a73e2d0fb6
- Mach-O: universal dynamic library
- Architectures: arm64 + arm64e
- Deployment target used by CI: iOS 12.0
- Xcode: 16.4
- iPhoneOS SDK: 18.5

## Important build root causes already resolved
1. Original Git upload did not match Xcode's `testmod/` physical group path.
2. Original upload omitted WX_NongShiFu123.h and dependency source trees; user later supplied the authoritative originals.
3. Theos `vendor/include/MobileCoreServices/MobileCoreServices.h` shadows Apple's SDK umbrella and lacks legacy UTI declarations required by old AFNetworking.
4. MonkeyDev `md --xcbp` attempts Release package/device installation when `VALIDATE_PRODUCT=YES`; CI now uses `VALIDATE_PRODUCT=NO` and disables install/profile/package flags.

## Current important files
- testmod/Bsphp/main.m: current dylib +load bootstrap.
- testmod/Bsphp/Config.h: legacy BS/PHP client configuration.
- testmod/Bsphp/WX_NongShiFu123.mm: legacy auth/business logic.
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
- Runtime/device verification: not yet run.
- Regression verification: not yet run.

## Next Task
Runtime smoke-test the verified dylib through the IPA-injection path first. After runtime baseline is confirmed, continue production bootstrap, feature registry and BS/PHP service-adapter modularization without changing existing feature behavior.
