# P72 Device Validation

## Candidate
- Version: `v1_p72`
- Branch: `work/p72-reset-presentation-coordinator`
- Device baseline: `v1_p71`
- Device-baseline build SHA: `ef556183635b6d7256bb33eac456eff9bccae190`
- P72 actual migrated/build SHA: `56dbaa0c9c2d3a065dc4e01709f980254a754e2b`
- CI Run: `35692335444`
- CI status: `success`
- Device status: `passed`
- Promotion status: `promoted`
- Device validation reported by user: `true`

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

## Real-device validation result
The user explicitly confirmed all scoped P72 validation items are normal/passed.

Validated scope:
1. Launch, menu and six-button regression passed.
2. **清除游戏数据** confirmation appears normally.
3. Cancelling **清除游戏数据** preserves data and keeps the game open.
4. Confirming **清除游戏数据** preserves staged HUD behavior, completes reset, and exits automatically on success.
5. Relaunch after game-data reset shows reset local state while authorization/keychain state remains available.
6. **清除授权记录** confirmation appears normally.
7. Cancelling **清除授权记录** preserves authorization and does not exit.
8. Confirming **清除授权记录** clears authorization and preserves the historical ~3-second delayed exit; relaunch requires authorization again.
9. P70 backup creation/share regression passed.
10. P71 local restore regression passed and successful restore still auto-exits.
11. Remote ZIP restore and cloud-save restore regression passed and successful restore still auto-exits.
12. No reset/backup/restore regression or crash was reported.

## Promotion
P72 is promoted to the current device-verified runtime baseline.

- Promoted runtime SHA: `56dbaa0c9c2d3a065dc4e01709f980254a754e2b`
- Previous device-verified rollback baseline: `v1_p71` / `ef556183635b6d7256bb33eac456eff9bccae190`
