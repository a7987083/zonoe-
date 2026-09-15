# ROADMAP

> Canonical refactor plan for `zonoemenu`. This file is the source of truth for stage goals, allowed scope, forbidden scope, verification gates, status, and Next Task. Do not rely on chat history for sequencing decisions.

## Current promoted baseline
- Device-verified version: `v1_p42`.
- Runtime/source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- CI Run `34995566144`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **77**.
- Architectures: `arm64 + arm64e`.
- P42/P41 exported symbol sets and linked load-library sets are identical.
- P42 is the mandatory rollback/device baseline for every later candidate until a newer version explicitly passes its real-device gate.

## Refactor operating rules
1. One architectural concern per version. Never combine ownership cleanup with behavior, timing, threading, protocol, persistence, UI, or feature changes.
2. Every source-moving phase needs a mechanical/equivalence contract where practical.
3. Every phase must define protected files/symbols/state machines before source changes begin.
4. CI success is not device promotion. A version becomes the new baseline only after explicit real-device PASS.
5. A failed candidate does not modify the promoted fallback baseline.
6. Preserve `testmod/` + `testmod.xcodeproj` as the canonical runtime/product surface. PBX membership decides whether code is active.
7. Do not delete legacy code until active-target reachability and runtime consumers are proven absent.
8. Do not change `+load`, main-queue sequencing, callback timing, socket retry timing, URL schemes, persistence keys, or authorization continuation as part of structural cleanup.
9. Every completed development version must record branch, product commit, CI run/status, A_customer artifact, architectures, SHA256, device status, and rollback baseline.
10. `CHANGELOG_DEV.md` records what actually changed; `HANDOFF.md` records context/risks; `PROJECT_STATE.json` is machine-readable state; `KNOWN_ISSUES.md` tracks open risks.

## Completed foundation
### P41 — UDID Bridge Compilation Boundary — COMPLETED / DEVICE PASSED
- Source: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI: `34959813770` / success.
- `ZONUDIDBridge.h` became declaration-only; implementation moved to `ZONUDIDBridge.m`.
- Active Sources: 75 → 76.
- Device validation: passed; superseded by P42.

