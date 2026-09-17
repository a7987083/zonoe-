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
- `v1_p44`: passed; superseded.
- `v1_p48_1`: passed; superseded.
- `v1_p49`: passed; superseded.
- `v1_p51b`: passed; superseded by P51-C.

## v1_p51c — Restore Refactor
Source: `5154a75a8cd88980387080e6c191b03a8f92a81e`  
CI head: `24e0502fded288a32789cfc76db1eba27db58c6c`  
CI Run: `35268337848` / **success**  
Status: **passed / current promoted device baseline**.

CI evidence:
- Runtime scope limited to `testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m` relative to P51-B.
- Active PBX Sources remain **78**.
- Restore behavior contract passed.
- `addBtnAction` menu entry and `yidongwenjian` compatibility entry preserved.
- `/tmp/<bundle-id>-Inbox` and `/tmp/zonoe` semantics preserved.
- Nested `Documents` / `Library` discovery, filename repair, skip set, overwrite semantics and `MyCustomSettings` reload preserved.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols and linked libraries match P51-B.
- A_customer artifact `10518040689`; digest `sha256:b980ab1c91ff352b89d2de395e7a4e12c24b14fd06d2c13158c85616a28b62b8`.
- A_customer dylib SHA256 `f96528132a479cddc67ab15f975a7132ba7e8664fe1c1f9ba5a308b23e1ee3e6`.
- B_debug artifact `10517890902`; digest `sha256:1db3a21200ffceef329a6a93e5ac4be2af05c545314039c1c588d9a7df9e6256`.

Real-device result:
- User explicitly reported **all P51-C tests normal**.
- P51-B-generated ZIP restore, actual restored state after relaunch, nested backup-root discovery, and VIP cloud-save automatic restore showed no reported regression.
- P51-C is therefore promoted and becomes the current rollback/device baseline.

## Promotion rule
P51-C has satisfied CI and real-device gates. P51-D must start from this promoted runtime.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
