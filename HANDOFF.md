# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read `PROJECT_STATE.json`, `DEVICE_TEST_MATRIX.md`, `P50_ARCHITECTURE_FREEZE.md`, then `P51B_BACKUP_REFACTOR_PLAN.md`.

## Current promoted runtime baseline
- Version: `v1_p51b`.
- Work branch: `work/zonoemenu-v1-p51b-backup-refactor`.
- Product source: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`.
- Test branch: `test/zonoemenu-v1-p51b-backup-refactor`.
- CI head: `cd70800e364cf9ceb8c5c3b91df3b9d8c1a377a6`.
- CI Run `35255286856`: success.
- Real-device validation: passed, explicitly reported by user.
- Active Sources: 78.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10511909626`, digest `sha256:a8786d238573418cdd69e51578df0b8e5a8fab791dbac61e462dd81c55c2c5b6`.
- A_customer dylib SHA256: `770b2cc1088fdcaa9f7fcfb5abb08d17e257f38f992ecee4b8b3eed4149f1053`.
- B_debug artifact: `10511974476`, digest `sha256:d456aa02a8bc5cfc23f02c349949af468261e370b1c0b37af156b4fe965fb0be`.
- P51-B is the current rollback/device baseline.

## P51-B behavior preserved
- `data.backup-save` still enters through `backupasd -> bfcundang:`.
- Documents and Library are staged under `tmp/zonoe/{Documents,Library}`.
- >50 MiB items still require Skip/Backup confirmation.
- Cleanup inside staging still removes `Library/HeimdallrBU`, `Library/Caches`, `Library/UnityCache`, and `Documents/zonoe` contents.
- Archive output remains `Documents/zonoe/<name>.zip`.
- Existing share flow remains active.

## Frozen architecture rules
- Registry/Dispatcher remains the menu execution boundary.
- Startup/bootstrap, authorization/UDID, module-loader ordering, persistence/save semantics and destructive-data behavior require dedicated stages if changed.
- Active source/framework dependency changes require reachability evidence, dual-variant CI and the normal promotion gate.
- CI success does not equal real-device promotion for runtime candidates.
- Each completed runtime stage must provide an A_customer dylib to the user after CI success.

## Immediate Next Task
P51-C: restore-save refactor. Separate document-picker/UI orchestration from restore engine while preserving ZIP import, nested Documents/Library discovery, overwrite semantics, skip set, PreferenceManager reload, and current user-visible behavior. Start from promoted P51-B.
