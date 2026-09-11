# zonoemenu HANDOFF

## Repository
- Repository: `a7987083/zonoe-`
- Stable branch: `main`
- Production branch: `dev/zonoemenu-production-v1`
- Current work branch: `work/zonoemenu-v1-p27-cleanup`
- Current version: `v1_p27`
- p25 structural baseline: `ec8176f60e4ebf13df22a8e7b354990095b68f80`
- p26 source commit / current device-verified baseline: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`
- p26 documentation closure commit: `11af85a8d276d6e4a824d8bcd5a1f9ebda65cac4`
- p27 source commit: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`
- Stable baseline commit: `68329ee5844f3899d369a778073e5586d8bc4e1f`
- User source-completion commit on main: `89507e1cd2f7c27184931e875adca02b043cfb36`

## Device-verified baseline — v1_p26
The user completed p26 device/runtime regression and reported no issues. p26 is now the current device-verified structural baseline.

Verified behavior includes the p26 regression scope:
- App launch without crash.
- Floating icon behavior remains correct.
- Menu opens/closes normally, including outside-tap close.
- Sections render/fold/relayout correctly.
- Layout/rotation behavior shows no reported regression.
- Existing card/grid actions, switches, ad switch and slider dispatch correctly.
- Authorization, UDID, VIP cloud save, clear-game-data and existing business behavior show no reported regression.

The previously suspected keyboard/presentation issue was a test/user-side mistake, not a project defect. It is closed and must not be used as a reason to modify presentation or keyboard logic.

## Current phase — v1_p27 Post-Refactor Cleanup
p27 is a minimal-risk cleanup after the p19-p26 structural split. It does not change menu behavior or business semantics.

Completed in p27 source commit `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`:
- Bumped `VERSION` from `v1_p26` to `v1_p27`.
- Converted `testmod/ZONCore/ZONMenuCoordinator.h` into a public interface-only header.
- Moved private dependencies, private properties and the existing coordinator method bodies into new `testmod/ZONCore/ZONMenuCoordinator.m` without intended behavioral changes.
- Kept `PopupMenuVC` lifecycle forwarding and legacy selector passthrough intact.
- Because the legacy Xcode project does not enumerate `ZONCore` source files, `PopupMenuVC.m` imports `ZONMenuCoordinator.m` exactly once as a bounded compilation bridge. This avoids broad `project.pbxproj` churn in p27 while removing the public-header duplicate-implementation risk.

p27 source diff against the p26 work-branch head is limited to:
1. `VERSION`
2. `testmod/ZONCore/ZONMenuCoordinator.h`
3. `testmod/ZONCore/ZONMenuCoordinator.m`
4. `testmod/菜单/PopupMenuVC.m`

## Protected scope for p27
Do not change as part of this cleanup:
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
- keyboard/presentation logic

## v1_p27 isolated CI verification
To keep the work branch workflow unchanged, CI validation runs from isolated branch `test/zonoemenu-v1-p27-build`.

- Workflow: `iOS Dylib Build`
- Run number: `97`
- Run ID: `34656320290`
- Test-only validation commit: `b5b8d8c20da0fd1cb358956036ff4e532216339e`
- Toolchain: Xcode 16.4 / iPhoneOS SDK 18.5
- Deployment target: iOS 12.0
- Architectures: arm64 + arm64e
- `A_customer`: success; artifact `testmod-v1_p27-A_customer`, ID `10286251100`, artifact ZIP SHA256 `2af95debe4ee769a03642bd5d7d31330dacbb8bfb1b8264e7ff3164663b08a05`
- `B_debug`: success; artifact `testmod-v1_p27-B_debug`, ID `10286565630`, artifact ZIP SHA256 `f50b96bc3fb6e0b7e5a358a544888409c135c99bea488df95ae36b21ff82b683`
- Both jobs passed compile, link, versioned dylib packaging, Mach-O verification and artifact upload.

The SHA256 values above are GitHub Actions artifact ZIP digests, not per-dylib hashes.

## Runtime verification state
- `v1_p26`: device/runtime verified and current stable structural baseline.
- `v1_p27`: CI/static verified; device/runtime regression is still pending.
- CI success must not be treated as device verification.

## Current architecture
```text
Floating Entry
  -> PopupMenuVC compatibility shell
     -> ZONMenuCoordinator
        -> ZONMenuPanelController
        -> ZONMenuChromeRenderer
        -> ZONSectionRenderer
           -> ZONFeatureRegistry
        -> ZONMenuEventBridge
           -> existing dispatcher/business handlers
```

## Next task
Device-regression-test the `v1_p27` A_customer build against the p26 device-verified baseline. Focus on proving behavior is unchanged; do not add more cleanup in the same test cycle.

Required checks:
1. Launch/floating icon/tap/drag.
2. Menu open/close/outside-tap close.
3. Section render/fold/relayout and layout refresh.
4. Card/grid/switch/ad switch/slider dispatch.
5. Authorization, UDID, VIP cloud save and clear-game-data show no regression.

If p27 passes, promote source commit `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311` as the next device-verified baseline. If it fails, compare directly with p26 source commit `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80` and fix only the proven regression.
