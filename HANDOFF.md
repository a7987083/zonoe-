# zonoemenu HANDOFF

## Repository / current baseline
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current promoted/device version: `v1_p42`.
- Promoted/device baseline source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- P42 CI Run `34995566144`: success.
- P42 real-device validation: explicitly reported normal by user.
- Active PBX Sources: 77.
- Architectures: arm64 + arm64e.
- Current audit work branch: `work/zonoemenu-v1-p43-architecture-audit`.
- Current audit test branch: `test/zonoemenu-v1-p43-architecture-audit`.
- P43 audit head: `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`.
- P43 CI Run `35001000784`: success.
- **Canonical future refactor sequence is defined in `ROADMAP.md`. If chat history conflicts with repository docs, use `ROADMAP.md` + `PROJECT_STATE.json` as the source of truth.**

## P41 — UDID Bridge Boundary
- Source: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI Run `34959813770`: success.
- Device validation: passed, then superseded by P42.
- `ZONUDIDBridge.h` is declaration-only; `ZONUDIDBridge.m` owns implementation.
- Active Sources: 75 → 76.

## P42 — Zonoe UDID API Boundary
- Product source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Test-only contract unicode-path fix: `698bd84d676107f65ae14d6b2041805948001674`.
- CI Run `34995566144`: success.
- `testmod/ZONServices/ZonoeUDIDAPI.m` owns the stable public Zonoe UDID API implementation.
- `testmod/视图菜单/NSObject+UI.m` no longer owns UDID callback/fallback state.
- PBX source delta from P41 is exactly `ZonoeUDIDAPI.m`; active Sources 76 → 77.
- Exact mechanical migration contract passed.
- Independent iPhoneOS compile with `-Wall -Wextra -Werror` passed.
- A_customer/B_debug full builds passed for arm64 + arm64e.
- Exported symbol set and linked load-library set are identical to P41.

### P42 artifacts
- A_customer artifact: `10407391591`.
- A_customer artifact digest: `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- A_customer dylib SHA256: `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- B_debug artifact: `10406554164`.
- B_debug artifact digest: `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.

## P43 — Architecture State Refresh & Remaining Ownership Audit
- Work branch: `work/zonoemenu-v1-p43-architecture-audit`.
- Test branch: `test/zonoemenu-v1-p43-architecture-audit`.
- Audit head: `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`.
- CI Run `35001000784`: **success**.
- P43 is audit-only. `testmod/` + `testmod.xcodeproj` are tree-identical to P42 product source.
- Active Sources remain exactly **77**.
- No real-device test is required for P43 because the product runtime is unchanged.
- Detailed audit: `P43_ARCHITECTURE_AUDIT.md`.

### P43 ownership result
`testmod/Bsphp/main.m` currently mixes startup hosting with a coherent authorization/reset helper block. P43 selected that helper block as the safest P44 extraction target.

P44 selected functions/state:
- `gZONOriginalDeleteKM`;
- `ZONClearStoredUDIDState`;
- `ZONDeleteKMAndUDID`;
- `ZONInstallAuthorizationResetExtension`;
- `ZONShowCustomerStatus`;
- `ZONContinueCustomerAuthorization`;
- `ZONStartCustomerAuthorization`.

Planned P44 boundary:
- `testmod/ZONServices/ZONAuthorizationCoordinator.h`;
- `testmod/ZONServices/ZONAuthorizationCoordinator.m`.

`main.m` must remain the `+load` startup host. P44 must not rewrite `WX_NongShiFu123.mm`.

## Runtime call chain that must remain stable
```text
dyld
  -> testmod/Bsphp/main.m +load
     -> authorization reset compatibility install
     -> ZONBootstrapStart(...)
        -> framework preflight: AppLovinSDK / UnityFramework
        -> A_customer authorization startup
           -> authorization coordinator (planned P44 ownership only; same behavior)
              -> DZUDID keychain fast path
              -> ZonoeUDIDAPI.m
                 -> ZONUDIDBridge.m
                    -> zonoe://udid callback + nonce
                    -> localhost bridge polling
                    -> NSUserDefaults bridge cache
                 -> legacy WX_NongShiFu123 web/profile fallback when needed
              -> WX_NongShiFu123 loada continuation
        -> B_debug floating entry
        -> ZONLoadBundledModules()
```

## P44 non-negotiable invariants
- `ZONInstallAuthorizationResetExtension` remains before `ZONBootstrapStart`.
- Original `deletekm` IMP is invoked before extended UDID state clearing.
- Reset still removes `DZUDID` and exactly these defaults: `zonoe.udid.bridge.value`, `zonoe.udid.bridge.scheme`, `zonoe.udid.bridge.requestTimestamp`, `zonoe.udid.bridge.requestNonce`.
- Existing valid `DZUDID` still goes directly to `[auth loada]`.
- Bridge cache still uses `ZonoeCurrentUDID()`.
- Fresh acquisition order remains status -> `ZonoeSetUDIDCallback` -> `ZonoeRequestUDIDIfNeeded`.
- Callback validation, keychain write/read verification and `[auth loada]` continuation remain unchanged.
- Queue behavior, status text/durations, persistence keys, endpoints, payloads and retry/timing semantics remain unchanged.
- `main.m +load`, framework preflight and A_customer/B_debug branch timing remain unchanged.
- `WX_NongShiFu123.mm`, `ZONUDIDBridge.m`, `ZonoeUDIDAPI.m`, menu, hooks and unrelated product runtime remain protected.

## Legacy risk map
- `WX_NongShiFu123.mm`: active, high-risk god object spanning authorization, network, UDID/IDFV, activation UI and status flows. Do not split in P44.
- `PubgLoad.mm`: active broad file/download/config/UI surface. Not P44.
- `JiangHuHook.m`: active CaptainHook runtime surface affecting menu lifecycle, StoreKit and ad/video behavior. Protected.
- `daochucd.m`, `YYYPicker.m`, `fuhzu.m`: active legacy candidates; defer any split/removal to later evidence-driven stages.

## Takeover rules
- Read `ROADMAP.md` first; it is the phase/source-of-truth document.
- Read `PROJECT_STATE.json` for current branch/CI/device state.
- Read `P43_ARCHITECTURE_AUDIT.md` before implementing P44.
- Read `KNOWN_ISSUES.md` before touching startup/auth/legacy code.
- Verify PBX membership before assuming a same-named file is active.
- One architectural concern per version; no opportunistic cleanup.
- Source moves are mechanical first, cleanup later.
- CI success alone never promotes a runtime candidate.
- Keep P42 as rollback/device baseline until P44 explicitly passes real-device validation.

## Immediate Next Task
Start **P44 — Authorization Orchestration Boundary**. Mechanically move only the selected static authorization/reset helper block from `testmod/Bsphp/main.m` into `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m`, register exactly one new active `.m` source (expected 77 → 78), preserve `main.m +load` and all protected behavior, add extraction/protected-source contracts, build A_customer and B_debug for arm64 + arm64e, compare exports/load libraries against P42, then request A_customer real-device validation.
