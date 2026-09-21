# P69 Device Validation

## Candidate

- Version: `v1_p69`
- Branch: `work/p69-save-transfer-coordinator`
- Device baseline: `v1_p68`
- Device-baseline build SHA: `57492160450673f9ea17e69b9d4776668db32773`
- P69 actual migrated/build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`
- CI Run: `35668507458`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## CI artifacts

### A_customer
- Artifact ID: `10670576190`
- Artifact digest: `sha256:5978d27119c39697231b1edf3c6a061b20d1fc82dd917696a7ab55c8a341032e`
- dylib SHA256: `475d6721881ea69d1aebb131449ad66038342040fe98dcc9886207c167419574`

### B_debug
- Artifact ID: `10670576184`
- Artifact digest: `sha256:a901681c897f10da2d3d20e2e68a32dffd4af310b4a1ff6cfb0344838932a79f`
- dylib SHA256: `23a07b9272cb6ce5f591d95d35c253858914d470918e3f9b5bcac865e0407615`

Both variants passed inherited P67/P67a/P68 contracts, the P69 coordinator contract, the real Xcode 16.4 build, dylib output verification, and artifact upload.

## Scope

P69 moves save-transfer UI/process orchestration out of `PubgLoad` into `ZONSaveTransferCoordinator` and passes the existing host view controller explicitly from `ZONSixButtonActionService`.

The P67/P67a/P68 service stack is reused unchanged:

`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONSaveTransferCoordinator -> ZONCloudSaveService / ZONRemoteDownloadService -> ZONRestoreAPI`

`PubgLoad` remains only as a legacy compatibility shim.

## Real-device validation required

Use A_customer first.

1. Launch, menu and six-button regression.
2. Manual remote-download alert appears from the active menu host.
3. Valid manual ZIP URL downloads, restores, closes the game after success, and restored data is correct after relaunch.
4. Empty manual URL re-prompts; invalid URL/network/non-ZIP errors do not falsely report success or close the game.
5. Cloud-save metadata title/subtitle/buttons render normally.
6. Authorized cloud-save item downloads, restores, closes the game, and data is correct after relaunch.
7. Unauthorized entitlement shows the purchase prompt and does not start archive download.
8. Historical default `homezip + bundleID.zip` and JSON custom download address both work.
9. B_debug entitlement-bypass diagnostic behavior remains available.
10. Local backup and local restore remain functional.

P69 must not be promoted until the user explicitly confirms the scoped device validation passes.
