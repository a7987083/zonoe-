# P40 Architecture / Refactor Review

## Review baseline

- Repository: `a7987083/zonoe-`
- Canonical product surface: `testmod/` + `testmod.xcodeproj`
- Promoted device-verified baseline: `v1_p39`
- P39 runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`
- P39 active PBX Sources: **75**
- Active product features: **9**
- P40 phase-1 runtime/source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`

This review treats startup ordering, Objective-C `+load`, CaptainHook constructors, method replacement, fishhook/rebind, authorization/UDID, menu, file/cloud and runtime-hook chains as protected behavior until an isolated proof says otherwise.

## Architecture summary

### 1. Startup / bootstrap

```text
dyld loads testmod.dylib
  -> testmod/Bsphp/main.m +load
     -> install authorization-reset method replacement
     -> ZONBootstrapStart(preflight, ready)
        -> synchronous framework preflight
           -> AppLovinSDK dlopen when present
           -> UnityFramework dlopen when present
        -> main queue variant entry
           -> A_customer
              -> customer status notification
              -> DZUDID / Zonoe UDID acquisition
              -> WX_NongShiFu123 loada authorization
           -> B_debug
              -> floating menu entry
        -> ZONLoadBundledModules()
```

`main.m` is still the process-level compatibility adapter. Its `+load` timing is part of current behavior and must not be casually moved to application lifecycle callbacks.

### 2. Menu / feature data flow

```text
NSObject+UI 显示图标
  -> JHDragView
     -> vip菜单显示
        -> PopupMenuVC
           -> ZONMenuCoordinator
              -> panel/chrome/section renderers
                 -> ZONFeatureRegistry (9 built-ins)
                 -> ZONFeatureRenderer
              -> ZONMenuEventBridge
                 -> ZONFeatureDispatcher
                    -> legacy business handlers
```

`PopupMenuVC` is now a compatibility shell. `ZONMenuCoordinator` owns menu lifecycle; renderers own UI composition; `ZONFeatureRegistry` owns feature metadata; `ZONMenuEventBridge` translates UIKit events; `ZONFeatureDispatcher` routes to the existing business implementations.

### 3. Active feature routing

| Feature | Legacy tag | Runtime destination |
| --- | ---: | --- |
| Remote download | 1 | `PubgLoad yuanchengdwon` |
| VIP cloud save | 2 | `ZONEnsureTmpDirectory` -> `PubgLoad checkCloudSaveStatus` |
| Local files | 3 | `SandboxBrowserVC` |
| Backup save | 100 | `daochucd backupasd` |
| Restore save | 101 | `YYYPicker addBtnAction` |
| Clear game data | 102 | confirmation -> protected cleanup flow |
| Clear authorization | 103 | confirmation -> `WX_NongShiFu123 deletekm` |
| IAP/no-ads | 201 | NSUserDefaults -> `ImgTool.NeiGou` -> runtime hooks |
| Ad speed | 202 | NSUserDefaults -> `ImgTool.ADSpeed/ADBiansu` -> runtime hooks |

### 4. UDID / authorization data flow

```text
main.m
  -> ZonoeUDIDAPI public C interface
     -> implementation currently inside NSObject+UI.m
        -> ZONUDIDBridge.h implementation
           -> callback scheme + nonce
           -> zonoe://udid request
           -> localhost result polling
           -> bridge NSUserDefaults cache
        -> if zonoe open fails
           -> WX_NongShiFu123 getUDID legacy web/profile flow
        -> DZUDID keychain
        -> authorization loada
```

The public API and lower-level bridge are conceptually services, but their implementation ownership is still mixed with the UI category and an implementation-heavy header.

### 5. Cloud/save flow

```text
menu tag 2
  -> ZONFeatureDispatcher
     -> ensure sandbox tmp directory
     -> PubgLoad checkCloudSaveStatus
        -> authorization/purchase check
        -> JDStatusBarNotification: preparing download
        -> NSURLSession download
           -> didWriteData: update status text + progress bar
        -> archive/load flow
```

`JDStatusBarNotification` is a proven live dependency. It also serves startup/UDID and authorization notifications and must remain protected.

### 6. Runtime hooks

```text
menu runtime toggles
  -> NSUserDefaults + ImgTool runtime state
     -> JiangHuHook / HookClass / provider-specific hook code
        -> StoreKit / AVPlayer / ad-SDK runtime methods
```

`JiangHuHook.m` contains an active `CHConstructor`; hook registration ordering is therefore a protected runtime property.

### 7. Extension modules

```text
ZONBootstrap
  -> ZONModuleLoader
     -> Frameworks/ZONModules + bundle/ZONModules
     -> sorted dylib enumeration
     -> path containment check
     -> dlopen(RTLD_NOW | RTLD_LOCAL)
     -> ABI / identifier / initialize dlsym checks
     -> initialize(ZONHostAPI)
```

