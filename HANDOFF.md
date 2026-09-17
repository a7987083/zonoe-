# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read `ROADMAP.md`, `PROJECT_STATE.json`, `P50_ARCHITECTURE_FREEZE.md`, then `P50_FINAL_STATUS_MATRIX.md`.

## Current promoted runtime baseline
- Version: `v1_p49`.
- Product source: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- CI Run `35195152912`: success.
- Real-device validation: passed, explicitly reported by user.
- Active Sources: 78.
- Architectures: `arm64 + arm64e`.
- A_customer artifact: `10485344383`, digest `sha256:33ae7fda25128e9d0bd6a167a82aedaf3a1272a8ceb13111bef23c58ff270c5d`.
- A_customer dylib SHA256: `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- B_debug artifact: `10485622521`, digest `sha256:9156b57fd832461274f3c8d1625c8b8213d556c9862b32d1d461294783a23e27`.
- P49 remains the rollback/device baseline.

## P50 completion
- Branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- P50 is completed as a documentation/contract/CI freeze stage.
- Runtime/product surface remains identical to P49.
- Freeze contract: `P50_ARCHITECTURE_FREEZE.md`.
- Final matrix: `P50_FINAL_STATUS_MATRIX.md`.
- Static contract: `Tests/p50_architecture_freeze_contract.py`.
- CI gate: `.github/workflows/p50-architecture-freeze.yml`.

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

## Takeover rules
- Do not reopen core refactoring automatically; P41-P50 structural work is closed.
- New menu UI must stay presentation-only and consume Registry/Dispatcher.
- Startup/bootstrap, authorization/UDID, module-loader ordering, persistence/save semantics and destructive-data behavior require dedicated stages if changed.
- Active source/framework dependency changes require reachability evidence, dual-variant CI and the normal promotion gate.
- CI success does not equal real-device promotion for runtime candidates.

## Immediate Next Task
There is no automatic P51 refactor. Start the next branch only for a concrete product requirement. If the next requirement is the menu redesign, create a UI-only stage from the P49/P50 frozen baseline and keep all underlying business/runtime boundaries unchanged.
