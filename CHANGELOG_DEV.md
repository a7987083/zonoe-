# CHANGELOG_DEV

## 2026-09-12 — v1_p26 Menu Coordinator structural closure
- Baseline: `v1_p25` commit `ec8176f60e4ebf13df22a8e7b354990095b68f80`.
- Added `ZONMenuCoordinator` as the owner of menu panel/scroll lifecycle, section build/relayout, visibility and event forwarding.
- Reduced `PopupMenuVC` to a compatibility shell with UIKit lifecycle forwarding and legacy selector passthrough.
- Reused existing `ZONMenuPanelController`, `ZONSectionRenderer`, `ZONMenuChromeRenderer`, `ZONMenuEventBridge`, Feature Registry and dispatcher/business handlers without intended behavior change.
- Did not change authorization, UDID, VIP cloud save, clear-game-data, `WX_NongShiFu123.mm`, `main.m`, AppDelegate/SceneDelegate, Feature Registry data, business handlers, UI style/dimensions/colors/text/spacing, or keyboard behavior.
- Version bumped to `v1_p26`; source commit `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`.
- Isolated CI run `#96` / `34653448146` passed both `A_customer` and `B_debug`, including compile/link/package and arm64+arm64e Mach-O verification.
- p26 device/runtime regression remains pending; last device-verified baseline remains `7120f92f978b99931444903b6f95b2e56a1bd594`.

## 2026-09-09 — production-v1 bootstrap
- Created production development branch from stable baseline `68329ee5844f3899d369a778073e5586d8bc4e1f`.
- Locked runtime priority: IPA injection first, jailbreak injection second.
- Locked deployment target: iOS 12.0+; architectures arm64 + arm64e.
- Locked BS/PHP strategy: compatibility first, backend replacement later.
- Locked product role: universal core menu with future external dylib modules loaded via dlopen().
- Existing feature behavior is a regression-protected baseline.
- No runtime source behavior changed yet.
