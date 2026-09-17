# P51-C Restore Refactor Plan

Baseline: promoted P51-B runtime (`e8df5c72c8698eda76971ac44b44d611c6e8cbbb`).
Promoted/device baseline remains P51-B until P51-C passes real-device validation.

## Scope
- Refactor only restore-save implementation in `YYYPicker.m`.
- Preserve `addBtnAction` as the menu-facing restore entry.
- Preserve `yidongwenjian` as a compatibility restore entry used by existing cloud-save/download flows.
- Separate picker/UI orchestration from archive extraction and restore engine responsibilities.
- Preserve inbox convention `/tmp/<bundle-id>-Inbox`.
- Preserve staging root `/tmp/zonoe`.
- Preserve recursive discovery of nested `Documents` and `Library` directories.
- Preserve filename repair through `fixedName:`.
- Preserve skip set `__MACOSX`, `.DS_Store`, `Preferences`.
- Preserve overwrite/type-conflict copy semantics.
- Preserve `PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"` after a successful restore tree is found.

## Non-goals
- No backup changes.
- No cloud/remote download changes.
- No authorization, startup, menu UI, hook, module-loader, or persistence-key changes.
- No PBX membership or framework changes.
- No change to accepted document type (`public.data`) or picker mode (`UIDocumentPickerModeImport`).

## Verification
- Exact runtime scope gate: only `YYYPicker.m` may differ from promoted P51-B under `testmod/` / `testmod.xcodeproj`.
- Static behavior contract for picker delay/type/mode, inbox/staging paths, unzip/remove ordering markers, recursive discovery, skip set, destination roots, compatibility entry, and preference reload.
- Active PBX Sources remain 78.
- A_customer + B_debug builds for arm64 + arm64e.
- Exported symbols and linked libraries must match P51-B artifacts.
- Real-device restore validation required before promotion.

## Candidate evidence
- Runtime source commit: `5154a75a8cd88980387080e6c191b03a8f92a81e`.
- Candidate version: `v1_p51c`.
- Test branch: `test/zonoemenu-v1-p51c-restore-refactor`.
- CI head: `24e0502fded288a32789cfc76db1eba27db58c6c`.
- CI Run: `35268337848` — **success**.
- Contract: PASS; runtime scope is exactly `testmod/导入导出/UIDocumentPickerDelegate/YYYPicker.m`.
- Active Sources: 78.
- A_customer/B_debug: build PASS for `arm64 + arm64e`.
- ABI exported-symbol surface matches P51-B.
- Linked-library surface matches P51-B.
- A_customer artifact: `10518040689`, digest `sha256:b980ab1c91ff352b89d2de395e7a4e12c24b14fd06d2c13158c85616a28b62b8`.
- A_customer dylib SHA256: `f96528132a479cddc67ab15f975a7132ba7e8664fe1c1f9ba5a308b23e1ee3e6`.
- B_debug artifact: `10517890902`, digest `sha256:1db3a21200ffceef329a6a93e5ac4be2af05c545314039c1c588d9a7df9e6256`.
- Promotion status: **candidate / awaiting real-device restore validation**.
