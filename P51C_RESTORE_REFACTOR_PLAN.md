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
