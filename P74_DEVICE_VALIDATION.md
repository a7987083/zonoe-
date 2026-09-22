# P74 Device Validation

## Candidate
- Version: `v1_p74`
- Branch: `work/p74-feature-dispatcher-boundary`
- Previous device baseline: `v1_p73`
- Previous device-baseline build SHA: `4a81c201556fa1c371f5a258b82b08322d34c649`
- P74 actual migrated/build SHA: `47840ad17fb4780dff4294adf162cb08a02bb6dc`
- CI Run: `35695305509`
- CI status: `success`
- Device status: `passed`
- Promotion status: `promoted_device_passed`
- User confirmation: `全能正常`
- Recorded date: `2026-09-22`

## Artifacts
### A_customer
- Artifact ID: `10680137532`
- Artifact digest: `sha256:8122ac384972969a886b40a2a6d8fea55250b5c16bf6c969d02c1172e4b011fb`
- dylib SHA256: `3fed6bf8cfc198c78254fa020d990d9b04e448535dd3938b58e23fc97e3e6d3f`

### B_debug
- Artifact ID: `10680386985`
- Artifact digest: `sha256:be8ad97b608bb4fa9b4de737cfc90dcbe03a517c687ea47065cdb65f13c64714`
- dylib SHA256: `2c9d6e77ab0561ba74246db9367ffab005a687082935c0aea5e845fea6c9866a`

## Scope
P74 moves local-files presentation out of `ZONFeatureDispatcher` into `ZONLocalFilesCoordinator`.

`ZONFeatureDispatcher -> ZONLocalFilesCoordinator -> SandboxBrowserVC / UINavigationController`

The existing presentation behavior is preserved: iOS 13+ uses page sheet and older systems use full screen. Runtime toggle behavior (`NNGG/NNGGNNGG/NeiGou` and `AADD/AADDAADD/ADSpeed`) is intentionally unchanged in P74.

## Real-device validation result
User confirmed all scoped behavior normal on device.

1. Launch, menu and six-button regression: PASS.
2. Local-files action opens sandbox browser normally: PASS.
3. Navigation/presentation behavior matches prior baseline: PASS.
4. Documents/subdirectory browsing and back navigation: PASS.
5. Representative file handling remains normal: PASS.
6. Repeated dismiss/reopen has no stuck controller, duplicate presentation or crash: PASS.
7. Backup creation/share regression: PASS.
8. Local restore and post-success auto-exit regression: PASS.
9. Remote ZIP restore and cloud-save restore regression: PASS.
10. Clear game data and clear authorization regression: PASS.
11. Runtime iap-noads/ad-speed behavior remains unchanged: PASS.
12. No route regression, false success or crash observed: PASS.

## Promotion
P74 is promoted as the current verified runtime and rollback baseline.

The verified runtime/source baseline is exactly `47840ad17fb4780dff4294adf162cb08a02bb6dc`. Any later documentation-only commits on the branch are not substitutes for that tested runtime SHA.

P73 remains the previous known-good historical baseline.
