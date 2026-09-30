# CODEBASE REVIEW / REFACTOR PLAN

## Review baseline
- Repository: `a7987083/zonoe-`.
- Canonical product surface: `testmod/` + `testmod.xcodeproj`.
- Active branch: `work/p79.8-udid-first-rebuild`.
- Current architecture-hardening build: `v1_p79_8e`.
- P79.8e Run `36718795572` / #40: PASS.
- Raw product dylib is byte-identical to P79.8d: SHA256 `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Real-device promotion is intentionally not inferred from CI.

## Architecture summary

### 1. Bootstrap/startup
`testmod/Bsphp/main.m +load` is the process entry. It installs the authorization-reset compatibility hook and calls `ZONBootstrapStart`. Bootstrap preserves synchronous legacy framework preflight, then schedules variant entry on the main queue and finally scans formal `ZONModules` extensions.

### 2. Authorization
`ZONAuthorizationCoordinator` owns obtaining/reusing `DZUDID`, verifying durable Keychain storage, and entering `ZONAuthV2Flow`. `ZONAuthV2Flow` currently owns the complete authorization state machine: `/apiface` classification, card activation, Runtime Config, Verify, user-facing error mapping, card UI, notice/update UI, and final floating-icon continuation.

### 3. Menu
`ZONMenuCoordinator` owns panel lifecycle. `ZONSectionRenderer` reads the current Verify state, filters registry features by server permissions, and delegates visual creation to `ZONFeatureRenderer`. `ZONMenuEventBridge` translates UIKit events to feature tags. `ZONFeatureDispatcher` maps registry identifiers to service/coordinator boundaries and runtime toggles.

### 4. Business services
Backup, restore, save transfer, local-file browsing, reset, runtime directory, UDID and authorization have dedicated coordinators/services. This is the correct target direction: core/menu code should route rather than reimplement business behavior.

### 5. External dylibs
Two mechanisms exist:
- `ZONModuleLoader`: host-owned formal ABI plugins loaded with `dlopen` and `dlsym`.
- P79.8d passive module: externally pre-injected dylib discovered through dyld and invoked only after exact Mach-O/RVA/signature checks.

They have different lifecycle contracts and should share capability abstractions only after preserving those differences.

## Priority findings

### P0 — CI previously ignored core changes — corrected in P79.8e
Before P79.8e, the active P79 workflow listened mainly to VERSION/AuthV2/AuthorizationCoordinator. A `ZONCore` change could therefore land without the primary device build running.

P79.8e correction:
- workflow now watches `testmod/ZONCore/**`, `testmod/ZONServices/**`, project-file changes and current contract tests;
- current Dispatcher/runtime contracts execute before Xcode build.

### P0 — contract-test drift — partially corrected in P79.8e
`Tests/dispatcher_contract_smoke.py` still described the old implementation where Dispatcher directly called `PubgLoad`, `daochucd`, `YYYPicker` and `WX_NongShiFu123`. Current Dispatcher routes through service/coordinator boundaries.

P79.8e correction:
- updated the active Dispatcher contract to current service routing;
- added `Tests/p79_8d_passive_satella_contract.py` to pin the externally injected-module behavior.

Remaining risk:
- historical phase tests such as `dispatcher_boundary_audit.py` still encode obsolete header-only/legacy assumptions. They should be classified as historical snapshots or refreshed before being included in a global test suite.

### P0 — `ZONAuthV2Flow.m` is an authorization god object
The file owns protocol interpretation, state classification, activation sequencing, config/Verify orchestration, error translation, alerts, notices, update UI and final application continuation.

Risk:
- small UI changes can affect protocol flow;
- protocol changes can affect presentation behavior;
- most behavior is difficult to unit-test without UIKit/network state.

Target split, in order:
1. pure `ZONAuthorizationDecision` parser/classifier;
2. activation/Verify orchestration state machine;
3. presentation policy/adapter;
4. notice/update presentation kept behind existing `ZONPresentationCoordinator`.

Do not rewrite all of this in one phase.

### P0 — startup remains order-sensitive
`main.m +load` performs synchronous legacy preflight, including conditional framework `dlopen`, before the asynchronous ready block.

Risk:
- startup latency;
- loader-lock/order interactions;
- hard-to-reproduce host-App compatibility problems.

Action:
- instrument first; do not reorder before measurement and a dedicated real-device gate.

### P1 — `ZONFeatureDispatcher` mixes four responsibilities
It currently contains:
1. server-permission lookup + permission-denied UI;
2. feature identifier routing;
3. runtime preference/`ImgTool` side effects;
4. passive Mach-O discovery/validation/PAC/invocation.

Target:
- keep Dispatcher as route table only;
- extract passive capability/invocation into a runtime-capability service;
- extract runtime preference mutation into a runtime-settings service;
- inject/query permissions through a feature-access context instead of reading AuthV2 storage directly.

This directly prepares the codebase for future “new external dylib + new button + show only when loaded” requirements without hardcoding every plugin inside Dispatcher.

### P1 — `ZONSectionRenderer` depends directly on AuthV2 storage schema
Renderer reads `lastVerify`, extracts `permissions` and `access_level`, then performs rendering decisions.

Risk:
- presentation knows authorization storage representation;
- harder to test feature visibility independently;
- future local runtime capabilities would force more unrelated dependencies into renderer.

Target API:
```objc
@protocol ZONFeatureAccessProviding <NSObject>
- (BOOL)isFeatureVisible:(NSDictionary<NSString *, id> *)feature;
- (BOOL)isFeatureActionAllowed:(NSDictionary<NSString *, id> *)feature;
@end
```

Renderer should consume a resolved access/capability decision, not raw Verify storage.

### P1 — weakly typed feature metadata
`ZONFeatureRegistry` uses dictionaries with string keys for identifiers, title, section, tag, kind, risk and permission requirements.

Risk:
- misspelled keys compile successfully;
- runtime casts are repeated;
- adding capability requirements will make dictionaries increasingly fragile.

Target:
- introduce immutable `ZONFeatureDescriptor` / `ZONSectionDescriptor` objects or typed structs;
- preserve existing identifiers and legacy tags exactly;
- migrate one renderer/route at a time.

### P1 — two external-module concepts need a common capability vocabulary
Formal modules expose a stable ABI; passive injected dylibs use filename + binary signatures + RVA. The future new-dylib button needs a common answer to “is capability X available?” without forcing common loading behavior.

Recommended boundary:
```text
ZONRuntimeCapabilityRegistry
  capability id
  -> probe()       // loaded/compatible?
  -> invoke()      // optional action
  -> source type   // formal module / pre-injected image
```

Do **not** make this registry automatically `dlopen` passive modules.

### P1 — duplicated config parsing utilities
`ZONAuthV2API.m` and `ZONAuthV2Verify.m` each implement nested Runtime Config lookup helpers (`ZONConfigValue`-style behavior).

Risk:
- schema handling can drift between endpoint construction and Verify identity construction.

Target:
- one pure config accessor utility with contract tests for nested containers and fallback keys.

### P2 — runtime preference keys are duplicated across core files
`NNGGNNGG`, `AADDAADD`, `AADDssppeedd` and associated state are split between EventBridge and Dispatcher.

Target:
- one runtime-settings boundary/constant owner;
- preserve existing key strings and `synchronize` timing until device equivalence is proven.

### P2 — repository contains historical architecture/tests/artifacts
The repository intentionally contains many phase-specific workflows/tests and legacy source trees. This is useful evidence but makes “run all tests” and source discovery misleading.

Target:
- separate active tests from historical phase snapshots;
- maintain one current CI entry point;
- remove tracked generated binaries only after proving no packaging/script consumer depends on them.

## Performance findings

### Measured/proven
No runtime performance regression was measured in this review. P79.8e is byte-identical to P79.8d, so it introduces no runtime cost.

### Candidates requiring measurement before change
- synchronous framework lookup/`dlopen` during `+load` preflight;
- full dylib SHA-256 computation for Verify;
- repeated `NSUserDefaults synchronize` on runtime toggles;
- module-directory scanning/loading at bootstrap;
- UI relayout/deferred grid rendering.

Do not optimize these only from code inspection. Security/ordering semantics can matter more than micro-performance.

## Staged refactor plan

### R1 — Verification baseline — DONE in P79.8e
- restore CI coverage for active core/service changes;
- align current Dispatcher test with service routing;
- lock P79.8d passive-module contract;
- prove arm64 + arm64e compilation;
- prove raw product binary byte-identical to P79.8d.

### R2 — Runtime capability boundary
Extract passive image discovery/validation/invocation from `ZONFeatureDispatcher` into a dedicated capability service. No menu filtering change yet. Add pure probe tests and retain exact names/RVAs/signatures/PAC/main-thread/one-shot semantics.

### R3 — Feature access context
Stop `ZONSectionRenderer` and Dispatcher from reading raw AuthV2 storage independently. Create one access provider combining server permissions and local runtime capabilities. This is the right place for the future “only show the new button when its separate dylib is actually loaded” rule.

### R4 — Typed feature descriptors
Replace dictionary-only feature metadata incrementally. Preserve every identifier/tag/order/state key and test the resulting registry snapshot.

### R5 — Authorization decomposition
Extract pure license/Verify decision parsing from `ZONAuthV2Flow`, then extract orchestration. Keep UIKit presentation and network calls behind interfaces/fakes. This phase needs the broadest regression matrix.

### R6 — Startup measurement before optimization
Add signposts/timestamps around `+load`, AppLovin/Unity preflight, authorization entry and module load. Only after real measurements decide whether loading can move/reorder.

### R7 — repository/test hygiene
Classify active vs historical tests/workflows and generated/package artifacts. Delete nothing without PBX/script/release evidence.

## Test strategy for behavior preservation
Use four layers:
1. **Snapshot/contract tests** for identifiers, legacy tags, keys, permission requirements and passive binary signatures.
2. **Pure unit tests** for future authorization decisions/config lookup/capability probes.
3. **Build tests** for `arm64 + arm64e` with the production target.
4. **Real-device gates** for startup ordering, authorization, menu rendering, cloud permissions and external injected-dylib invocation.

P79.8e currently provides layers 1 and 3 for the refactored verification boundary. It does not claim to replace real-device testing.
