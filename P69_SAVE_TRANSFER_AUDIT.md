# P69 Save Transfer Coordinator Audit

## Baseline

- Promoted version: `v1_p68`
- Promoted runtime/build SHA: `57492160450673f9ea17e69b9d4776668db32773`
- P68 CI Run: `35665082142`
- P68 device status: passed

## Finding

After P68, `PubgLoad` no longer owns download transport, restore execution, or cloud-save business/networking. It still owns UI orchestration for manual remote restore and cloud-save presentation.

The primary feature route already receives an explicit `UIViewController *hostViewController` in `ZONSixButtonActionService`, but the old adapter discarded that host, instantiated `PubgLoad`, and `PubgLoad` rediscovered a current controller through `JHPP currentViewController`.

That indirection creates a hidden global UI dependency and makes future transfer refactors more likely to lose presentation/post-action behavior.

## P69 boundary

P69 introduces `ZONSaveTransferCoordinator` as the UIKit orchestration layer:

`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONSaveTransferCoordinator`

The coordinator reuses the promoted service stack without changing their responsibilities:

`ZONSaveTransferCoordinator -> ZONCloudSaveService -> ZONRemoteDownloadService -> ZONRestoreAPI`

Responsibilities:

- `ZONSaveTransferCoordinator`: alerts, progress/status presentation, explicit host view controller, manual URL and cloud-save orchestration.
- `ZONCloudSaveService`: metadata, entitlement, download-address policy and final URL resolution.
- `ZONRemoteDownloadService`: download lifecycle and owned temporary archive.
- `ZONRestoreAPI`: complete restore lifecycle including verified post-restore synchronization/cleanup/exit tail.
- `PubgLoad`: legacy compatibility shim only.

## Behavior preservation

P69 intentionally preserves:

- P67 download service behavior;
- P67a restore API and post-restore exit behavior;
- P68 cloud-save metadata/entitlement policy;
- A_customer entitlement enforcement;
- B_debug cloud entitlement bypass test mode;
- existing alert strings and download/restore progress flow.

P69 does not change backup, local restore, game-data reset, authorization reset, or runtime toggle behavior.
