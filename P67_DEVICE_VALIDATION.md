# P67 Device Validation Record

## Build delivery
- Version: `v1_p67`
- Branch: `work/p67-remote-download-engine-audit`
- Runtime/build source: `71410f993dc9c00d16586af75c7d8e05bcdc8307`
- CI Run: `35574929300`
- CI result: `success`
- Architectures: `arm64 + arm64e`

### A_customer
- Artifact ID: `10627980322`
- Artifact digest: `sha256:eab4c8cbac9b6f1ae0324d88a82efe3e361af6ce04f0c3b5dc0a031f423f5356`
- Delivered dylib: `v1_p67_A_customer_testmod.dylib`
- Dylib SHA256: `2f04058ef7c9146f456541569a957bd98955dde11df28fbd60e2eb724ce7c8d0`

### B_debug
- Artifact ID: `10627384391`
- Artifact digest: `sha256:a4afbd6f544bf6f35ce9244e087c4f175bb8b4efca9b4547b7c1301afc4f82fc`
- Delivered dylib: `v1_p67_B_debug_testmod.dylib`
- Dylib SHA256: `755826f73dfb3e34614b542987ed13fd6579ba5ca967e596257c0857fcd02c8d`

## Required real-device validation before promotion
Use `A_customer` first. Use `B_debug` for diagnosis if a scoped cloud/download test fails.

1. General regression
   - Game launches normally.
   - Menu and six-button surface remain normal.
   - P66 local file restore still works.

2. User-entered remote download
   - Open the existing remote-download entry.
   - Supply a known-good backup ZIP URL.
   - Confirm progress is displayed, download finishes once, restore starts automatically, and data is correct after relaunch.

3. Cloud-save download
   - Run the normal cloud-save query/list/entitlement flow.
   - Trigger a cloud save download.
   - Confirm download progress, automatic P66 restore, and correct data after relaunch.
   - Confirm normal purchase/entitlement behavior is unchanged in A_customer.

4. Failure handling
   - Invalid URL: reject cleanly; no false success.
   - Network/offline failure: show failure; no restore attempt / false success.
   - Non-ZIP download: reject cleanly.
   - Repeated start while a download is active: no overlapping download; should report that a task is already running.

5. Temporary-file safety
   - Confirm unrelated app behavior/transient state is not broken after remote/cloud downloads.
   - P67 must not behave like the old legacy path that cleared the whole application `/tmp` directory.

## Promotion gate
P67 remains `CI PASSED / DEVICE VALIDATION PENDING` until the user explicitly confirms the scoped real-device remote-download and cloud-download tests pass. P66 runtime `5cd3667754449b9a7630ba2d1e7db472d692377b` remains the rollback/device baseline until that confirmation.
