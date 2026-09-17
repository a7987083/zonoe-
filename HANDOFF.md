# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read `ROADMAP.md` first and `PROJECT_STATE.json` second. If chat history conflicts with them, repository docs win.

## Current promoted baseline
- Version: `v1_p48_1`.
- Product source: `71eddfa0600112aa56a8bef45013d73f4673794a`.
- Work branch: `work/zonoemenu-v1-p48-storekit-cleanup`.
- Test branch: `test/zonoemenu-v1-p48-storekit-cleanup-build`.
- CI head: `efabe050194b87518c1442b4fe078ed7283db846`.
- CI Run `35180342515`: **success**.
- Real-device validation: **passed, explicitly reported by user**.
- Active Sources: **78**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10480455519`, digest `sha256:beb2e1dd9b0b6ad913b5dc00911a890fd33293f9f33204196266474909b47dfe`.
- A_customer dylib SHA256: `36bbe4c32882d98b274fb7cfb40bf62f727502b4867765bee1f747c0e5fbe90d`.
- B_debug artifact: `10480331340`, digest `sha256:fb21abd689eee241ae9331e24558756a342fd50a766fd8d4740bab5fde615e8e`.
- P48.1 is the rollback/device baseline until a later candidate explicitly passes its real-device gate.

## P48.1 change
- Removed residual StoreKit/App Store presentation code from `YYYPicker`.
- Preserved restore-save/import behavior.
- PBX did not change versus P48.
- Exported symbols are identical to P48.
- Load libraries are identical to P48 except `StoreKit.framework` is deliberately absent.

## Runtime chain to preserve
```text
dyld
  -> main.m +load
     -> authorization reset install
     -> ZONBootstrapStart
        -> AppLovinSDK / UnityFramework preflight
        -> A_customer authorization or B_debug floating entry
        -> ZONLoadBundledModules
           -> module directory scan / dlopen
        -> bootstrap ready
  -> floating entry/menu lifecycle
```

## Takeover rules
- Never optimize startup timing based only on source inspection; use device trace evidence first.
- Do not change `+load`, queues, timeouts, retries, callback order or module loading timing during structural cleanup.
- Verify PBX membership and repository/runtime reachability before deleting or moving code.
- One architectural concern per version.
- CI success never equals device promotion.
- Historical audit/CI material is not dead merely because it is old.

## Immediate Next Task
P49 — Active Target / Dead Code / Dependency Audit. Recompute the active PBX/build/framework/dependency surface from P48.1 and produce evidence before deleting anything. Compare all candidate changes against P48.1.
