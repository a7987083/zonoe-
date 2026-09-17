# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read `ROADMAP.md`, `PROJECT_STATE.json`, then `P50_ARCHITECTURE_FREEZE.md`.

## Current promoted runtime baseline
- Version: `v1_p49`.
- Product source: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- CI Run `35195152912`: **success**.
- Real-device validation: **passed, explicitly reported by user**.
- Active Sources: **78**.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10485344383`, digest `sha256:33ae7fda25128e9d0bd6a167a82aedaf3a1272a8ceb13111bef23c58ff270c5d`.
- A_customer dylib SHA256: `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- B_debug artifact: `10485622521`, digest `sha256:9156b57fd832461274f3c8d1625c8b8213d556c9862b32d1d461294783a23e27`.
- P49 is the rollback/device baseline.

## P49 change
- Removed proven-unused `Network.framework` from PBX.
- Active Sources remain 78.
- A_customer/B_debug builds passed.
- Exported symbols are identical to P48.1.
- Load libraries are identical to P48.1 except `Network.framework` is absent.
- User reported startup, authorization, menu, save/network smoke normal on device.

## P50 state
- Work branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- P50 is a stabilization/freeze stage; **no runtime behavior change is intended**.
- Contract: `P50_ARCHITECTURE_FREEZE.md`.
- Static gate: `Tests/p50_architecture_freeze_contract.py`.
- CI gate: `.github/workflows/p50-architecture-freeze.yml`.
- P50 must keep `testmod/` + `testmod.xcodeproj` identical to promoted P49.

## Frozen runtime chain
```text
dyld
  -> main.m +load
     -> authorization reset install
     -> ZONBootstrapStart
        -> preflight
        -> A_customer authorization or B_debug floating entry
        -> ZONLoadBundledModules
           -> module directory scan / dlopen
        -> bootstrap ready
  -> floating entry/menu lifecycle
```

## Frozen ownership rules
- Startup/bootstrap responsibilities stay in their current boundary.
- Authorization/UDID stays behind Coordinator/API/Bridge/Fallback Adapter.
- Menu/UI consumes Registry/Dispatcher; new UI must not directly couple to legacy feature implementations.
- Module discovery/load ordering remains unchanged without a dedicated stage.
- Save/restore/cloud-save and persistence semantics remain unchanged without a dedicated stage.
- Active dependency/source deletion requires a new reachability audit and promotion gate.

## Immediate Next Task
Finish P50 contract CI and canonical documentation synchronization. Do not modify runtime/product files during P50.
