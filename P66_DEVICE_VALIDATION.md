# P66 Device Validation Record

## Build delivery
- Version: `v1_p66`
- Branch: `work/p66-restore-engine-audit`
- Runtime/build source: `5cd3667754449b9a7630ba2d1e7db472d692377b`
- CI Run: `35573653173`
- CI result: `success`
- Architectures: `arm64 + arm64e`

### A_customer
- Artifact ID: `10626703331`
- Artifact digest: `sha256:877487080313af302a1af64d4df9a3252cd40d7f320ff61e4d76c0a954507ac3`
- Delivered dylib: `v1_p66_A_customer_testmod.dylib`
- Dylib SHA256: `6373be7be7777a4b7401340ef905b744837629221a1eb4a0644558ed4d76aee8`

### B_debug
- Artifact ID: `10627431692`
- Artifact digest: `sha256:9e05f86bbb8160e0f2cf83200e361a2bcfd6de00bbdb6cf2520036fcb4fc93cf`
- Delivered dylib: `v1_p66_B_debug_testmod.dylib`
- Dylib SHA256: `f67f6e55d5f53796f3b83fdcc5ef7de230f3a415db32dfffdbc2b93f58f7119f`

## P66 changes under device test
- Restore filesystem/archive execution extracted from `YYYPicker` into `ZONRestoreService`.
- Restore compatibility rules owned by `ZONRestorePolicy`.
- Existing `addBtnAction` picker entry preserved.
- Existing `yidongwenjian` cloud/download compatibility entry preserved.
- Merge/overwrite restore semantics preserved; P66 does not convert restore into snapshot replacement.
- Shared SSZipArchive now rejects standardized output paths that escape the requested extraction root.
- Prefer a common backup root containing Documents/Library, with legacy independent recursive discovery retained as fallback.
- Selected imported archive is cleaned individually; the whole Inbox is removed only when empty.

## Real-device validation required before promotion
Use `A_customer` for normal testing. Use `B_debug` only for diagnosis if a scoped test fails.

1. Launch/menu regression
   - Game launches normally.
   - Menu appears normally.
   - Existing six-button surface remains callable.

2. P65 backup -> P66 restore
   - Create or use a backup produced by the promoted P65 build.
   - Restore it with P66.
   - Confirm restore completes without crash/error.
   - Relaunch game and verify restored data is correct.

3. Historical backup compatibility
   - Restore at least one older backup created before P65.
   - Confirm Documents/Library data remains compatible and usable after relaunch.

4. Cloud/download compatibility
   - Run the existing cloud/download restore flow which prepares `/tmp/zonoe` and reaches `yidongwenjian`.
   - Confirm it still restores successfully.

5. Failure safety
   - Select a non-ZIP/corrupt file and confirm restore fails without reporting false success.
   - If practical, test an archive containing an unsafe `../` entry and confirm extraction is rejected.

6. General regression
   - Backup still works normally.
   - Clear game data / authorization reset and other six-button actions remain normal.

## Promotion gate
P66 remains `CI PASSED / DEVICE VALIDATION PENDING` until the user explicitly confirms the scoped P66 real-device restore tests have passed. P65 runtime `60db9885c1c69ff7e658bd99949274884d898b32` remains the rollback/device baseline until that confirmation.
