# CHANGELOG_DEV

## 2026-09-18 — v1_p51b Backup Refactor — DEVICE PASSED
- Work branch: `work/zonoemenu-v1-p51b-backup-refactor`.
- Product source commit: `e8df5c72c8698eda76971ac44b44d611c6e8cbbb`.
- Test branch: `test/zonoemenu-v1-p51b-backup-refactor`.
- CI head: `cd70800e364cf9ceb8c5c3b91df3b9d8c1a377a6`.
- CI Run `35255286856`: **success**.
- Refactored duplicated Documents/Library backup loops into a shared backup helper without changing the backup entry or output contract.
- Preserved the 50 MiB confirmation threshold, Skip/Backup choices, staging layout, cleanup paths, ZIP destination and share flow.
- Active Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbols and linked libraries match P51-A.
- A_customer artifact ID `10511909626`, digest `sha256:a8786d238573418cdd69e51578df0b8e5a8fab791dbac61e462dd81c55c2c5b6`.
- A_customer dylib SHA256 `770b2cc1088fdcaa9f7fcfb5abb08d17e257f38f992ecee4b8b3eed4149f1053`.
- B_debug artifact ID `10511974476`, digest `sha256:d456aa02a8bc5cfc23f02c349949af468261e370b1c0b37af156b4fe965fb0be`.
- User explicitly reported all required P51-B real-device tests normal.
- **P51-B is promoted and is now the current rollback/device baseline.**

## 2026-09-18 — v1_p51 Feature Execution Refactor — CI VERIFIED
- Standardized nine feature execution routing and de-duplicated runtime-toggle persistence.
- CI Run `35253980287`: success.
- Device behavior is covered by the later P51-B real-device pass.

## 2026-09-18 — v1_p50 Refactor Stabilization / Architecture Freeze
- Work branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- Runtime baseline remained P49 commit `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- Added architecture freeze contract, final status matrix and CI guardrails.

## 2026-09-18 — v1_p49 Active Target / Dead Code / Dependency Audit
- Product source commit: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- CI Run `35195152912`: success.
- Removed unused `Network.framework`; Active Sources remained 78.
- User explicitly reported P49 real-device validation normal.
- Superseded by P51-B.

## Earlier architecture cleanup
- P48.1 StoreKit residual cleanup: device passed.
- P47 Repository Hygiene: CI passed.
- P46 Startup Side-Effect Instrumentation & Launch Contract: CI passed.
- P45 Legacy UDID Web/Profile Fallback Adapter Boundary: CI passed.
- P44 Authorization Orchestration Boundary: CI passed; device passed.
- P43 architecture audit: CI passed.
- P42 Zonoe UDID API Boundary: CI passed; device passed.
- P41 UDID Bridge Boundary: CI passed; device passed.
