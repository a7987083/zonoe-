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
Result: current device-verified baseline. User explicitly reported p35 real-device validation passed.

## v1_p36 — UDID Web Fallback
Source commit: `c85a6a235daf3287b70c13fbe69be455a3aecce2`
CI Run: `34829714958` / `success`
Status: `pending device verification; runtime carried unchanged into p37`

Changed boundary:
- `zonoe://udid` remains the preferred first-launch acquisition path.
- If the actual `openURL` call cannot open Zonoe, the stable UDID API starts the existing `WX_NongShiFu123 getUDID:` web/profile flow.
- No `canOpenURL` preflight is used, avoiding false negatives when the injected host lacks `LSApplicationQueriesSchemes`.
- If the legacy server returns HTTP 404, the existing code opens `udid.php?id=...&openurl=...&daihao=...` and exits the app as before; after profile acquisition, a subsequent launch rechecks `udid<id>.txt`, stores `DZUDID`, and resumes the existing authorization callback.
- Existing Zonoe callback/nonce behavior, main customer startup ownership, and all nine p35 menu features are preserved.

## v1_p37 — Canonical Mirror Cleanup
Source commit: `6a605489a5f3837301c2ed127088146538c4c849`
CI Run: `34834303080` / `success`
Status: `pending device verification`
Runtime equivalence: `testmod/` and `testmod.xcodeproj` are exactly identical to p36 runtime commit `c85a6a235daf3287b70c13fbe69be455a3aecce2`.
A_customer dylib SHA256: `560165e890968cd5e229e31193c85d76a75ef2620b19bd71dd554e795a7c11c9`, exactly matching p36 A_customer.

Repository-only change:
- Removed root `category/`, `工具箱/`, `SVProgressHUD/`, and `Package/` after exact Git tree-SHA equality proof against their `testmod/` canonical mirrors.
- No product runtime source or Xcode project content changed.
- All nine active menu features remain unchanged.

Required device validation:
- Common device smoke test.
- With Zonoe installed and no existing `DZUDID`: first launch still opens Zonoe and returns through the existing callback path; authorization completes normally.
- Without Zonoe installed and no existing `DZUDID`: failed `zonoe://udid` open automatically switches to the web/profile UDID page instead of stopping.
- Complete the existing profile/web flow; after the legacy flow exits, open the app again and confirm the server result is consumed, `DZUDID` is stored, and authorization proceeds normally.
- With an existing valid `DZUDID`: no unnecessary Zonoe or web acquisition should start.
- Confirm normal menu opening and the nine retained features remain present.

Promotion rule:
- A successful `v1_p37` device report promotes p37 and also covers the byte-identical p36 runtime behavior.
- Until then, `v1_p35` / `def6cb1c51fb0ae174f69ae7c5cebf286d1c4bb9` remains the device-verified baseline.
