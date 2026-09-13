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
Result: superseded by p31 baseline.

## v1_p29 — Rendering Boundary Cleanup
Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`
Status: `passed`
Result: covered by cumulative p31 hardware regression.

## v1_p30 — EventBridge Boundary Cleanup
Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`
Status: `passed`
Result: covered by cumulative p31 hardware regression.

## v1_p31 — Feature Registry Boundary Cleanup
Source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`
Status: `passed`
Result: cumulative p29+p30+p31 hardware regression passed; superseded by p32.

## v1_p32 — Dispatcher Source Split
Source commit: `84f8b3898bee9d95ed4034d12842879cc56280d3`
CI Run: `34723015809` / `success`
Status: `passed`
Result: user explicitly reported the full p32 real-device checklist passed; current device-verified baseline.

Changed boundary:
- `ZONFeatureDispatcher.h` is declarations-only for Dispatcher functions.
- `ZONFeatureDispatcher.m` owns the same seven function bodies.
- The `.m` is registered as a normal Xcode target source.
- No intended route, persistence, destructive-action, UI or runtime semantic changes.

Validated on device:
- Common device smoke test.
- Remote download opens the same flow as p31.
- VIP cloud save opens/checks the same flow; tmp-directory behavior remains normal.
- Local files presents the same browser/navigation UI.
- Backup and restore open the same target flows.
- Clear game data reaches the same destructive confirmation dialog; destructive deletion was not required for promotion.
- Clear authorization reaches the same destructive confirmation dialog; destructive deletion was not required for promotion.
- IAP/no-ads switch persists/restores and reaches `ImgTool.NeiGou` behavior.
- Ad-speed enable switch persists/restores and reaches `ImgTool.ADSpeed` behavior.
- Ad-speed slider updates its label, persists/restores and reaches `ImgTool.ADBiansu` behavior.
- Repeated action/toggle/slider use, menu open/close, and section fold/unfold do not crash or freeze.
- Section/feature order, visual style, dimensions, text and animations remain unchanged from p31.

Promotion rule result:
- `v1_p32` is promoted because A_customer CI succeeded and the user explicitly reported the required device checklist passed.
