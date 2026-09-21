# P69 Device Validation

## Candidate

- Version: `v1_p69`
- Branch: `work/p69-save-transfer-coordinator`
- Device baseline: `v1_p68`
- Device-baseline build SHA: `57492160450673f9ea17e69b9d4776668db32773`
- Device status: `pending`
- Promotion status: `not_promoted`

## Scope

P69 moves save-transfer UI/process orchestration out of `PubgLoad` into `ZONSaveTransferCoordinator` and passes the existing host view controller explicitly from `ZONSixButtonActionService`.

The P67/P67a/P68 service stack is reused unchanged.

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
