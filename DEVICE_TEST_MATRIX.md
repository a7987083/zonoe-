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
CI verification fix commit: `5364d440442474f540d90b8d52f69fabb2b1deb7` (CI/test only; runtime unchanged)
Fixed verification Run: `34891852090` / `success`
Status: `passed`
Result: current device-verified baseline. User explicitly reported p39 real-device validation passed.

Product change:
- Removed unused `NSString+Tools.m/.h` and corresponding PBX references only.
- PBX active Sources: **76 → 75**.
- P38/P39 exported symbol sets are identical.
- Four unique `NSString(Tools)` selectors are intentionally absent in P39.
- Nine active product features remain intact.

Device result:
- App/floating entry/menu behavior reported normal.
- User reported P39 test normal after CI verification succeeded.
- P39 promoted as current real-device baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: `audit only; no deletion approved yet`
If a removal candidate is proven, define a separate device checklist after exact dependency reachability is known. Until then, P39 remains the fallback baseline.
