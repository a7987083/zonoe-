# P48 — Legacy God-Object Split #1 Preflight

## Gate state
P48 runtime implementation remains blocked until the inherited P46/P47 real-device promotion gate passes. Current promoted rollback baseline remains P44.

## Selected legacy unit
`testmod/导入导出/fuhzu.m`

## Selected responsibility
Move only the App Store version lookup/comparison responsibility out of `fuhzu.m`.

### Exact selector set
- `checkbanben`
- `checkAppStoreVersionWithAppId:`
- `compareVersion:`
- `checkbanbencn`
- `checkAppStoreVersionWithAppIdcn:`
- `compareVersioncn:`

These methods form a coherent ownership cluster around App Store metadata lookup, persistence of version/name/URL/date/id values, and local-vs-store version comparison. They are separate from the file/import/export helper responsibilities that remain in `fuhzu.m`.

## Planned destination
After device promotion only:
- `testmod/ZONServices/ZONAppStoreVersionChecker.h`
- `testmod/ZONServices/ZONAppStoreVersionChecker.m`

The implementation must preserve the existing Objective-C selectors and call sites. Mechanical move first; no API redesign in P48.

## Protected behavior
- Preserve lookup URLs exactly, including international and `/cn/` variants.
- Preserve synchronous `stringWithContentsOfURL:` behavior and current calling thread.
- Preserve `NSUserDefaults` keys and write order: `服务器版本号`, `应用名称`, `下载地址`, `最新版本日期`, `游戏版本ID`.
- Preserve numeric version comparison semantics (`NSNumericSearch`).
- Preserve international -> China fallback behavior and existing selector calls.
- Preserve current logging and nil/error behavior.
- Do not alter UI presentation code, timers, dispatch, file import/export, zip handling, backup/restore, or `JHPP` behavior.
- Do not touch `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, or `YYYPicker.m` in this phase.

## Expected build surface after implementation
- Active PBX Sources: 79 -> 80.
- Exactly one new active translation unit: `ZONAppStoreVersionChecker.m`.
- `fuhzu.m` remains active.
- Exports and load libraries must remain identical to immediate runtime predecessor.

## Mechanical equivalence contract
The P48 implementation contract must reconstruct the six moved method bodies from the new implementation and compare normalized method text against the P47 source block. No cleanup or semantic edits are allowed during the move.

## Device gate after implementation
Because P48 changes translation-unit ownership, A_customer real-device regression is required even if ABI/load libraries are unchanged. At minimum verify startup/auth/UDID/fallback/menu smoke plus the version-check path where reachable.

## Why other candidates were not selected
- `WX_NongShiFu123.mm`: authorization/network/UI/UDID coupling remains too high-risk.
- `PubgLoad.mm`: still combines menu/config/download/package/UI state.
- `JiangHuHook.m`: runtime CaptainHook/payment/ad hook surface remains protected.
- `daochucd.m`: combines backup, file copy, size prompts, zip/share UI, progress, cleanup and document-interaction delegate state.
- `YYYPicker.m`: UI/document-picker responsibility is narrower but remains coupled to import/export presentation; defer until after this lower-risk service extraction.

## Activation rule
Do not create `ZONAppStoreVersionChecker.*`, change PBX membership, or modify `fuhzu.m` until P47 A_customer receives an explicit real-device PASS and ROADMAP promotion state is updated.
