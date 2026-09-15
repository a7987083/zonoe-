# zonoemenu HANDOFF

## Repository / current state
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- **Promoted/device baseline remains `v1_p42`** / `e87b683a9c868e00d13582c8145bb9368878fee3`.
- P42 CI Run `34995566144`: success; real-device validation passed.
- Current development candidate: **`v1_p44` — Authorization Orchestration Boundary**.
- P44 work branch: `work/zonoemenu-v1-p44-authorization-orchestration-boundary`.
- P44 test branch: `test/zonoemenu-v1-p44-authorization-orchestration-boundary-build`.
- P44 product source: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- P44 successful CI head: `d6a110befbbc8c96dfffcae1f942c94b6011fe2d`.
- P44 CI Run `35020232205`: **success**.
- P44 device status: **pending**.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- If chat history conflicts with repository docs, use `ROADMAP.md` + `PROJECT_STATE.json` as source of truth.

## P44 — what changed
P43 selected the coherent authorization/reset block in `testmod/Bsphp/main.m` as the safest next ownership split. P44 mechanically moved that block into:
- `testmod/ZONServices/ZONAuthorizationCoordinator.h`
- `testmod/ZONServices/ZONAuthorizationCoordinator.m`

The moved implementation owns:
- original `deletekm` IMP storage;
- `ZONClearStoredUDIDState`;
- `ZONDeleteKMAndUDID`;
- `ZONInstallAuthorizationResetExtension`;
- `ZONShowCustomerStatus`;
- `ZONContinueCustomerAuthorization`;
- `ZONStartCustomerAuthorization`.

`main.m` still owns `+load`, framework preflight and the A_customer/B_debug startup split. It calls the coordinator entry points at the same original locations/order.

## P44 verification evidence
- `Tests/p44_authorization_coordinator_contract.py`: PASS; compares the moved block mechanically against P42.
- Protected runtime sources remain unchanged by contract, including `WX_NongShiFu123.mm`, `ZonoeUDIDAPI.m`, `ZONUDIDBridge.m`, Bootstrap, ModuleLoader, `PubgLoad.mm`, and `JiangHuHook.m`.
- Coordinator independent iPhoneOS compile: PASS. The isolated check keeps warnings-as-errors and suppresses only the pre-existing third-party JDStatusBarNotification `UIWindowScene` unguarded-availability warning.
- A_customer build: PASS.
- B_debug build: PASS.
- `arm64 + arm64e`: PASS.
- P44/P42 exported symbols: identical.
- P44/P42 linked load libraries: identical.

### P44 artifacts
- A_customer artifact ID: `10417242852`.
- A_customer artifact digest: `sha256:d9ce3432727b1c2ce5302ad4e732237ac7c45261ebd65cc3e7eda291ae2c71b8`.
- A_customer dylib SHA256: `f8d33f888ea5466217938af1cd338765252effb2cc4eda039a871579346e0435`.
- B_debug artifact ID: `10417212790`.
- B_debug artifact digest: `sha256:2979768f150373160bffd1bddaf45e5d1ba1ee6d9ed1c8cdc05149485abd4a78`.

## Runtime chain that must remain stable
```text
dyld
  -> testmod/Bsphp/main.m +load
     -> ZONInstallAuthorizationResetExtension()
        -> ZONAuthorizationCoordinator.m
     -> ZONBootstrapStart(...)
        -> framework preflight: AppLovinSDK / UnityFramework
        -> A_customer
           -> ZONStartCustomerAuthorization()
              -> DZUDID keychain fast path
              -> ZonoeCurrentUDID() cache path
              -> ZonoeSetUDIDCallback + ZonoeRequestUDIDIfNeeded
                 -> ZonoeUDIDAPI.m
                    -> ZONUDIDBridge.m
                    -> legacy WX_NongShiFu123 getUDID fallback if needed
              -> DZUDID write/read verification
              -> WX_NongShiFu123 loada
        -> B_debug floating entry
        -> ZONLoadBundledModules()
```

## P44 non-negotiable invariants
- Coordinator reset install remains before `ZONBootstrapStart`.
- Original `deletekm` IMP call-through occurs before extended UDID state clearing.
- Reset removes `DZUDID` and exactly the same four Zonoe defaults.
- Existing valid `DZUDID` still calls `[auth loada]` directly.
- Bridge cache still uses `ZonoeCurrentUDID()`.
- Fresh acquisition order remains status → callback registration → request.
- Callback validation, keychain write/read verification and `[auth loada]` continuation are unchanged.
- Queue behavior, status text/durations, keys, endpoints, payloads, retry/timing semantics are unchanged.
- `WX_NongShiFu123.mm` is not rewritten/split in P44.

## Known risk / current gate
CI proves source equivalence, compilation, linking, ABI surface and dependencies; it cannot prove lifecycle behavior on a real device. P44 therefore remains **unpromoted** until explicit device PASS. P42 is the rollback baseline.

## P44 real-device checklist
1. Existing valid `DZUDID`: normal startup and authorization continuation.
2. Clear authorization/UDID: Zonoe opens/returns, callback is received, `DZUDID` is written and authorization continues.
3. Clear-auth/deletekm flow: next startup really performs fresh UDID acquisition rather than restoring stale bridge state.
4. Zonoe unavailable/legacy fallback path if practical: no duplicate request, dead loop or crash; returning foreground continues normally.
5. Floating icon/menu open-close and basic feature smoke remain normal.

## Takeover rules
- Read `ROADMAP.md` first.
- Read `PROJECT_STATE.json` for exact current branch/commit/CI/device state.
- Read `KNOWN_ISSUES.md` before touching startup/auth/legacy code.
- Verify PBX membership before assuming a source is active.
- One architectural concern per version; no opportunistic cleanup.
- Source moves mechanical first, cleanup later.
- CI success never equals device promotion.

## Immediate Next Task
**Real-device validate the P44 A_customer artifact.** Do not begin P45 product changes until explicit P44 device PASS. If P44 passes, promote it and then start P45 Legacy UDID Web/Profile Fallback Adapter Boundary; if it fails, diagnose against P42 and keep P42 promoted.
