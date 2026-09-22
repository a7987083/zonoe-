# P73 Device Validation

## Candidate
- Version: `v1_p73`
- Branch: `work/p73-six-button-routing-cleanup`
- Device baseline: `v1_p72`
- Device-baseline build SHA: `56dbaa0c9c2d3a065dc4e01709f980254a754e2b`
- P73 actual migrated/build SHA: `4a81c201556fa1c371f5a258b82b08322d34c649`
- CI Run: `35693629736`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## Artifacts
### A_customer
- Artifact ID: `10679429187`
- Artifact digest: `sha256:4a7f29605a3e1fcd6f5951a839854d656a0ad863b66abe24a064d53eb4b284a7`
- dylib SHA256: `09777ffb8d2296eb8f1715a79bc1f81aa6fae71b6bb6d1f43d319a349a21341e`

### B_debug
- Artifact ID: `10679805076`
- Artifact digest: `sha256:36421c613489496ffc2125cb4e970b32fcb10cb31bbc41051011942aa9439f4c`
- dylib SHA256: `f9d139288dbfe844f2732390719605ff421ab306e7c24cd4fd18bb9ae56d8d24`

## Scope
P73 separates runtime temporary-directory compatibility from the six-button routing boundary.

- `ZONRuntimeDirectoryService` now owns tmp-path and tmp-directory preparation.
- `ZONFeatureDispatcher` C compatibility helpers route directly to `ZONRuntimeDirectoryService` / `ZONResetCoordinator`.
- `ZONSaveTransferCoordinator` now performs the historical cloud-save tmp preparation itself.
- `ZONSixButtonActionService` no longer owns filesystem implementation. Historical Objective-C helper selectors remain as thin compatibility forwarders.
- P65 through P73 behavior contracts pass in CI.

## Required real-device validation
Use A_customer first.

1. Launch, menu and six-button regression.
2. Remote ZIP download/restore still works and successful restore still auto-exits.
3. Cloud-save list opens normally and cloud restore still works; successful restore still auto-exits.
4. Confirm cloud-save flow still works after a clean launch where the tmp directory may need to be prepared.
5. Local backup creation/share remains normal.
6. Local restore remains normal and still auto-exits after success.
7. Clear game data confirmation/cancel/confirm behavior remains normal; authorization remains after game-data reset.
8. Clear authorization confirmation/cancel/confirm behavior remains normal; confirmed clear retains the historical delayed exit.
9. File-browser/local-files action remains normal.
10. Repeat cloud-save or remote-restore once after a prior restore/reset cycle to catch tmp-directory lifecycle regressions.
11. No crash, false success, missing HUD, or route regression is observed.

P73 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
