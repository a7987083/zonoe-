# DEVICE TEST MATRIX

## Rule
Every development version must define its required real-device regression scope before it can be promoted to the device-verified baseline.

A CI-successful version is not a device-verified baseline until the required checklist is explicitly reported as passed. Destructive actions should be verified only up to the confirmation/UI boundary unless an explicit destructive test is intended.

## Common device smoke test
- App launches normally; floating entry appears normally.
- Menu opens and closes normally; outside-tap close works.
- Section fold/unfold and relayout work.
- Card/grid buttons and normal switches remain usable.
- Ad switch and speed slider remain usable.
- No obvious freeze/crash while opening, closing, folding, or operating controls.

## v1_p28 — ZONCore Build Integration
Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
Status: `passed`
Result: superseded by later baselines.

## v1_p29 — Rendering Boundary Cleanup
Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`
Status: `passed`

## v1_p30 — EventBridge Boundary Cleanup
Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`
Status: `passed`

## v1_p31 — Feature Registry Boundary Cleanup
Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`
Status: `passed`

## v1_p32 — Dispatcher Source Split
Source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`
CI Run: `34723015809` / `success`
Status: `passed`

## v1_p33 — Bootstrap / ModuleLoader Boundary
Source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`
CI Run: `34733013479` / `success`
Status: `superseded; covered by later p34 device pass`

## v1_p34 — Retired Feature Cleanup
Source commit: `cd9a0ab78158de11f1d51cda7461dbc6dd60f956`
CI Run: `34758839228` / `success`
Status: `passed`
Result: current device-verified baseline. User explicitly reported p34 real-device validation passed.

## v1_p35 — Canonical Source Cleanup
Source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`
CI Run: `34825140580` / `success`
Status: `pending device verification`

Changed boundary:
- Removed the obsolete `runtime.placeholder-203` / `暂无` menu item.
- Removed the corresponding renderer branch and Dispatcher placeholder behavior (`人物血量`).
- Removed root-only legacy copies of stacks already retired from canonical `testmod/` in p34.
- Preserved all nine active product features.

Required device validation:
- Common device smoke test.
- Confirm the runtime section shows only the retained IAP/no-ads control and ad-speed control/slider; `暂无` / tag 203 is absent.
- Remote download opens/executes the same flow as p34.
- VIP cloud save follows the same p34 flow; tmp-directory behavior remains normal.
- Local files opens the same sandbox browser/navigation UI.
- Backup and restore retain the same flows.
- Clear game data still presents the same destructive confirmation; cancel unless intentionally testing deletion.
- Clear authorization records still presents the same confirmation; cancel unless intentionally testing deletion.
- IAP/no-ads persists/restores and still reaches `ImgTool.NeiGou`.
- Ad-speed enable persists/restores and still reaches `ImgTool.ADSpeed`.
- Speed slider still updates the label, persists `AADDssppeedd`, restores, and reaches `ImgTool.ADBiansu`.
- Repeated menu open/close, fold/unfold, actions, toggles and slider changes do not crash or freeze.
- No unexpected menu ordering/style/section regressions other than the intentional removal of the `暂无` row.

Promotion rule:
- Promote `v1_p35` only after A_customer real-device regression is explicitly reported passed.
- Until then, `v1_p34` / `cd9a0ab78158de11f1d51cda7461dbc6dd60f956` remains the device-verified baseline.
