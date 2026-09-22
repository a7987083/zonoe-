# CHANGELOG_DEV

## 2026-09-22 — v1_p69 Save Transfer Coordinator — DEVICE PASSED / PROMOTED
- Branch: `work/p69-save-transfer-coordinator`.
- Baseline: P68 runtime `57492160450673f9ea17e69b9d4776668db32773`.
- Actual migrated/build SHA: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Added `ZONSaveTransferCoordinator` as the explicit UI/process orchestration boundary for remote download and cloud save.
- `ZONSixButtonActionService` now passes the active `hostViewController` directly instead of routing through a fresh `PubgLoad` instance and rediscovering the active controller.
- `PubgLoad` is reduced to compatibility forwarding for the migrated save-transfer selectors.
- Reused the P67/P67a/P68 service stack unchanged: `ZONCloudSaveService`, `ZONRemoteDownloadService`, and `ZONRestoreAPI`.
- Updated inherited contracts so they validate behavior ownership rather than requiring the implementation to remain physically inside `PubgLoad`.
- A_customer `arm64 + arm64e`: PASS. Artifact `10670576190`, digest `sha256:5978d27119c39697231b1edf3c6a061b20d1fc82dd917696a7ab55c8a341032e`, dylib SHA256 `475d6721881ea69d1aebb131449ad66038342040fe98dcc9886207c167419574`.
- B_debug `arm64 + arm64e`: PASS. Artifact `10670576184`, digest `sha256:a901681c897f10da2d3d20e2e68a32dffd4af310b4a1ff6cfb0344838932a79f`, dylib SHA256 `23a07b9272cb6ce5f591d95d35c253858914d470918e3f9b5bcac865e0407615`.
- User explicitly reported P69 real-device validation: `全部正常`.
- **P69 is promoted and becomes the current device baseline. P68 remains the previous rollback baseline.**

## Recent promoted history
- P68 — Cloud Save Engine Extraction — device passed / promoted.
- P67a — Restore compatibility hotfix — device passed / promoted.
- P67 — Remote Download Engine Extraction — CI passed, device regression, not promoted.
- P66 — Restore Engine Audit/Extraction — device passed / promoted.
- P65 — Backup Engine Refactor — device passed / promoted.

## Operating rule
New development must branch conceptually from the latest device-passed runtime, not from stale planning text. The next phase must be selected after auditing the current P69 source responsibilities and data flow.