The module boundary is already substantially cleaner than the legacy runtime and has permanent ABI/contract tests.

## Priority findings

### P0 — preserve startup and hook ordering

The highest regression risk is not ordinary UI code; it is implicit process initialization:

- `main.m +load`
- `method_setImplementation` authorization reset extension
- synchronous framework preflight / `dlopen`
- CaptainHook `CHConstructor`
- fishhook/rebind paths

These paths are order-sensitive and difficult to reproduce with ordinary unit tests. Refactor only after instrumentation and with explicit device gates.

### P1 — `ZONUDIDBridge.h` is an implementation-heavy header

`ZONUDIDBridge.h` contains callback parsing, nonce generation/validation, persistence, raw localhost socket I/O, retry state, observer setup and URL launch behavior. It also contains `static inline` functions with function-local static state.

Risk:
- implementation ownership is implicit;
- future imports can create per-translation-unit copies of static state;
- socket/lifecycle behavior is coupled to every importer;
- changes are hard to isolate and test.

Recommended next structural refactor: move the implementation mechanically to `ZONUDIDBridge.m`, leave declarations in the header, and lock the state-machine behavior with a dedicated contract before any logic cleanup.

### P1 — public UDID API implementation is mixed with menu UI

`ZonoeUDIDAPI.h` is a clean public interface, but its implementation currently lives in `NSObject+UI.m`, alongside floating-window creation and menu presentation.

Risk: unrelated UI edits can affect authorization/device identity lifecycle.

Recommended refactor: move the C API and callback ownership to `ZonoeUDIDAPI.m`; keep `NSObject+UI.m` UI-only. Do this in the same isolated UDID-boundary phase as the bridge split, with first-activation and fallback device tests.

### P1 — large legacy responsibility clusters

Current large active surfaces include approximately:

- `WX_NongShiFu123.mm`: ~68 KB — authorization, activation, legacy UDID/web flow and related status behavior.
- `PubgLoad.mm`: ~35 KB — remote/cloud download, purchase checks, progress UI and archive/load orchestration.
- `daochucd.m`: ~20 KB — backup/export behavior.
- `fuhzu.m`: ~16 KB — import/export support behavior.
- `JiangHuHook.m`: broad multi-provider hook registration and hook implementations.

These are not deletion candidates. They are split candidates only after call ownership and state invariants are locked.

### P1 — hook surface has high maintenance cost

`JiangHuHook.m` combines StoreKit, AVPlayer and multiple ad-provider classes, constructor registration, global state and significant commented historical code.

Risks:
- provider SDK changes are difficult to isolate;
- duplicate/overlapping hook patterns are easy to introduce;
- constructor registration can accidentally drift from implementations;
- commented obsolete implementations obscure the active path.

Do not split it opportunistically. First generate a provider/hook manifest and a constructor-registration contract, then move one provider family at a time while preserving a single constructor owner.

### P1 — repository-only source residue

P39-B proved `NotificationPresenter.swift` had zero PBX membership. It is a Swift convenience wrapper shipped with JDStatusBarNotification, while this target consumes the Objective-C presenter directly.

P40 phase 1 removes this repository-only source without touching the eight active Objective-C JDStatusBarNotification implementations.

### P2 — public-header dependency leakage

Before P40, `ZONFeatureDispatcher.h` imported concrete feature handlers, views and vendor UI (`PubgLoad`, `YYYPicker`, `ImgTool`, `SVProgressHUD`, `WX_NongShiFu123`, etc.). Any consumer of the dispatcher therefore inherited implementation dependencies it did not need.

P40 phase 1 fixes this by keeping the public header declaration-only/minimal and moving concrete imports into `ZONFeatureDispatcher.m`.

### P2 — stale imports and naming debt

P39-B found unused JDStatus imports in `PreferenceManager.m` and `JiangHuHook.m`. P40 phase 1 removes only the low-risk `PreferenceManager.m` import. The hook file remains untouched because it is constructor-owned runtime code.

Legacy class/file names (`WX_NongShiFu123`, `daochucd`, `fuhzu`, mixed Chinese/English paths) reduce discoverability, but renaming active Objective-C symbols/files is lower priority than isolating behavior boundaries and can produce unnecessary PBX/runtime churn.

### P2 — weak error propagation

A number of legacy file operations intentionally ignore `NSError`, and several flows use `exit(0)` as part of established behavior. This makes failure diagnosis harder, but changing failure semantics during structural cleanup would be unsafe.

Recommended order: add logging/observability first; change behavior only in a separately reviewed functional phase.

## Performance review

No runtime profiler data has been collected in this phase, so the items below are **risks to measure**, not claims of measured regressions.