### P42 — ZonoeUDIDAPI Service Boundary — COMPLETED / CURRENT DEVICE BASELINE
- Source: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI: `34995566144` / success.
- Existing `ZonoeUDIDAPI` implementation moved mechanically from `testmod/视图菜单/NSObject+UI.m` to `testmod/ZONServices/ZonoeUDIDAPI.m`.
- Active Sources: 76 → 77; sole source addition `ZonoeUDIDAPI.m`.
- A_customer artifact: `10407391591`, digest `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- B_debug artifact: `10406554164`, digest `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.
- A_customer dylib SHA256: `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- Device validation: passed.

# Planned refactor stages

## P43 — Architecture State Refresh & Remaining Ownership Audit
**Status:** `next / planned`

### Goal
Create an up-to-date, P42-based ownership map before touching the next high-risk legacy boundary. Remove stale architectural assumptions from documentation and identify exactly which remaining responsibilities are safe to split.

### In scope
- Re-audit startup/auth/UDID/menu/module call chains from the P42 tree.
- Re-audit active PBX Sources and direct imports/callers for `main.m`, `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m` and other large legacy units.
- Update `REFACTOR_REVIEW.md` to P42 facts.
- Add machine-checkable reachability/ownership reports or tests where useful.
- Identify the single safest P44 extraction target and exact protected behavior.

### Out of scope / forbidden
- No runtime behavior change.
- No source move merely because a file looks large.
- No authorization, UDID, network, UI, persistence, timing or threading change.
- No dead-code deletion without reachability proof.

### Verification gate
- Documentation and audit output agree with PBX membership.
- No product-runtime diff unless an audit helper/test is explicitly non-product.
- CI audit job succeeds.
- Real-device gate: not required if product runtime is byte/tree unchanged; otherwise mandatory.

### Exit criteria
P44 target, allowed diff, protected files, invariants, and rollback plan are written into this ROADMAP before P44 source work begins.

---

## P44 — Authorization Orchestration Boundary
**Status:** `planned / conditional on P43 audit`

### Goal
Separate authorization orchestration from startup/UI ownership without changing the existing customer authorization sequence.

### Expected scope
- Extract only orchestration that P43 proves can be mechanically isolated from `main.m` / legacy auth implementation.
- Prefer a narrow coordinator/service translation unit with declarations in a small header.
- Keep `WX_NongShiFu123` as an implementation dependency behind the boundary rather than rewriting it.

### Protected behavior
- `main.m +load` execution timing.
- authorization-reset compatibility hook installation order.
- A_customer vs B_debug branch behavior.
- cached UDID handling.
- `ZonoeSetUDIDCallback` / request ordering.
- transition into `loada` / existing authorization continuation.
- all persistence/keychain keys and network/API semantics.

### Forbidden
- No async/sync changes.
- No queue changes.
- No retry/timeout changes.
- No API endpoint or payload changes.
- No UI changes.

### Verification gate
- Mechanical/equivalence contract for moved orchestration.
- Independent compile of new translation unit with warnings-as-errors where feasible.
- Full A_customer + B_debug arm64/arm64e builds.
- Exported symbols/load libraries compared with P42 unless an intentionally new internal symbol is hidden.
- A_customer real-device startup/auth/UDID/menu smoke before promotion.

---

## P45 — Legacy UDID Web/Profile Fallback Adapter Boundary
**Status:** `planned / conditional`

### Goal
Isolate the legacy `WX_NongShiFu123 getUDID:` fallback behind a narrow adapter so modern `ZonoeUDIDAPI` no longer directly owns legacy class details.

### Scope
- Wrap the existing fallback entry/callback only.
- Preserve `DZUDID` keychain lookup and `ZONUDIDBridgeStoreUDID` continuation exactly.
- Preserve one-in-flight guard and main-queue behavior.

### Forbidden
- No rewrite of the legacy profile/web acquisition implementation.
- No change to fallback trigger conditions.
- No change to callback semantics, keychain key, validation rules or logging-dependent behavior.

### Verification gate
- Exact fallback call/continuation contract.
- Full builds and ABI/load-library check.
- Real-device test with normal Zonoe path plus forced/unavailable fallback path.

---

## P46 — Startup Side-Effect Instrumentation & Launch Contract
**Status:** `planned`

### Goal
Measure and lock startup ordering before any later attempt to simplify global startup side effects.

### Scope
- Add non-functional timing/signpost/log instrumentation around: `+load`, authorization-reset hook install, framework preflight, Bootstrap ready callback, authorization start/ready, module scan/load, first floating entry/menu presentation.
- Produce a startup-order contract/document from device/CI evidence.

### Forbidden
- Do not move work off-main/on-main.
- Do not remove `+load`.
- Do not reorder preflight/bootstrap/auth/module loading.
- Do not optimize timeouts or delays in this phase.

### Verification gate
- A/B builds.
- No semantic product-path diff beyond instrumentation.
- Real-device startup sequence captured at least once on A_customer.

### Exit criteria
Only measured evidence may justify a later startup-behavior refactor. If evidence is insufficient, startup timing remains protected indefinitely.

---

## P47 — Repository Hygiene / Generated Artifact Cleanup
**Status:** `planned`

### Goal
Reduce repository noise without changing runtime or build outputs.

### Scope
- Audit generated/package binaries, user-specific Xcode state, reproducible artifacts and stale non-runtime material.
- Extend `.gitignore` where safe.
- Remove only files proven not to be build/release/runtime inputs.

### Forbidden
- Do not combine with source refactors.
- Do not delete vendor/dependency material required by bootstrap scripts or CI.
- Do not delete any file referenced by PBX, scripts, release packaging or runtime loaders.

### Verification gate
- Before/after active PBX source set identical.
- Build scripts and dependency bootstrap succeed.
- A_customer/B_debug dylibs are byte-identical when the build environment is deterministic; otherwise exported symbols, load libraries and source inputs must match.
- Device test not required if binaries are proven identical; otherwise required.

---

## P48 — Legacy God-Object Split #1
**Status:** `planned / target chosen only by P43 evidence`

### Goal
Split exactly one large legacy unit with the best risk/reward ratio. Candidate list includes `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m`, `fuhzu.m`; P43 decides the target.

### Scope
- One responsibility only: e.g. persistence adapter, UI helper, dispatch adapter, or service adapter.
- Move existing code mechanically before any cleanup/renaming.

### Forbidden
- No simultaneous redesign of the selected legacy unit.
- No multiple god-object splits in one version.
- No behavior simplification based on assumptions.

### Verification gate
- Target-specific body/invariant contract.
- Full A/B builds.
- Relevant real-device feature path plus common menu/startup smoke.

---

## P49 — Active Target / Dead Code / Dependency Audit
**Status:** `planned`

### Goal
Recompute the active runtime surface after the boundary work and remove only proven-unused code/dependencies.

### Scope
- PBX active source inventory.
- import/caller/reference audit.
- unique-selector/symbol checks for removal candidates.
- JDStatusBarNotification and other retained third-party/legacy dependencies may be re-audited only if call reachability changed.

### Forbidden
- No deletion based only on search absence in one path.
- No behavior changes bundled with removal.

### Verification gate
- Explicit removal proof per file/dependency.
- Full A/B build.
- Export/load-library comparison.
- Real-device smoke for any runtime-linked removal.

---

## P50 — Refactor Stabilization / Architecture Freeze
**Status:** `planned`

### Goal
Consolidate the proven architecture after P43–P49, update documentation/contracts, and stop structural churn unless a concrete maintenance or feature need justifies more change.

### Scope
- Re-run architecture audit.
- Ensure declarations/implementations have clear owners.
- Ensure documentation matches active target.
- Retire obsolete audit helpers only if their invariant has permanent replacement coverage.
- Produce final source/feature/dependency inventory.

### Verification gate
- Full CI, A/B arm64+arm64e artifacts, ABI/load-library review.
- Full real-device regression using the current device matrix.
- Promote only after explicit user PASS.

# Protected behavior across all planned stages
Until a stage explicitly says otherwise and proves the change independently, keep unchanged:
- `main.m +load` timing and Bootstrap/authorization sequencing.
- authorization-reset compatibility behavior.
- Zonoe callback scheme/host, nonce generation/validation, callback parsing and storage keys.
- localhost bridge port, socket timeout, retry count/delay, pending-request age and request throttle.
- `zonoe://udid` preferred path and legacy web/profile fallback.
- `DZUDID` keychain semantics.
- floating entry/menu stack and active features.
- cloud save, local files, backup/restore, clear-data and clear-auth paths.
- module discovery directories, containment checks, ABI checks and `dlopen` behavior.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime behavior.

# Universal promotion checklist
For each runtime-affecting candidate:
1. Product diff is limited to the phase-declared scope.
2. Contract/static tests pass.
3. New translation units independently compile where applicable.
4. A_customer and B_debug build successfully for `arm64 + arm64e`.
5. Export surface and linked libraries are compared against the promoted baseline.
6. A_customer artifact ID/digest and dylib SHA256 are recorded.
7. Required real-device checklist passes.
8. Only then update `last_device_verified_*` and promote the version.

# Next Task
Start **P43 — Architecture State Refresh & Remaining Ownership Audit** from the promoted P42 baseline. First action: refresh `REFACTOR_REVIEW.md` from the actual P42 tree and active PBX membership, then choose exactly one P44 authorization-orchestration extraction target. Do not modify product runtime during the audit unless the ROADMAP is first amended with an explicit isolated scope and verification gate.
