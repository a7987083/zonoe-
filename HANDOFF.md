# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` -> `P65_CODEBASE_REVIEW.md` -> `ROADMAP.md` -> `DEVICE_TEST_MATRIX.md`.

## Promoted rollback/device baseline
- Version: `v1_p62`.
- Runtime/source commit: `a11160e70ff1163b2c462bb3ef5d539da1f489eb`.
- Test/CI head: `c1f1415d3787b879def387d68e2df089776dbffa`.
- CI Run `35410564486`: success.
- Real-device validation: passed, explicitly reported by user.
- Active Sources: 78.
- Architectures: `arm64 + arm64e`.

## Current candidate
- Version: `v1_p65`.
- Work branch: `work/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test branch: `test/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test head: `f5742ed68489b529169c850619cb9e1036150920`.
- CI Run `35424279529`: success.
- Contract: passed.
- A_customer build: passed.
- B_debug build: passed.
- arm64 + arm64e / ABI / linked-library checks: passed.
- A_customer artifact: `10578282908`, digest `sha256:5e1bf17b13d03c9bcb090a535d2e0aaa3c63f9fb985a59e0eed77c6df30c6e50`.
- B_debug artifact: `10579071326`, digest `sha256:1707e41634a956603b306e1569594942bd37a5a2281adbd68fc5e95d180de373`.
- Real-device validation: pending.
- P62 remains rollback baseline until P65 device pass.

## P65 runtime change
Only `testmod/ZONServices/ZONAuthorizationCoordinator.m` changes in the runtime surface versus P62.

The refactor centralizes:
- `DZUDID` key ownership;
- zonoe bridge-cache key ownership;
- UDID validity checks;
- keychain read helper;
- write-then-read verification helper.

Protected behavior retained:
- authorization-reset method hook;
- existing-DZUDID fast path;
- Zonoe bridge cache path;
- callback/request ordering;
- launch trace events;
- customer status strings;
- `WX_NongShiFu123::loada` continuation.

## Current architecture
```text
dyld
 -> Bsphp/main.m +load
 -> ZONBootstrap
    -> framework preflight
    -> A_customer: ZONAuthorizationCoordinator -> ZonoeUDIDAPI -> legacy loada
    -> B_debug: floating entry
    -> ZONModuleLoader

menu
 -> PopupMenuVC shell
 -> ZONMenuCoordinator/renderers
 -> ZONFeatureRegistry
 -> ZONFeatureDispatcher
 -> legacy business handlers
```

## High-priority risks
1. `WX_NongShiFu123.mm` remains the active authorization/network/UI god object.
2. `getXinxi:` trusts split-array shape before indexing.
3. `getNet` lacks explicit NULL handling for reachability creation.
4. clear-data deletion and `exit(0)` are independently scheduled for the same deadline.
5. startup `+load` / preflight / authorization / module loading remain order-sensitive.
6. P63/P64 offline authorization work is abandoned and must not be reintroduced accidentally.

## Planned sequence
- P65: coordinator state cleanup — CI passed, device pending.
- P66: authorization retry ownership extraction.
- P67: authorization response parsing safety.
- P68: authorization networking boundary.
- P69: destructive-data sequencing.
- P70: staged legacy authorization decomposition.

## Immediate Next Task
Run P65 real-device regression. If normal, record device pass and promote P65. If any visible behavior differs, stop promotion and compare against P62 before continuing. Do not start P66 from an unverified P65 runtime.
