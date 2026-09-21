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

## P66 changes validated on device
- Restore filesystem/archive execution extracted from `YYYPicker` into `ZONRestoreService`.
- Restore compatibility rules owned by `ZONRestorePolicy`.
- Existing `addBtnAction` picker entry preserved.
- Existing `yidongwenjian` cloud/download compatibility entry preserved.
- Merge/overwrite restore semantics preserved; P66 does not convert restore into snapshot replacement.
- Shared SSZipArchive rejects standardized output paths that escape the requested extraction root.
- Common backup root containing Documents/Library is preferred, with legacy independent recursive discovery retained as fallback.
- Selected imported archive is cleaned individually; the whole Inbox is removed only when empty.
- Restore execution is serialized.

## Real-device validation result
User explicitly confirmed on 2026-09-21 that all scoped P66 validation items are normal.

Validated:
- Launch/menu regression: PASS.
- Existing six-button surface: PASS.
- P65 backup -> P66 restore: PASS.
- Historical backup compatibility: PASS.
- Cloud/download `yidongwenjian` compatibility: PASS.
- Failure handling / abnormal restore behavior: PASS.
- Existing backup and other six-button regression: PASS.

## Promotion
- Device status: `passed`.
- Promotion status: `promoted_device_passed`.
- New rollback/device baseline: `v1_p66` runtime source `5cd3667754449b9a7630ba2d1e7db472d692377b`.
- P65 remains the prior known-good baseline for historical comparison, but P66 is now the active promoted baseline for follow-on development.
