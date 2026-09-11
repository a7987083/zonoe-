# CHANGELOG_DEV

## 2026-09-12 — v1_p27 post-refactor cleanup
- Baseline: device-verified `v1_p26` source commit `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`; p26 device/runtime regression passed with no reported issues.
- Bumped version to `v1_p27`.
- Changed `ZONMenuCoordinator.h` to an interface-only public header.
- Added `ZONMenuCoordinator.m` and moved the existing private imports, private properties and coordinator implementation there without intended behavior change.
- Kept `PopupMenuVC` lifecycle and legacy selector passthrough unchanged; added a single compatibility import of `ZONMenuCoordinator.m` because the legacy Xcode target does not yet enumerate ZONCore source files.
- Source commit: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`.
- Isolated CI run `#97` / `34656320290` passed both `A_customer` and `B_debug`, including compile/link/package and Mach-O arm64+arm64e verification.
- No authorization, UDID, VIP cloud save, clear-game-data, `WX_NongShiFu123.mm`, `main.m`, Feature Registry data, dispatcher business handlers, UI appearance or keyboard/presentation logic was changed.
- `v1_p27` device/runtime regression remains pending; `v1_p26` remains the current device-verified baseline until p27 passes on device.
- Previously suspected keyboard/presentation issue is closed as a test/user-side mistake; no code fix is required.

## 2026-09-12 — v1_p26 Menu Coordinator structural closure
- Baseline: `v1_p25` commit `ec8176f60e4ebf13df22a8e7b354990095b68f80`.
- Added `ZONMenuCoordinator` as the owner of menu panel/scroll lifecycle, section build/relayout, visibility and event forwarding.
- Reduced `PopupMenuVC` to a compatibility shell with UIKit lifecycle forwarding and legacy selector passthrough.
- Reused existing `ZONMenuPanelController`, `ZONSectionRenderer`, `ZONMenuChromeRenderer`, `ZONMenuEventBridge`, Feature Registry and dispatcher/business handlers without intended behavior change.
- Did not change authorization, UDID, VIP cloud save, clear-game-data, `WX_NongShiFu123.mm`, `main.m`, AppDelegate/SceneDelegate, Feature Registry data, business handlers, UI style/dimensions/colors/text/spacing, or keyboard behavior.
- Version bumped to `v1_p26`; source commit `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`.
- Isolated CI run `#96` / `34653448146` passed both `A_customer` and `B_debug`, including compile/link/package and arm64+arm64e Mach-O verification.
- Device/runtime regression subsequently passed; p26 was promoted to the device-verified structural baseline.

## 2026-09-09 — production-v1 bootstrap
- Created production development branch from stable baseline `68329ee5844f3899d369a778073e5586d8bc4e1f`.
- Locked runtime priority: IPA injection first, jailbreak injection second.
- Locked deployment target: iOS 12.0+; architectures arm64 + arm64e.
- Locked BS/PHP strategy: compatibility first, backend replacement later.
- Locked product role: universal core menu with future external dylib modules loaded via dlopen().
- Existing feature behavior is a regression-protected baseline.
