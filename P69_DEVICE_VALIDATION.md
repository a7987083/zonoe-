# P69 Device Validation

## Final status

- Version: `v1_p69`
- Branch: `work/p69-save-transfer-coordinator`
- Previous device baseline: `v1_p68`
- Previous baseline build SHA: `57492160450673f9ea17e69b9d4776668db32773`
- P69 actual migrated/build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`
- CI Run: `35668507458`
- CI status: `success`
- Device status: `passed`
- Promotion status: `promoted`
- Device result explicitly reported by user: `全部正常`

## CI artifacts

### A_customer
- Artifact ID: `10670576190`
- Artifact digest: `sha256:5978d27119c39697231b1edf3c6a061b20d1fc82dd917696a7ab55c8a341032e`
- dylib SHA256: `475d6721881ea69d1aebb131449ad66038342040fe98dcc9886207c167419574`

### B_debug
- Artifact ID: `10670576184`
- Artifact digest: `sha256:a901681c897f10da2d3d20e2e68a32dffd4af310b4a1ff6cfb0344838932a79f`
- dylib SHA256: `23a07b9272cb6ce5f591d95d35c253858914d470918e3f9b5bcac865e0407615`

Both variants passed inherited P67/P67a/P68 contracts, the P69 coordinator contract, Xcode 16.4 build, dylib verification and artifact upload.

## Promoted architecture

`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONSaveTransferCoordinator -> ZONCloudSaveService / ZONRemoteDownloadService -> ZONRestoreAPI`

`PubgLoad` remains only as a legacy compatibility shim for the migrated save-transfer routes.

## Device validation result

The scoped P69 checks were reported fully normal on real device, including launch/menu regression, manual remote download, cloud-save path, post-restore exit/relaunch behavior, entitlement behavior and local backup/restore regression.

P69 is now the current promoted/device baseline. P68 remains the previous rollback baseline.
