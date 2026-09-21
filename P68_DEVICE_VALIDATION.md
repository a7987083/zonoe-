# P68 Device Validation

## Candidate

- Version: `v1_p68`
- Branch: `work/p68-cloud-save-engine-audit`
- Previous device baseline: `v1_p67a`
- Previous device-baseline build SHA: `0433ab7f3ce24f5a11dd3d8a4fe3be360a233d61`
- P68 actual migrated/build SHA: `57492160450673f9ea17e69b9d4776668db32773`
- CI Run: `35665082142`
- CI status: `success`
- Device status: `passed`
- Promotion status: `promoted_device_passed`
- User device confirmation: `全部正常`
- Recorded date: `2026-09-22`

## CI artifacts

### A_customer
- Artifact ID: `10669120554`
- Artifact digest: `sha256:59d4c679cf8ae3edf83ea880cfba4a187fb8d3dae82f1930009582ca42ac9a9c`
- dylib SHA256: `56821b48b893a48c88d1d562ef7966e68ec4fd08e604294a1f374ea592983424`

### B_debug
- Artifact ID: `10669470231`
- Artifact digest: `sha256:41c2d6daf7f4f960723e3a66f276588dc8f2e3561983adf88f7e11d340f84832`
- dylib SHA256: `664c2399cdd18536516358faabf06ba0f32662d322f86cf0e268e000b29072b8`

Both variants passed the real Xcode build, dylib output verification, and artifact upload.

## P68 scope

P68 extracts cloud-save business logic from `PubgLoad` into `ZONCloudSaveService` while preserving the P67/P67a download and restore engines:

`PubgLoad UI -> ZONCloudSaveService -> ZONRemoteDownloadService -> ZONRestoreAPI`

Cloud-save service owns:
- metadata JSON retrieval and validation;
- cloud function download-address policy;
- entitlement verification;
- A_customer normal entitlement behavior;
- B_debug entitlement-bypass test mode;
- final archive URL resolution.

P67/P67a behavior remains inherited:
- archive download lifecycle stays in `ZONRemoteDownloadService`;
- complete restore lifecycle stays in `ZONRestoreAPI`;
- successful restore continues through the verified PreferenceManager synchronization/cleanup/exit tail.

## Real-device result

The user explicitly confirmed all scoped P68 validation items were normal.

Validated:
1. Launch / menu / six-button regression: PASS.
2. Cloud-save metadata query and UI: PASS.
3. Authorized cloud-save download -> restore -> automatic game close -> relaunch data verification: PASS.
4. Unauthorized entitlement handling / no unintended archive download: PASS.
5. Historical default `homezip + bundleID.zip` policy: PASS.
6. JSON-provided download address path: PASS.
7. Empty/invalid address failure handling: PASS.
8. Remote manual ZIP download regression: PASS.
9. Local restore and backup regression: PASS.
10. Existing menu actions regression: PASS.

## Promotion

P68 is promoted as the current verified runtime / rollback baseline.

- Version: `v1_p68`
- Runtime/source SHA: `57492160450673f9ea17e69b9d4776668db32773`
- CI Run: `35665082142`
- Device status: `passed`
- Promotion: `promoted_device_passed`

P67a remains the previous known-good historical baseline.
