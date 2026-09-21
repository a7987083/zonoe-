# P65 Device Validation Record

## Build delivery
- Version: `v1_p65`
- Branch: `work/p65-backup-engine-refactor`
- Runtime/build source: `60db9885c1c69ff7e658bd99949274884d898b32`
- CI Run: `35562076044`
- CI result: `success`
- Architectures: `arm64 + arm64e`

### A_customer
- Artifact ID: `10622392644`
- Artifact digest: `sha256:5523f46a052be04e917db07b761a6e6b06f96bdc695a7a7736e501883be462a0`
- Delivered dylib: `v1_p65_A_customer_testmod.dylib`
- Dylib SHA256: `83ab3e382d27e8c168a7428453e6b6da0f2acf0f5921877cb304e03485bde51e`

### B_debug
- Artifact ID: `10622696370`
- Artifact digest: `sha256:ca401df58423154f61af2eb16f2eff3e534fbac364b77967565420abfee366bd`
- Delivered dylib: `v1_p65_B_debug_testmod.dylib`
- Dylib SHA256: `849760004323c613d63c58c1b516141a732ece72603f2e19927327bebcaf8839`

## Real-device validation required before promotion
Use `A_customer` for the normal end-user device test. Keep `B_debug` for diagnosis if any scoped test fails.

1. Launch/injection regression
   - App launches normally.
   - Menu opens normally.
   - No immediate crash or abnormal startup delay.

2. Existing six-button regression
   - Confirm the existing six-button surface is still visible and callable.
   - Pay special attention to the backup entry route; P65 must not change its external behavior.

3. P65 backup creation
   - Create a backup from the existing backup button.
   - Confirm progress/UI does not hang or crash.
   - Confirm a backup archive is produced successfully.
   - Confirm the archive can be shared/exported as before.

4. Backup-content sanity
   - Confirm expected Documents/Library game data is present in the resulting backup.
   - Confirm obviously volatile cache/temp content is not unexpectedly promoted into persistent backup payload.
   - Record any missing path, extra path, naming change, or archive-layout change.

5. Compatibility-critical restore test
   - Use the existing pre-P66 restore path to restore the exact backup produced by P65.
   - Confirm restore completes without crash/error.
   - Relaunch the game and verify restored user/game data is actually usable.

6. Failure reporting
   - If any step fails, report the exact step, visible UI/error, whether the app crashed, and provide the B_debug runtime log if available.

## Promotion gate
P65 remains `CI PASSED / DEVICE VALIDATION PENDING` until the user explicitly confirms the scoped real-device backup + restore regression has passed.
