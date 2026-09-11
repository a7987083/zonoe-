# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p26-coordinator`
- Current version: `v1_p26`
- p25 structural baseline: `ec8176f60e4ebf13df22a8e7b354990095b68f80`
- p26 source commit: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`
- Stable baseline commit: `68329ee5844f3899d369a778073e5586d8bc4e1f`
- User source-completion commit on main: `89507e1cd2f7c27184931e875adca02b043cfb36`
- Last device-verified code commit: `7120f92f978b99931444903b6f95b2e56a1bd594`

## Current phase — v1_p26 Menu Coordinator
p26 is a structure-only menu closure. `PopupMenuVC` is now a compatibility shell and delegates menu lifecycle/action selectors to `ZONMenuCoordinator`.

Completed in p26:
- Added `testmod/ZONCore/ZONMenuCoordinator.h`.
- Moved panel/scroll ownership, section build/relayout, show/hide, layout and event forwarding into the coordinator.
- Reduced `testmod/菜单/PopupMenuVC.m` to lifecycle forwarding plus legacy selector passthrough.
- Kept existing `ZONMenuPanelController`, `ZONSectionRenderer`, `ZONMenuChromeRenderer`, `ZONMenuEventBridge`, Feature Registry and dispatcher/business handlers intact.
- No intended UI style/size/color/text behavior change.

## Hard constraints for this phase
Do not change while validating p26:
- authorization / BS-PHP behavior
- UDID behavior
- VIP cloud save
- clear-game-data behavior
- `WX_NongShiFu123.mm`
- `main.m`
- AppDelegate / SceneDelegate
- Feature Registry data
- Dispatcher business handlers
- UI style, dimensions, colors, text or spacing
- unrelated keyboard logic

## Product goal
Build zonoemenu as a production-grade universal iOS injected dylib menu.

## Runtime/build constraints
- Primary runtime: non-jailbroken IPA injection.
- Secondary runtime: jailbreak injection.
- Minimum iOS: 12.0.
- Architectures: arm64 + arm64e.
- Existing features must remain functional during migration.
- Existing BS/PHP authorization is compatibility baseline.
- zonoemenu is the universal host/core menu, not a game-specific implementation.
- Prefer minimal-risk migration over rewrite.

## v1_p26 isolated CI verification
To avoid changing the work branch workflow, p26 was copied to isolated validation branch `test/zonoemenu-v1-p26-build`; only that test branch received an extra push trigger.

- Workflow: `iOS Dylib Build`
- Run number: `96`
- Run ID: `34653448146`
- Test branch CI commit: `a09b1fd35950c65386be3b4e70e689ae2c804d10`
- Toolchain: Xcode 16.4 / iPhoneOS SDK 18.5
- Deployment target: iOS 12.0
- Architectures verified by CI: arm64 + arm64e
- `A_customer`: success; artifact `testmod-v1_p26-A_customer`, ID `10198416330`, artifact ZIP SHA256 `0a071bbe62248e38a70763ea12ceacde29b3b5d0467ed6377c80b85c0fea8e00`
- `B_debug`: success; artifact `testmod-v1_p26-B_debug`, ID `10198366721`, artifact ZIP SHA256 `102ae95930ef5e1b6aca7789dd10a744ba13e128f0de3b69760807804442de79`
- Both matrix jobs passed compile, link, versioned packaging, Mach-O verification and artifact upload.
- The hashes above are GitHub artifact ZIP digests. Per-dylib SHA256 was printed by CI verification but could not be re-fetched from the Actions log/artifact endpoint in this handoff update, so it is intentionally not guessed.

## Device runtime verification
The latest device-verified runtime baseline remains commit `7120f92f978b99931444903b6f95b2e56a1bd594`:
- App launches without crash.
- Floating icon is visible.
- Tapping the floating icon opens PopupMenuVC.
- Dragging the floating icon works and does not falsely open the menu.

`v1_p26` has **not yet been device/runtime regression verified**. CI success must not be treated as device verification.

## Important files for p26
- `testmod/菜单/PopupMenuVC.m`: compatibility shell.
- `testmod/ZONCore/ZONMenuCoordinator.h`: menu lifecycle/orchestration owner.
- `testmod/ZONCore/ZONMenuPanelController.h`: panel creation/layout/show/hide.
- `testmod/ZONCore/ZONSectionRenderer.h`: registered section rendering/relayout.
- `testmod/ZONCore/ZONMenuChromeRenderer.h`: menu chrome/header rendering.
- `testmod/ZONCore/ZONMenuEventBridge.h`: action/toggle/runtime bridge.
- `testmod/ZONCore/ZONFeatureRegistry.h`: feature data source; unchanged by p26.

## Verification state
- p26 static source/call-chain review: passed.
- p26 A_customer CI compile/link/package: passed.
- p26 B_debug CI compile/link/package: passed.
- p26 Mach-O arm64 + arm64e verification: passed in CI.
- p26 device launch smoke: pending.
- p26 menu UI/runtime regression: pending.
- Last known-good device runtime baseline: `7120f92f978b99931444903b6f95b2e56a1bd594`.

## Next Task
Install/inject the `v1_p26` customer build on device and perform regression only; do not add new structure or keyboard fixes in the same variable set.

Required p26 device checks:
1. App launches without crash.
2. Floating icon appears.
3. Tap opens menu; drag does not false-open.
4. Menu panel open/close animation and outside-tap close work.
5. Sections render, fold/unfold and relayout correctly.
6. Rotation/layout refresh does not lose panel/scroll state or create duplicate UI.
7. Existing card/grid actions, switches, ad switch and slider still dispatch correctly.
8. Authorization, UDID, cloud save, clear-game-data and existing business behavior show no regression.

If all checks pass, promote `v1_p26` to the new device-verified structural baseline. Otherwise compare the failure directly against p25 commit `ec8176f60e4ebf13df22a8e7b354990095b68f80` and fix only the proven regression.
