# P51-B Backup Refactor

Baseline: P51-A candidate (`e1be699655cec468c7d69fd15ed60f1810a4f3b1`).
Promoted/device baseline remains P49 (`4cebe094ad7a4dd554e8266af34dcf3abe04902a`).

## Scope
- Refactor only the backup implementation behind `data.backup-save`.
- Preserve `backupasd -> bfcundang:` entry semantics.
- Preserve 50 MiB confirmation threshold and Skip/Backup choices.
- Preserve temp layout `tmp/zonoe/{Documents,Library}`.
- Preserve cleanup of `Library/HeimdallrBU`, `Library/Caches`, `Library/UnityCache`, and `Documents/zonoe` inside the staging tree.
- Preserve archive destination `Documents/zonoe/<name>.zip` and sharing flow.
- Preserve current progress/status strings.

## Implemented
- Product/runtime commit: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`.
- Replaced duplicated Documents and Library loops with one `copyBackupTopLevelFrom:to:label:fileManager:` implementation.
- Centralized the existing 50 MiB prompt behavior in `shouldSkipBackupItemNamed:size:`.
- Kept existing `folderSizeAtPath:`, staging cleanup, archive creation, sharing and background execution model.
- No PBX membership change; Active Sources remain 78.

## CI verification
- Test branch: `test/zonoemenu-v1-p51b-backup-refactor`.
- CI head: `cd70800e364cf9ceb8c5c3b91df3b9d8c1a377a6`.
- CI Run: `35255286856` — SUCCESS.
- Static scope/behavior contract: PASS.
- A_customer + B_debug: PASS.
- Architectures: arm64 + arm64e.
- Exported symbol sets: identical to P51-A candidate artifacts.
- Linked libraries: identical to P51-A candidate artifacts.
- A_customer artifact: `10511909626`, digest `sha256:a8786d238573418cdd69e51578df0b8e5a8fab791dbac61e462dd81c55c2c5b6`.
- A_customer dylib SHA256: `770b2cc1088fdcaa9f7fcfb5abb08d17e257f38f992ecee4b8b3eed4149f1053`.
- B_debug artifact: `10511974476`, digest `sha256:d456aa02a8bc5cfc23f02c349949af468261e370b1c0b37af156b4fe965fb0be`.

## Device status
- Not yet device tested.
- P49 remains the promoted rollback/device baseline.
- P51-B must not be promoted until the user explicitly reports a real-device pass.

## Deferred risks
- The >50 MiB prompt still uses a background semaphore with `DISPATCH_TIME_FOREVER`; this is intentionally preserved for behavior equivalence and should be changed only in a separate behavior stage.
- `folderSizeAtPath:` still performs a recursive pre-scan before copy; performance optimization is deferred until equivalence fixtures exist.
