# CHANGELOG_DEV

## 2026-09-12 — v1_p28 ZONCore build integration
- Baseline: device-verified `v1_p27` source commit `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`.
- Bumped version to `v1_p28`.
- Registered `testmod/ZONCore/ZONMenuCoordinator.m` as a normal Xcode target source using one PBX file reference, one build-file record and one Sources build-phase entry.
- Removed the temporary direct import of `ZONMenuCoordinator.m` from `PopupMenuVC.m`.
- Did not modify `ZONMenuCoordinator.m` method bodies, Feature Registry, dispatcher/business handlers, UI appearance, authorization, UDID, cloud save, clear-game-data, `WX_NongShiFu123.mm`, `main.m`, or keyboard/presentation logic.
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- Source diff is exactly three files: `VERSION`, `testmod.xcodeproj/project.pbxproj`, and `testmod/菜单/PopupMenuVC.m`.
- Isolated CI run `34657710034` passed integration checks plus both A_customer and B_debug compile/link/package/Mach-O verification.
- A dylib SHA256: `2a0bf1f10c490dd4d8a239943365b0d3fe71d35ee2109e968297307a599dfccc`.
- B dylib SHA256: `720a457df07ea8f5d4ddc6f7460357a193a98907a23d05d1fe50889f74b90437`.
- User completed p28 device/runtime regression with no issues.
- p28 is promoted to the current device-verified baseline; source/static/CI/device verification is fully closed.

## 2026-09-12 — v1_p27 post-refactor cleanup
- Made `ZONMenuCoordinator.h` interface-only and moved implementation/private dependencies to `ZONMenuCoordinator.m`.
- Preserved the existing runtime behavior and temporary single compilation bridge through `PopupMenuVC.m`.
- Source commit: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`.
- A/B CI passed; user subsequently completed device regression with no issues.
- p27 was promoted to the device-verified baseline and is now the historical predecessor to p28.

## 2026-09-12 — v1_p26 Menu Coordinator structural closure
- Added `ZONMenuCoordinator` ownership of menu lifecycle/orchestration and reduced `PopupMenuVC` to compatibility forwarding.
- Source commit: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`.
- A/B CI and subsequent device regression passed.

## 2026-09-09 — production-v1 bootstrap
- Established production-v1 migration constraints: IPA injection first, jailbreak second, iOS 12+, arm64+arm64e, compatibility-before-rewrite, external modules via versioned ABI.
