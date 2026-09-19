# P65 — P62 Codebase Review / Behavior-Preserving Refactor

## Baseline
- Repository: `a7987083/zonoe-`
- Stable runtime baseline: `v1_p62`
- P62 runtime/source commit: `a11160e70ff1163b2c462bb3ef5d539da1f489eb`
- P62 CI head: `c1f1415d3787b879def387d68e2df089776dbffa`
- P62 CI Run: `35410564486` — success
- P62 real-device status: passed, reported by user and recorded in `PROJECT_STATE.json`
- Canonical runtime surface: `testmod/` + `testmod.xcodeproj`
- Active PBX Sources: 78
- Architectures: arm64 + arm64e

P63/P64 offline-authorization experiments remain abandoned/reverted and are outside this refactor.

## Architecture summary

### Startup / authorization
```text
dyld loads testmod.dylib
  -> testmod/Bsphp/main.m +load
     -> ZONInstallAuthorizationResetExtension()
     -> ZONBootstrapStart(preflight, ready)
        -> preflight: AppLovinSDK / UnityFramework dynamic load
        -> main-queue variant entry
           -> B_debug: floating menu entry
           -> A_customer: ZONStartCustomerAuthorization()
              -> existing DZUDID keychain state
              -> ZonoeUDIDAPI bridge cache / callback
              -> legacy fallback adapter when required
              -> WX_NongShiFu123::loada
                 -> BSPHP / BSPHPy authorization modes
                 -> NetTool / server configuration / activation UI
        -> ZONLoadBundledModules()
```

### Menu / feature flow
```text
NSObject+UI floating entry
  -> PopupMenuVC compatibility shell
     -> ZONMenuCoordinator / renderers
        -> ZONFeatureRegistry (metadata/source of truth)
        -> ZONMenuEventBridge
           -> ZONFeatureDispatcher
              -> existing legacy handlers
              -> NSUserDefaults / ImgTool state
              -> backup / restore / destructive-data flows
```

### Extension module flow
```text
ZONBootstrap
  -> ZONModuleLoader
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted dylib scan
     -> path containment check
     -> dlopen(RTLD_NOW | RTLD_LOCAL)
     -> ABI / identifier / initialize exports
     -> ZONHostAPI
```

### Identity persistence flow
```text
DZUDID keychain
  <-> ZONAuthorizationCoordinator
      -> ZonoeUDIDAPI
         -> ZONUDIDBridge
            -> zonoe:// callback + nonce
            -> localhost bridge/cache
      -> WX_NongShiFu123::loada
```

## Priority findings

### P0 — `WX_NongShiFu123.mm` remains the principal god object
Verified responsibilities include authorization-mode selection, network reachability, HTTP initialization, server configuration parsing, activation UI, keychain-driven branching and retry presentation. Global process state is also stored beside those responsibilities.

Risk: unrelated changes can alter authorization timing, UI lifecycle, retry mode, global state or server parsing.

Plan: split only one responsibility per stage, with P62 behavior contracts and dual-variant build/device gates.

### P0 — project state documentation is inconsistent
`PROJECT_STATE.json` correctly records P62, while older `ROADMAP.md`, `HANDOFF.md`, `ARCHITECTURE.md` and `KNOWN_ISSUES.md` still describe earlier baselines.

Risk: future maintainers can resume from a superseded baseline or reintroduce abandoned P63/P64 work.

Plan: make P62 the canonical documented rollback baseline before P65 promotion.

### P1 — server configuration parsing trusts array shape
`getXinxi:` splits server strings and immediately indexes `arr[0]...arr[7]` and `arr2[0]...arr2[7]` without proving element counts.

Risk: malformed/truncated server responses can raise Objective-C range exceptions.

Plan: dedicated parsing-safety stage with fixture tests. Do not fold this semantic error-handling change into P65.

### P1 — reachability helper has defensive gaps
`getNet` creates an `SCNetworkReachabilityRef`, then gets flags/releases it without an explicit NULL guard.

Risk: allocation/setup failure can become a crash instead of a clean offline result.

