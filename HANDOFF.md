# zonoemenu HANDOFF

## Repository / current baseline
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Current test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- Current promoted version: `v1_p42`.
- Promoted/device baseline source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI Run `34995566144`: success.
- Real-device validation: explicitly reported normal by user.
- Active PBX Sources: 77.
- Architectures: arm64 + arm64e.
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

## Runtime call chain that must remain stable
```text
dyld
  -> testmod/Bsphp/main.m +load
     -> authorization reset compatibility hook
     -> ZONBootstrapStart(...)
        -> A_customer authorization startup
           -> ZonoeUDIDAPI.h
              -> ZonoeUDIDAPI.m
                 -> ZONUDIDBridge.h
                    -> ZONUDIDBridge.m
                       -> zonoe://udid callback + nonce
                       -> localhost bridge polling
                       -> NSUserDefaults bridge cache
                 -> legacy WX_NongShiFu123 web/profile fallback when needed
           -> authorization continuation
        -> B_debug floating entry
        -> ZONLoadBundledModules()
```

## Non-negotiable protected behavior
Unless a ROADMAP phase explicitly authorizes and separately proves otherwise, preserve:
- `main.m +load` timing and startup order.
- authorization-reset compatibility hook behavior.
- A_customer/B_debug variant split.
- Zonoe scheme/host/nonce/callback parsing/storage semantics.
- localhost bridge port/timeouts/retry/delay/pending-age/request-throttle values.
- `DZUDID` keychain semantics.
- legacy `WX_NongShiFu123` fallback trigger and continuation behavior.
- floating/menu UI and active features.
- cloud save/local files/backup-restore/clear-data/clear-auth paths.
- module-loader directories, containment checks, ABI rules and `dlopen` behavior.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime behavior.

## Refactor sequence after P42
The full goals/scope/forbidden changes/gates are in `ROADMAP.md`. Sequence:
1. **P43** — Architecture State Refresh & Remaining Ownership Audit.
2. **P44** — Authorization Orchestration Boundary.
3. **P45** — Legacy UDID Web/Profile Fallback Adapter Boundary.
4. **P46** — Startup Side-Effect Instrumentation & Launch Contract.
5. **P47** — Repository Hygiene / Generated Artifact Cleanup.
6. **P48** — Legacy God-Object Split #1, target selected only by P43 evidence.
7. **P49** — Active Target / Dead Code / Dependency Audit.
8. **P50** — Refactor Stabilization / Architecture Freeze.

## Takeover rules
- Do not invent the next phase from memory; read `ROADMAP.md` first.
- Read `PROJECT_STATE.json` for current branch/commit/CI/device status before modifying source.
- Read `KNOWN_ISSUES.md` before selecting a risky boundary.
- Read `CHANGELOG_DEV.md` to distinguish planned work from completed work.
- Verify PBX membership before assuming a same-named source file is active.
- One architectural concern per version; no opportunistic cleanup.
- A source move should be mechanical first, cleanup later.
- CI success alone never promotes a candidate.
- Keep P42 as rollback/device baseline until a later candidate explicitly passes real-device validation.

## Immediate Next Task
Start P43. Refresh `REFACTOR_REVIEW.md` from the actual P42 tree and active PBX membership, audit remaining ownership/reachability, and select exactly one P44 authorization-orchestration extraction target. P43 is audit-first; do not modify product runtime merely to make the architecture look cleaner.
