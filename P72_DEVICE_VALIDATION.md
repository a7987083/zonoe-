# P72 Device Validation

## Candidate
- Version: `v1_p72`
- Branch: `work/p72-reset-presentation-coordinator`
- Device baseline: `v1_p71`
- Device-baseline build SHA: `ef556183635b6d7256bb33eac456eff9bccae190`
- P72 actual migrated/build SHA: `56dbaa0c9c2d3a065dc4e01709f980254a754e2b`
- CI Run: `35692335444`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## Artifacts
### A_customer
- Artifact ID: `10679661035`
- Artifact digest: `sha256:04a8264086cbdbbb53a25a6d508c06550286974661ea40832c7de62b4bba8773`
- dylib SHA256: `2df04dfe5e91987a90be781641b11d80c777d9a17619c1d7009a4d1625100a3b`

### B_debug
- Artifact ID: `10678952550`
- Artifact digest: `sha256:17f2ddc99ace6370c9585ddf71f92e24bfcfd4b9d93e07e439b0d53bc636d176`
- dylib SHA256: `fd90ebd7cfd4ce3ba6a182d974ffbfab26e95e6d2dedc94d3dde33aacd7487e5`

## Scope
P72 moves reset presentation/orchestration out of `ZONSixButtonActionService` into `ZONResetCoordinator`.

`ZONSixButtonActionService -> ZONResetCoordinator -> { ZONGameDataResetService, ZONAuthorizationResetService }`

The underlying game-data reset and authorization-reset services are unchanged. The historical `clearGameDataPreservingTemporaryDirectory` entry remains as a compatibility forwarder to the coordinator without confirmation UI.

## Required real-device validation
Use A_customer first. Back up any important local game data before testing the destructive reset actions.

1. Launch, menu and six-button regression.
2. Tap **清除游戏数据** and confirm the existing destructive confirmation appears.
3. Cancel **清除游戏数据**; no data is removed and the game stays open.
4. Confirm **清除游戏数据**; staged HUD remains sensible, the game-data reset completes, and the game exits automatically on success.
5. Relaunch after game-data reset and confirm the local game state is reset as expected while authorization/keychain state remains available.
6. Tap **清除授权记录** and confirm the existing destructive confirmation appears.
7. Cancel **清除授权记录**; authorization remains and the game does not exit.
8. Confirm **清除授权记录**; authorization data is cleared, the historical ~3-second delayed exit still occurs, and relaunch requires authorization again.
9. Backup creation/share from P70 remains normal.
10. Local restore from P71 remains normal and still auto-exits after successful restore.
11. Remote ZIP restore and cloud-save restore remain normal and still auto-exit after success.
12. No reset/backup/restore regression or crash is observed.

P72 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