Plan: dedicated network-hardening stage; preserve P62 retry UX.

### P1 — destructive clear-data sequencing is race-prone
`ZONClearGameDataPreservingTmp()` schedules deletion work for +5s and independently schedules `exit(0)` for the same +5s deadline.

Risk: queue ordering currently decides whether all deletion work completes before process exit.

Plan: dedicated behavior-fix stage where exit is chained after deletion completion and covered by filesystem tests/device validation.

### P1 — startup remains order-sensitive
`main.m +load`, dynamic framework preflight, customer authorization and module loading are deliberately ordered. `ZONBootstrap` runs module scanning/loading on the main-queue ready path.

Risk: broad cleanup or async conversion can change launch behavior.

Plan: preserve ordering until timing measurements justify a dedicated startup-performance stage.

### P2 — `ZONLaunchTrace.h` is implementation-heavy
The header contains event mapping, uptime calculation, log singleton and signpost emission as static inline implementation.

Risk: compile-time coupling and duplicated inline implementation across translation units; not currently a proven runtime defect.

Plan: lower priority than authorization/data-safety work.

### P2 — dispatcher still imports legacy business implementations directly
`ZONFeatureDispatcher.m` correctly centralizes routes but remains coupled to `PubgLoad`, `daochucd`, `YYYPicker`, `ImgTool` and `WX_NongShiFu123`.

Risk: the Registry/Dispatcher boundary is stable, but implementation replacement remains expensive.

Plan: migrate one route family at a time behind stable service protocols/functions.

## P65 implemented refactor

Scope is intentionally narrow and mechanically reviewable:

- Only runtime source changed: `testmod/ZONServices/ZONAuthorizationCoordinator.m`.
- Centralized `DZUDID` and bridge-cache key ownership into private constants.
- Centralized UDID validity check.
- Centralized keychain read and write-then-verify behavior.
- Kept reset hook, callback order, trace events, status text and `loada` continuation unchanged.
- Did not modify `WX_NongShiFu123.mm`, startup ordering, menu, storage, module loader, hooks or Xcode target membership.

## Behavior-preservation gates

`Tests/p65_p62_maintainability_refactor_contract.py` locks:
- P65 version identity.
- authorization reset method hook.
- P62 trace events.
- existing DZUDID fast path.
- bridge-cache path.
- Zonoe callback/request path.
- `loada` continuation.
- exact user-visible UDID status strings.
- unchanged persistence key strings.
- a single centralized keychain write/clear path.

CI additionally requires:
- runtime diff vs P62 source commit contains exactly `ZONAuthorizationCoordinator.m`;
- PBX active source count remains 78;
- A_customer and B_debug both build with Xcode 16.4;
- arm64 + arm64e are present;
- exported symbols match P62 artifacts;
- linked libraries match P62 artifacts.

Real-device promotion is still required after CI success.

## Staged refactor plan

1. **P65 — Authorization coordinator state cleanup**: behavior-preserving helper/constants refactor. CI + real-device gate.
2. **P66 — Authorization retry ownership extraction**: move P62 retry presentation/mode ownership out of the god object without changing UI or retry target.
3. **P67 — Authorization response parsing safety**: parse/validate server configuration before assignment; add malformed/truncated response fixtures.
4. **P68 — Authorization networking boundary**: isolate reachability/request failures and retry policy; remove hidden global ownership only after equivalence tests.
5. **P69 — Destructive-data sequencing**: serialize clear-data completion before exit; filesystem fixture tests + device gate.
6. **P70 — Legacy authorization decomposition**: progressively split activation UI, server/config state and credential operations from `WX_NongShiFu123`.
7. **Later measured performance stage**: evaluate main-thread module scanning/framework preflight using existing launch trace before changing timing.

## Refactor rules
- One responsibility per runtime stage.
- No P63/P64 offline mode resurrection.
- No opportunistic hook/patch cleanup.
- No source/framework deletion without PBX/import/runtime evidence.
- CI success is not device promotion.
- Keep a P62 rollback path until a later candidate passes its device gate.