1. Framework path checks and `dlopen` happen synchronously during startup preflight initiated from `+load`.
2. Bundled module enumeration and `dlopen` occur on the main queue after variant entry.
3. UDID localhost polling is off-main, but can perform repeated socket timeouts/retries before reporting unavailable.
4. Cloud-download progress performs UI updates on progress callbacks; behavior is correct and user-visible, but update frequency should be measured before any throttling attempt.
5. Large legacy files increase compile/index/review cost; this is a proven maintainability cost, not necessarily a runtime cost.

Recommended performance phase: add timing/signpost instrumentation around framework preflight, authorization-ready, UDID request/fallback, module scan and first menu presentation; collect data before moving work off the main thread.

## Refactor plan

### Phase 1 — zero-behavior hygiene (P40-A, implemented)

- Remove uncompiled `NotificationPresenter.swift`.
- Remove the proven unused JDStatus import from `PreferenceManager.m`.
- Make `ZONFeatureDispatcher.h` minimal; localize concrete dependencies in `.m`.
- Keep PBX Sources at 75.
- Keep all nine feature routes and all protected startup/hook/auth files unchanged.
- Require A_customer and B_debug full builds and byte-for-byte comparison against promoted P39 artifacts.

### Phase 2 — UDID service ownership (recommended next)

- Freeze the current UDID state machine with source/behavior contracts.
- Add `ZONUDIDBridge.m`; move current bridge implementation mechanically.
- Add `ZonoeUDIDAPI.m`; move callback/fallback API implementation out of `NSObject+UI.m`.
- Keep UI presentation methods in `NSObject+UI.m` only.
- Preserve callback scheme, nonce validation, localhost polling, fallback and keychain semantics.
- Require A/B builds plus explicit real-device tests for:
  - existing DZUDID;
  - Zonoe installed callback path;
  - Zonoe unavailable -> web fallback;
  - fresh activation;
  - clear-auth -> reacquire UDID.

### Phase 3 — hook manifest / provider isolation

- Generate a machine-checkable list of every active hook class/selector and its registration line.
- Identify duplicate or obsolete commented blocks separately from active code.
- Keep one constructor owner.
- Split provider families only when the manifest and binary/selector checks prove equivalence.

### Phase 4 — cloud/save service split

- Separate network/download orchestration from UI status presentation and archive application without changing the existing feature entry points.
- Preserve JDStatusBarNotification messages/progress behavior first; improve error handling only later.

### Phase 5 — authorization decomposition

- Only after UDID ownership is clean, partition `WX_NongShiFu123.mm` by authorization transport/state/UI responsibility.
- Do not rename public/runtime-observed classes during the first decomposition pass.

### Phase 6 — performance work based on measurements

- Add timings first.
- Move or throttle only measured hot/slow paths.
- Treat startup order and hook availability as behavioral constraints.

## P40-A improved code

The first implemented tranche intentionally changes structure, not behavior:

1. `ZONFeatureDispatcher.h` no longer exposes concrete business/vendor dependencies.
2. `ZONFeatureDispatcher.m` explicitly owns those imports; all executable function bodies remain identical to P39.
3. `PreferenceManager.m` no longer imports a notification library it never calls.
4. `NotificationPresenter.swift` is removed because it is not a PBX member and the target uses the Objective-C JDStatus implementation.

Runtime/source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`.

## Behavior-preservation tests

`Tests/p40_zero_behavior_refactor_contract.py` locks:

- exactly 75 PBX Sources;
- all eight JDStatus Objective-C implementations remain active;
- the retired Swift wrapper has no PBX reference and is absent;
- the PreferenceManager change is exactly one unused import removal;
- Dispatcher public function names are unchanged;
- Dispatcher executable body is identical to P39;
- all protected startup/auth/menu/cloud/file/hook source blobs remain identical to P39;
- all nine feature identifiers remain registered;
- tag 203 stays retired;
- protected `+load`, `CHConstructor`, UDID fallback and cloud/JDStatus markers remain present.

Existing permanent tests are also required:

- `Tests/bootstrap_moduleloader_contract.py`
- `Tests/dispatcher_contract_smoke.py`
- Feature Registry compiled smoke
- Module ABI smoke

The P40 CI additionally requires full Xcode 16.4 iOS 12 arm64+arm64e builds for A_customer and B_debug, then compares each produced dylib byte-for-byte with its corresponding promoted P39 artifact. A byte mismatch is a hard failure even if compilation and exported symbols succeed.

## Promotion rule

P39 remains the promoted device baseline until P40 verification completes. P40-A is intentionally designed so its runtime binary should be identical to P39; if byte identity is proven, record it as `binary_equivalent_to_device_verified_p39`. Do not record a new real-device test unless one is explicitly performed and reported.
