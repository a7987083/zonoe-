# P50 Final Status Matrix

## Purpose
This matrix is the post-refactor engineering baseline for `zonoemenu`. P50 does not change runtime behavior; it freezes the device-verified P49 product surface and defines how future work must enter the codebase.

## Promoted runtime baseline
| Item | Frozen value |
| --- | --- |
| Runtime version | `v1_p49` |
| Runtime commit | `4cebe094ad7a4dd554e8266af34dcf3abe04902a` |
| Device status | PASS |
| CI Run | `35195152912` |
| Active PBX Sources | `78` |
| Architectures | `arm64 + arm64e` |
| A_customer artifact | `10485344383` |
| A_customer SHA256 | `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac` |
| B_debug artifact | `10485622521` |
| `StoreKit.framework` | absent |
| `Network.framework` | absent |

## Architecture ownership matrix
| Surface | Canonical owner | Frozen contract | Future change route |
| --- | --- | --- | --- |
| Startup | `ZONBootstrap` + existing `+load` entry | startup ordering and continuation semantics preserved | dedicated startup stage |
| Authorization | `ZONAuthorizationCoordinator` | auth continuation/retry/timeout semantics preserved | dedicated auth stage |
| UDID | `ZONUDIDBridge`, `ZonoeUDIDAPI`, legacy fallback adapter | fallback order and persistence preserved | dedicated UDID stage |
| Feature catalog | `ZONFeatureRegistry` | feature identity/type/metadata source of truth | feature stage |
| Feature execution | `ZONFeatureDispatcher` | UI must dispatch through this boundary | feature/behavior stage |
| Menu UI | coordinator/renderers/panel/event bridge | presentation can change; business calls must not bypass Registry/Dispatcher | UI-only stage |
| Module loading | `ZONModuleLoader` | discovery / `dlopen` order preserved | dedicated module-loader stage |
| Backup / restore | existing import/export services | save paths and destructive semantics preserved | storage stage |
| Cloud save | existing cloud-save path | current auth/network/persistence semantics preserved | cloud-save stage |
| Hooks / toggles | current hook entry points and persisted keys | no silent key/behavior changes | behavior stage |

## Allowed post-P50 changes
- UI-only themes, renderers, layout and animation changes that consume `ZONFeatureRegistry` and `ZONFeatureDispatcher`.
- Isolated new features added behind existing Registry/Dispatcher and service boundaries.
- Root-cause bug fixes with a narrow contract and regression test.
- Documentation, CI, diagnostics and observability that do not alter runtime ordering or semantics.
- Build-system maintenance that preserves target membership, architectures, ABI and load dependencies unless explicitly scoped otherwise.

## Changes that require an explicitly named new stage
- Any modification to `+load` / bootstrap ownership or ordering.
- Authorization or UDID retry, timeout, callback, fallback or persistence changes.
- UI directly invoking legacy business classes instead of Registry/Dispatcher.
- Module discovery or `dlopen` ordering changes.
- Persistence key, save location or destructive-cleanup behavior changes.
- Active source or framework deletion/addition.
- Structural merge/split/move of frozen core classes without a concrete product requirement.

## Mandatory gates for future runtime stages
1. Start from the current promoted device baseline.
2. Declare exactly one behavioral or architectural concern.
3. Record product diff and PBX membership delta.
4. Run contract/static validation.
5. Build A_customer and B_debug for `arm64 + arm64e`.
6. Compare exported symbols and load libraries against the immediate promoted predecessor.
7. Produce A_customer artifact + digest + dylib SHA256.
8. Execute the scoped real-device checklist.
9. Promote only after explicit real-device PASS.

## Freeze conclusion
P41-P49 structural work is considered closed. P50 freezes the resulting architecture. Future work should prefer feature/UI stages over further structural churn unless a measured defect or concrete requirement proves the need to reopen a frozen boundary.
