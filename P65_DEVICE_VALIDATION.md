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

## Real-device validation — PASSED
User explicitly reported the complete scoped validation as: **全部正常**.

Validated scope:
1. Launch/injection regression: PASS.
2. Menu and existing six-button surface: PASS.
3. P65 backup creation: PASS.
4. Backup archive/output/share behavior: PASS.
5. Restore of the exact P65-produced backup through the existing pre-P66 restore path: PASS.
6. Post-restore game/data behavior: PASS.

## Promotion result
- Device status: `PASSED`.
- Promotion status: `PROMOTED`.
- Promoted runtime/build source remains `60db9885c1c69ff7e658bd99949274884d898b32`; later documentation-only commits are not runtime build revisions.
- P65 becomes the rollback/device baseline for P66.
