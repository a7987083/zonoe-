# DEVICE TEST MATRIX

## Rule
Every runtime-affecting development version must define its required real-device regression scope before promotion. CI success alone never changes `last_device_verified_*`.

## Common device smoke test
- App launches normally; floating entry appears normally.
- Menu opens/closes normally; outside-tap close works.
- Section fold/unfold and relayout work.
- Card/grid buttons, switches, ad switch and speed slider remain usable.
- No obvious freeze/crash while opening, closing, folding, or operating controls.

## Historical promoted baselines
- `v1_p41`: passed; superseded.
- `v1_p42`: passed; superseded.
- `v1_p44`: passed; superseded by later promoted baselines.
- P45/P46/P47 intermediate CI-verified behavior is covered by later real-device-passed baselines.
- `v1_p48_1`: passed; superseded by P49.
- `v1_p49`: passed; superseded by P51-B.

## v1_p51b — Backup Refactor
Source: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`  
CI head: `cd70800e364cf9ceb8c5c3b91df3b9d8c1a377a6`  
CI Run: `35255286856` / **success**  
Status: **passed / current promoted device baseline**.

CI evidence:
- Runtime scope limited to `testmod/导入导出/daochucd.m` relative to P51-A.
- Active PBX Sources remain **78**.
- Backup behavior contract passed.
- Documents/Library backup paths preserve the existing 50 MiB confirmation semantics.
- Staging layout remains `tmp/zonoe/{Documents,Library}`.
- Cleanup paths remain `Library/HeimdallrBU`, `Library/Caches`, `Library/UnityCache`, and `Documents/zonoe` inside the staging tree.
- Archive destination remains `Documents/zonoe/<name>.zip` and the existing share flow is preserved.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols and linked libraries match the P51-A candidate.
- A_customer artifact `10511909626`; digest `sha256:a8786d238573418cdd69e51578df0b8e5a8fab791dbac61e462dd81c55c2c5b6`.
- A_customer dylib SHA256 `770b2cc1088fdcaa9f7fcfb5abb08d17e257f38f992ecee4b8b3eed4149f1053`.
- B_debug artifact `10511974476`; digest `sha256:d456aa02a8bc5cfc23f02c349949af468261e370b1c0b37af156b4fe965fb0be`.

Real-device result:
- User explicitly reported **all P51-B device tests normal**.
- Small backup, named backup, Documents+Library archive structure, >50 MiB skip/backup paths, cleanup behavior, repeated backup, cancellation paths, and quick regression checks showed no reported regression.
- P51-B is therefore promoted and becomes the current rollback/device baseline.

## Previous v1_p49 baseline
Source: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`  
CI Run: `35195152912` / success.  
Status: passed / superseded by P51-B.

## Promotion rule
P51-B has satisfied both CI and real-device gates. P51-C must start from this promoted baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
