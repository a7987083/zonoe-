# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p28-build-integration`
- Current version: `v1_p28`
- Stable baseline commit: `68329ee5844f3899d369a778073e5586d8bc4e1f`
- User source-completion commit on main: `89507e1cd2f7c27184931e875adca02b043cfb36`
- p26 source commit: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`
- p27 source commit / current device-verified baseline: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`
- p28 source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`

## Device-verified baseline — v1_p27
The user completed p27 device/runtime regression and reported no issues. p27 is now the current device-verified structural/runtime baseline.

Verified scope includes launch, floating entry, menu open/close, section rendering/relayout, action/switch dispatch and protected business paths. The previously suspected keyboard/presentation issue remains closed as a test/user-side mistake; no code fix is required.

## Current phase — v1_p28 ZONCore Build Integration
p28 closes the remaining temporary build bridge introduced in p27. Runtime behavior and coordinator implementation are intentionally unchanged.

Source commit `350a46deb089a05fc599e641bd1eeb419c36c0d5` changes exactly three files:
1. `VERSION`: `v1_p27` -> `v1_p28`.
2. `testmod.xcodeproj/project.pbxproj`: adds one `PBXFileReference`, one `PBXBuildFile`, and one `PBXSourcesBuildPhase` entry for `testmod/ZONCore/ZONMenuCoordinator.m`.
3. `testmod/菜单/PopupMenuVC.m`: removes the temporary direct `#import "../ZONCore/ZONMenuCoordinator.m"` bridge and its explanatory comments.

No method body in `ZONMenuCoordinator.m` changed in p28.

## Protected scope for p28
Do not change:
- authorization / BS-PHP behavior
- UDID
- VIP cloud save
- clear-game-data
- `WX_NongShiFu123.mm`
- `main.m`
- AppDelegate / SceneDelegate
- Feature Registry data
- Dispatcher business handlers
- UI style/dimensions/colors/text/spacing
- keyboard/presentation logic

## v1_p28 isolated CI verification
Validation was run from isolated branch `test/zonoemenu-v1-p28-build`; the temporary integration workflow is not part of the p28 work branch.

- Workflow: `p28 Integrate and Build`
- Run ID: `34657710034`
- Result: success
- Test branch trigger commit: `1fa858be49313e9c37dfb8eb1bd2f32a2325de50`
- Integrated source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- Toolchain: Xcode 16.4 / iPhoneOS SDK 18.5
- Deployment target: iOS 12.0
- Architectures: arm64 + arm64e

### A_customer
- Result: success
- Artifact: `testmod-v1_p28-A_customer`
- Artifact ID: `10286438074`
- Artifact ZIP SHA256: `86b899de9b04772f02a9a879bdbbf4138a6e3711f890bb0fca503e31877defaf`
- Dylib SHA256: `2a0bf1f10c490dd4d8a239943365b0d3fe71d35ee2109e968297307a599dfccc`

### B_debug
- Result: success
- Artifact: `testmod-v1_p28-B_debug`
- Artifact ID: `10285962447`
- Artifact ZIP SHA256: `1a664beb7261164d7dc48a810c9f594d94f0ed80ede1c67a8f04b731fa645149`
- Dylib SHA256: `720a457df07ea8f5d4ddc6f7460357a193a98907a23d05d1fe50889f74b90437`

Both variants passed source-commit verification, compilation, linking, versioned dylib packaging, `file`, `lipo -info`, `otool -L`, SHA256 generation and artifact upload. No duplicate-symbol regression occurred.

## Runtime verification state
- `v1_p27`: device/runtime verified; current baseline.
- `v1_p28`: source/static/CI verified; device/runtime regression pending.
- CI success alone does not promote the device baseline.

## Current build relationship
```text
PopupMenuVC.m
  -> imports ZONMenuCoordinator.h only

Xcode target Sources
  -> PopupMenuVC.m
  -> ZONMenuCoordinator.m
```

The p27 direct implementation import is removed. `ZONMenuCoordinator.m` is now an independent Objective-C translation unit owned by the target.

## Next task
Device-regression-test `v1_p28` A_customer against device-verified `v1_p27`.

Required checks:
1. Launch / floating icon / tap / drag.
2. Menu open/close and outside-tap close.
3. Section render/fold/relayout/layout refresh.
4. Card/grid/switch/ad switch/slider dispatch.
5. Authorization, UDID, cloud save and clear-game-data show no regression.

If all checks pass, promote source commit `350a46deb089a05fc599e641bd1eeb419c36c0d5` as the next device-verified baseline.
