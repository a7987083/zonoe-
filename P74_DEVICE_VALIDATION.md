# P74 Device Validation

## Candidate
- Version: `v1_p74`
- Branch: `work/p74-feature-dispatcher-boundary`
- Device baseline: `v1_p73`
- Device-baseline build SHA: `4a81c201556fa1c371f5a258b82b08322d34c649`
- P74 actual migrated/build SHA: `47840ad17fb4780dff4294adf162cb08a02bb6dc`
- CI Run: `35695305509`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

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

## Required real-device validation
Use A_customer first.

1. Launch, menu and six-button regression.
2. Tap the local-files action and confirm the sandbox browser opens normally.
3. Confirm navigation/presentation behavior matches P73 on the test device.
4. Browse Documents and representative subdirectories; back navigation remains normal.
5. Open/inspect a representative file if supported by the existing browser flow.
6. Dismiss local-files and reopen it repeatedly; no stuck controller, duplicate presentation or crash.
7. Backup creation/share remains normal.
8. Local restore remains normal and still auto-exits after success.
9. Remote ZIP restore and cloud-save restore remain normal and still auto-exit after success.
10. Clear game data and clear authorization flows remain normal.
11. Runtime iap-noads/ad-speed toggles keep the same behavior as P73 if exposed in the current menu.
12. No route regression, false success or crash is observed.

P74 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
