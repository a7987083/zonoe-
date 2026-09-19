# ROADMAP

> Canonical stage plan for `zonoemenu`. Runtime changes are promoted only after scoped CI and required real-device validation.

## Current promoted runtime baseline
- Version: `v1_p62`.
- Runtime/source commit: `a11160e70ff1163b2c462bb3ef5d539da1f489eb`.
- Test/CI head: `c1f1415d3787b879def387d68e2df089776dbffa`.
- CI Run `35410564486`: **success**.
- Real-device regression: **passed**, explicitly reported by user.
- Active PBX Sources: **78**.
- Architectures: `arm64 + arm64e`.
- P62 remains the rollback baseline until a later candidate passes its own device gate.

## P63 / P64 — Offline authorization experiments — ABANDONED / REVERTED
- P63 offline authorization mode failed device behavior because authorization still fell back to forced network retry.
- P64 follow-up preroute work was abandoned before promotion.
- Do not reintroduce either path unless explicitly requested as a new product requirement.

## P65 — P62 Codebase Review / Authorization Coordinator Maintainability — CI PASSED / DEVICE PENDING
### Scope
- Review the current P62 architecture and data flows before further structural work.
- Keep P62 runtime behavior intact.
- Change only `testmod/ZONServices/ZONAuthorizationCoordinator.m` in the runtime surface.
- Centralize DZUDID/bridge persistence keys, UDID validity and write-verification helpers.

### Verification
- Work branch: `work/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test branch: `test/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test head: `f5742ed68489b529169c850619cb9e1036150920`.
- CI Run `35424279529`: **success**.
- Contract: PASS.
- A_customer: PASS.
- B_debug: PASS.
- `arm64 + arm64e`: PASS.
- Exported symbols vs P62: identical.
- Linked libraries vs P62: identical.
- Active Sources: 78.
- Real-device promotion: **pending**.

### Review artifact
- `P65_CODEBASE_REVIEW.md`

## Planned staged refactor sequence

### P66 — Authorization retry ownership extraction
Move the P62 network-retry presentation/mode ownership out of `WX_NongShiFu123.mm` while preserving exact retry UI, retry target and timing. No offline mode.

### P67 — Authorization response parsing safety
Validate server response shape before indexing global configuration arrays. Add malformed/truncated fixture tests. Preserve valid-response behavior.

### P68 — Authorization networking boundary
Isolate reachability/request-failure handling and reduce hidden mutable ownership. Keep P62 retry UX and server protocol unchanged.

### P69 — Destructive-data sequencing
Make clear-data completion precede process exit deterministically. Treat this as a behavior-fix stage with filesystem tests and device validation.

### P70 — Legacy authorization decomposition
Progressively split activation UI, server/config state and credential operations from `WX_NongShiFu123` one responsibility per stage. Do not delete the legacy object until reachability/caller/runtime evidence proves it safe.

### Later measured performance stage
Use existing launch trace/signpost evidence before changing framework preflight, module scan/load timing or main-thread ownership.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are the canonical runtime/product surface.
2. Registry/Dispatcher remains the menu execution boundary.
3. Startup `+load`, Bootstrap ordering, authorization/UDID continuation, module-loader order, persistence semantics and destructive-data behavior require dedicated stages if changed.
4. Active source/framework additions or deletions require PBX/import/runtime evidence.
5. Every runtime candidate must build A_customer + B_debug for arm64 + arm64e and compare ABI/load libraries with the promoted baseline.
6. CI success does not equal real-device promotion.
7. No opportunistic multi-file redesign of legacy god objects.

## Completed foundation
- P41 — UDID Bridge Compilation Boundary: device passed.
- P42 — ZonoeUDIDAPI Service Boundary: device passed.
- P43 — Architecture State Refresh & Ownership Audit: completed.
- P44 — Authorization Orchestration Boundary: device passed.
- P45 — Legacy UDID fallback adapter boundary: CI verified/covered by later baselines.
- P46 — Startup side-effect instrumentation & launch contract: CI verified/covered by later baselines.
- P47 — Repository hygiene: completed.
- P48 / P48.1 — App Store / StoreKit cleanup: device passed.
- P49 — Active target/dependency audit: device passed.
- P50 — Architecture freeze: completed.
- P51 / P51-B — Feature execution and backup refactor: device passed.
- P62 — Unified authorization network retry: device passed/current promoted runtime baseline.

# Next Task
Run P65 real-device regression against the same A_customer behavior covered by P62. If normal, promote P65 and start P66 from that promoted baseline. If not, roll back to P62 and record the first observed behavioral delta before any further refactor.
