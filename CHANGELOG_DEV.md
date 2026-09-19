# CHANGELOG_DEV

## 2026-09-19 — v1_p65 P62 Maintainability Refactor — CI PASSED / DEVICE PENDING
- Work branch: `work/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test branch: `test/zonoemenu-v1-p65-p62-maintainability-refactor`.
- Test head: `f5742ed68489b529169c850619cb9e1036150920`.
- CI Run `35424279529`: **success**.
- Runtime diff versus promoted P62 is restricted to `testmod/ZONServices/ZONAuthorizationCoordinator.m`.
- Centralized `DZUDID` / bridge-cache keys, UDID validity, keychain reads and write-verification into private helpers.
- Preserved reset hook, existing-DZUDID path, Zonoe bridge-cache path, callback/request flow, trace events, status text and `loada` continuation.
- Added `Tests/p65_p62_maintainability_refactor_contract.py`.
- Added `.github/workflows/p65-p62-maintainability-refactor.yml`.
- Added `P65_CODEBASE_REVIEW.md` with architecture, risk inventory and staged P66-P70 plan.
- Active Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols and linked libraries match P62 artifacts.
- A_customer artifact ID `10578282908`, digest `sha256:5e1bf17b13d03c9bcb090a535d2e0aaa3c63f9fb985a59e0eed77c6df30c6e50`.
- B_debug artifact ID `10579071326`, digest `sha256:1707e41634a956603b306e1569594942bd37a5a2281adbd68fc5e95d180de373`.
- **Not promoted yet: real-device regression is pending. P62 remains rollback/device baseline.**

## 2026-09-19 — v1_p62 Unified Authorization Network Retry — DEVICE PASSED
- Runtime/source commit: `a11160e70ff1163b2c462bb3ef5d539da1f489eb`.
- CI head: `c1f1415d3787b879def387d68e2df089776dbffa`.
- CI Run `35410564486`: **success**.
- Unified authorization network retry UI across Reachability failures, BSPHP initialization HTTP failures, configuration HTTP failures and BSPHPy entitlement-fetch failures.
- Preserved retry mode so `重新检查` retries BSPHP vs BSPHPy without re-entering `loada`.
- Active Sources: **78**.
- A_customer/B_debug arm64 + arm64e: PASS.
- User explicitly reported P62 real-device checks normal.
- **P62 is the current promoted rollback/device baseline.**

## 2026-09-19 — P63/P64 Offline Authorization Experiments — ABANDONED / REVERTED
- P63 device behavior still fell back to forced network retry.
- P64 follow-up preroute candidate was abandoned before promotion.
- Development returned to the verified P62 baseline.

## 2026-09-18 — v1_p51b Backup Refactor — DEVICE PASSED
- Work branch: `work/zonoemenu-v1-p51b-backup-refactor`.
- Product source commit: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`.
- Test branch: `test/zonoemenu-v1-p51b-backup-refactor`.
- CI head: `cd70800e364cf9ceb8c5c3b91df3b9d8c1a377a6`.
- CI Run `35255286856`: success.
- Refactored duplicated Documents/Library backup loops into a shared backup helper without changing the backup entry or output contract.
- Active Sources remained 78; A_customer/B_debug arm64 + arm64e passed.
- User explicitly reported real-device tests normal.

## 2026-09-18 — v1_p51 Feature Execution Refactor — CI VERIFIED
- Standardized feature execution routing and de-duplicated runtime-toggle persistence.
- CI Run `35253980287`: success.
- Device behavior covered by later P51-B pass.

## 2026-09-18 — v1_p50 Architecture Freeze
- Frozen Registry/Dispatcher and core ownership boundaries.
- Runtime unchanged from the then-promoted P49 baseline.

## Earlier architecture cleanup
- P49 Active Target / Dependency Audit: device passed.
- P48 / P48.1 App Store / StoreKit cleanup: device passed.
- P47 Repository Hygiene: completed.
- P46 Startup Side-Effect Instrumentation: CI verified.
- P45 Legacy UDID fallback adapter: CI verified.
- P44 Authorization Orchestration Boundary: device passed.
- P43 Architecture Audit: completed.
- P42 ZonoeUDIDAPI Boundary: device passed.
- P41 UDID Bridge Boundary: device passed.
