# DEVICE TEST MATRIX

## Rule
Every development version must define its required real-device regression scope before it can be promoted to the device-verified baseline.

For every future version, record:
- version and source commit
- what changed in that version
- core smoke tests that must still pass
- phase-specific tests for the changed code path
- protected-path smoke tests that must not regress
- destructive actions that should be verified only up to the confirmation/UI boundary unless an explicit destructive test is intended
- final status: `pending` / `passed` / `failed`

A CI-successful version is not a device-verified baseline until the required checklist is explicitly reported as passed.

## Common device smoke test
Run these for every version unless the phase is completely unrelated to the menu runtime:
- App launches normally; floating entry appears normally.
- Menu opens and closes normally.
- Outside-tap close works.
- Section fold/unfold and relayout work.
- Card and grid buttons remain clickable.
- Normal switches remain clickable and reflect the selected state.
- Ad switch and speed slider remain usable.
- No obvious freeze/crash while opening, closing, folding, or operating controls.

## v1_p28 — ZONCore Build Integration
Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
Status: `passed`

Required device validation:
- Common device smoke test.
- Coordinator lifecycle still works after removing the direct `.m` import bridge.
- Menu open/close and outside-tap dismissal.
- Section rendering/fold/relayout/layout refresh.
- Card/grid/switch/ad switch/slider event dispatch.
- Authorization, UDID, VIP cloud save and clear-game-data paths show no regression.

Result: user reported no issues; p28 was the device-verified fallback baseline until p31 promotion.

## v1_p29 — Rendering Boundary Cleanup
Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`
Status: `passed`

Changed boundary:
- `ZONMenuPanelController`
- `ZONMenuChromeRenderer`
- `ZONFeatureRenderer`
- `ZONSectionRenderer`

Required device validation:
- Common device smoke test.
- Panel size/position/open-close animation remains unchanged.
- Header renders normally.
- Every visible section renders with the same order/content as the p28 baseline.
- Fold/unfold repeatedly and confirm section heights/content offsets relayout correctly.
- Card and grid controls still dispatch the intended action.
- Switch rows and ad-speed controls still render and respond normally.
- Rotate/layout-refresh path, if applicable on the test host, does not break panel/section geometry.
- No visual regression in existing style, spacing, colors, text or control placement.

Result: covered and passed by the cumulative v1_p31 hardware regression reported by the user.

## v1_p30 — EventBridge Boundary Cleanup
Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`
Status: `passed`

Changed boundary:
- `ZONMenuEventBridge.h` declarations only
- new independent `ZONMenuEventBridge.m`
- Dispatcher implementation remains unchanged

Required EventBridge-specific validation:
- Card action path reaches the same target as before.
- Grid action path reaches the same target as before.
- Normal switch toggle reaches Dispatcher and applies the expected state.
- Ad switch enables/disables the speed slider correctly.
- Ad-speed slider label follows the selected value.
- Ad-speed value persists to `NSUserDefaults` and is restored after closing/reopening the menu.
- `ZONMenuSyncSettingsToRuntime` applies saved no-ads/ad-speed state on menu appearance.
- Runtime IAP/no-ads switch state still reaches `ImgTool.NeiGou`.
- Runtime ad-speed enable state still reaches `ImgTool.ADSpeed`.
- Runtime ad-speed numeric value still reaches `ImgTool.ADBiansu`.
- Representative protected action routes still open the same target UI/flow: remote download, cloud save, local files, backup/restore.
- Clear-game-data route reaches the same confirmation dialog; do not confirm the destructive action unless intentionally testing deletion.
- Clear-authorization route reaches the same confirmation dialog; do not confirm deletion unless intentionally testing it.
- No crash/freeze while repeatedly switching controls, moving the slider, opening actions, closing and reopening the menu.

Result: covered and passed by the cumulative v1_p31 hardware regression reported by the user.

## v1_p31 — Feature Registry Boundary Cleanup
Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`
Status: `passed`

Changed boundary:
- `ZONFeatureRegistry.h` is declaration-only for registry functions.
- Added independent `ZONFeatureRegistry.m` and registered it in the Xcode target.
- Registry key constants use `FOUNDATION_EXPORT` declarations with one definition in `.m`.
- The 10 feature records, 3 section records, tags, identifiers, titles, risk values, migrated flags, state keys and renderer values are unchanged.

Required Registry-specific validation:
- Common device smoke test.
- Confirm the three sections appear in the same order: `基础功能` -> `数据功能` -> `其他功能`.
- Confirm section titles/details and fold behavior remain unchanged.
- `基础功能` visible feature order remains: `远程下载` -> `VIP云存档` -> `浏览本地文件`.
- `数据功能` visible feature order remains: `备份存档` -> `恢复存档` -> `清除游戏数据` -> `清除授权记录`.
- `其他功能` visible feature order remains: `内购破解+ iGameGod去广告` -> `广告加速` -> `暂无`.
- Card/grid/toggle/placeholder/ad-speed controls still render with the same control type and placement.
- Remote download, cloud save, local files, backup and restore still route to the same target UI/flow.
- Clear-game-data reaches the same confirmation dialog; do not confirm deletion unless intentionally testing the destructive operation.
- Clear-authorization reaches the same confirmation dialog; do not confirm deletion unless intentionally testing it.
- IAP/no-ads switch, ad-speed switch and slider still operate, persist and synchronize to runtime as required by p30.
- Repeatedly open/close the menu and fold/unfold every section; no missing feature, duplicate feature, stale section, crash or freeze.
- p29 panel/header/layout/animation behavior remains unchanged.

Result: user reported the full cumulative p29 + p30 + p31 real-device regression passed with no issues. `v1_p31` / `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f` is promoted to the device-verified baseline; p29 and p30 are implicitly closed by the same regression.

## Template for the next version
Add a section before handing out a new A_customer dylib:

```text
## v1_pXX — <phase name>
Source commit: <sha>
Status: pending

Changed boundary:
- ...

Required device validation:
- Common device smoke test.
- <tests that directly exercise every changed path>
- <protected-path smoke tests relevant to the change>

Promotion rule:
- Only promote after the user explicitly reports this checklist passed.
```
