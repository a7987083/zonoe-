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

## v1_p35 — Canonical Source Cleanup
Source commit: `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9`
CI Run: `34825140580` / `success`
Status: `passed`

## v1_p36 — UDID Web Fallback
Source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`
CI Run: `34829714958` / `success`
Status: `superseded; covered by byte-identical p38 device pass`

## v1_p37 — Canonical Mirror Cleanup
Source commit: `6a605489a5f3837301c2ed127088146538c4c849`
CI Run: `34834303080` / `success`
Status: `superseded; covered by byte-identical p38 device pass`

## v1_p38 — Canonical Product Source Finalization
Source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`
CI Run: `34840451436` / `success`
Status: `passed`

## v1_p39 — Active Target Slimming
Source commit: `613882da7068795533c530d45775f7ae5f79ed56`
CI verification fix commit: `5364d440442474f540d90b8d52f69fabb2b1deb7`
Fixed verification Run: `34891852090` / `success`
Status: `passed`

## v1_p41 — UDID Bridge Boundary
Source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`
CI Run: `34959813770` / `success`
Status: `passed`
Result: user explicitly reported real-device validation normal before P42 development began.

Required scope covered the UDID/authorization chain plus common smoke behavior: cached UDID startup, zonoe callback/nonce path, localhost bridge acceptance where exercised, legacy web/profile fallback, authorization continuation, floating menu and core-feature smoke.

## v1_p42 — Zonoe UDID API Boundary
Source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`
CI Run: `34995566144` / `success`
Status: `passed`
Result: **current device-verified baseline**. User explicitly reported P42 real-device validation normal.

Product change:
- Moved the existing `ZonoeUDIDAPI` implementation from `testmod/视图菜单/NSObject+UI.m` into `testmod/ZONServices/ZonoeUDIDAPI.m`.
- `NSObject+UI.m` now owns only UI behavior from this boundary.
- PBX active Sources: **76 → 77**, with `ZonoeUDIDAPI.m` as the sole addition.
- Exact migration contract passed.
- `ZonoeUDIDAPI.m` independent iPhoneOS compile with `-Wall -Wextra -Werror` passed.
- A_customer and B_debug arm64 + arm64e builds passed.
- Exported symbol set and linked load-library set are unchanged versus P41.

Device result:
- Normal startup passed.
- Floating menu behavior passed.
- UDID/authorization regression reported normal.
- Return-from-Zonoe/browser behavior reported normal.

## P39-B — JDStatusBarNotification dependency audit
Status: `audit only; KEEP_LIVE_DEPENDENCY`.
