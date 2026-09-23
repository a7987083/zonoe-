# P77 Device Validation

## Candidate
- Version: `v1_p77`
- Branch: `work/p77-remote-restore-coordinator`
- Device baseline: `v1_p76`
- Device-baseline build SHA: `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`
- P77 actual migrated/build SHA: `0842910febc350908e2b61781ac396dd609c91e2`
- CI Run: `35931692582`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## Artifacts
### A_customer
- Artifact ID: `10780389378`
- Artifact digest: `sha256:42b212595d34bcd9b56582bab87b4a8b1fc705f2230eaeca530aa863ee8c7170`
- dylib SHA256: `ea3075cc22fbc50233384dba3b40061c9b514760653750540ae40d5632d81d27`

### B_debug
- Artifact ID: `10781640726`
- Artifact digest: `sha256:3873b91b3bb867dfd904d405cf04f9f4542ac2ca9f4b5ff7f63ef416d7d180c9`
- dylib SHA256: `a0d6fce3c142bbe4d6a0ca712a970e14d466feb8fb7b42df27a84eeba4e0dab5`

## Scope
P77 extracts the common remote-download-to-restore presentation/orchestration path from `ZONSaveTransferCoordinator` into `ZONRemoteRestoreCoordinator`.

`remote URL / cloud resolved URL -> ZONSaveTransferCoordinator -> ZONRemoteRestoreCoordinator -> ZONRemoteDownloadService -> ZONRestoreAPI -> ZONRestoreService -> PreferenceManager success tail`

P77 intentionally does not modify authorization core (`WX_NongShiFu123.mm`), backup, local restore, runtime toggles, cloud metadata/entitlement policy, `ZONRemoteDownloadService`, `ZONRestoreAPI`, or the P66 post-restore success/exit tail.

## Required real-device validation
Use A_customer first.

1. Launch/menu/basic six-button behavior remains normal.
2. Remote ZIP alert opens normally; a valid URL starts download.
3. Download progress still updates as percent when size is known and MB when unknown.
4. Successful download still shows `下载成功，正在恢复存档...` and then restores through the unchanged restore API.
5. Successful remote restore still auto-exits the game through the unchanged PreferenceManager post-success tail; relaunch data is correct.
6. Empty/invalid remote URL behavior remains normal; no false success or unexpected exit.
7. Remote download transport failure shows failure UI and does not enter a false restore path.
8. Cloud-save metadata/list/entitlement behavior remains unchanged; selecting a valid cloud archive routes into the same shared remote restore chain and still restores/exits correctly.
9. Local restore still works and auto-exits after success.
10. Backup create/share, local files, clear game data, clear authorization, and authorization startup remain normal.
11. No crash, duplicate presentation, route inversion, false success, or unexpected early exit is observed.

P77 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
