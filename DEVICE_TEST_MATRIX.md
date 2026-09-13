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
Result: current device-verified baseline.

## v1_p33 — Bootstrap / ModuleLoader Boundary
Source commit: `0f12e4353e8859c585fe2975812964a28b7410d1`
CI Run: `34733013479` / `success`
Status: `pending device verification`

Changed boundary:
- `ZONBootstrap.h` is declarations-only; `ZONBootstrap.m` owns the unchanged bootstrap body.
- `ZONModuleLoader.h` exposes declarations only; `ZONModuleLoader.m` owns the unchanged loader logic.
- Both `.m` files are normal Xcode target sources.
- No intended authorization, UDID, menu, route, persistence, UI, ABI or module-loading semantic changes.

Required device validation:
- Common device smoke test.
- A_customer launches normally and reaches the same existing authorization path as p32.
- Existing valid `DZUDID`/authorization state still avoids an unnecessary new UDID acquisition flow.
- Do not clear authorization only to exercise first activation unless an intentional destructive/activation test is desired.
- Legacy framework preflight still behaves normally when AppLovinSDK/UnityFramework are present or absent; no launch crash/freeze.
- Floating entry/menu appears normally after startup.
- No duplicate bootstrap behavior or duplicate visible startup action is observed.
- If no bundled `ZONModules` directory exists, launch continues normally without error UI/crash.
- Repeated app launches and repeated menu open/close remain stable.
- P32 menu/runtime smoke remains unchanged.

Promotion rule:
- Promote `v1_p33` only after `A_customer` real-device startup/bootstrap regression is explicitly reported as passed.
- Until then, `v1_p32` / `84f8b3898bee9d95ed4034d12842879cc56280d3` remains the device-verified baseline.
