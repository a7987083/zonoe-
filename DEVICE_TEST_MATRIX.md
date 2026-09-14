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

Changed boundary:
- `zonoe://udid` remains the preferred first-launch acquisition path.
- If the actual `openURL` call cannot open Zonoe, the stable UDID API starts the existing `WX_NongShiFu123 getUDID:` web/profile flow.
- No `canOpenURL` preflight is used.
- Legacy HTTP 404/profile behavior remains unchanged: open `udid.php?...`, exit, then on a later launch consume `udid<id>.txt`, store `DZUDID`, and resume authorization.

## v1_p37 — Canonical Mirror Cleanup
Source commit: `6a605489a5f3837301c2ed127088146538c4c849`
CI Run: `34834303080` / `success`
Status: `superseded; covered by byte-identical p38 device pass`
Runtime equivalence: `testmod/` and `testmod.xcodeproj` exactly match p36 runtime.

## v1_p38 — Canonical Product Source Finalization
Source commit: `43c632d4ce6d04e51f9c8cc033292f9d98b134ff`
Audit Run: `34840224717` / `success`
CI Run: `34840451436` / `success`
Status: `passed`
Result: current device-verified baseline. User explicitly reported p38 real-device validation passed.
Runtime equivalence: `testmod/` and `testmod.xcodeproj` exactly match p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
A_customer dylib SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`, exactly matching p36 and p37.

Repository-only change:
- Proved all 76 PBX product Sources resolve under `testmod/` and zero root copies are active.
- Proved the remaining root `Bsphp/`, `菜单/`, `导入导出/`, `视图菜单/` trees contain no root-only file.
- Removed those four root mirrors and retained the canonical `testmod/...` trees.
- No product runtime source or Xcode project content changed.
- All nine active menu features remain unchanged.

Device result:
- Common smoke/regression reported passed.
- Inherited P36 first-launch UDID behavior is accepted under the byte-identical P38 runtime lineage.
- P38 is promoted as the new fallback/device baseline for subsequent cleanup work.

## v1_p39 — Active Target Slimming
Status: `planned`
Required promotion scope will be defined after the P39 audit identifies the exact source/dependency deletion set.
