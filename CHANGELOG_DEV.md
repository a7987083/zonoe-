# CHANGELOG_DEV

## 2026-09-20 — v1_p62 Authorization Reset Service — DEVICE PASSED
- Work branch: `work/p62-zonkeychain-deletekm-service`.
- Product source commit: `a1d0f7b7ca7ea2747d7c52a2b5e002830731ffca`.
- CI Run `35480732207`: **success**.
- Extracted the authorization reset clear set into `testmod/ZONServices/ZONAuthorizationResetService.h/.m`.
- `WX_NongShiFu123::deletekm` now forwards to the reset service rather than owning the clear implementation.
- Preserved the effective P62 UserDefaults, legacy `getKeychain`, `DZUDID`, bridge-cache and `ZONKeychain` clear behavior.
- Removed reset implementation ownership from the authorization coordinator while preserving compatibility startup behavior.
- Fixed `tools/p62_apply_authorization_reset_service.py` so PBXBuildFile, PBXFileReference and PBXSourcesBuildPhase membership are inserted deterministically.
- Fixed the P62 workflow to pin A_customer/B_debug builds to the exact post-migration revision.
- A_customer build/link/output verification: PASS.
- B_debug build/link/output verification: PASS.
- A_customer artifact ID `10595647289`; dylib SHA256 `71f14901e140fd19cf175c0092e1cfdf46c7aefc04d2ba73b03baf83359f6962`.
- B_debug artifact ID `10595652401`; dylib SHA256 `34cbcd9695c7eaad9096c606341fed008dce4e78094df1433243dd5cb9391c59`.
- User explicitly reported the produced dylib tests fully normal on device.
- **P62 Authorization Reset Service is promoted/device-passed.**

## 2026-09-20 — v1_p62 ZONKeychain Migration — VERIFIED IN P62 LINE
- Replaced the active `SFHFKeychainUtils` UDID path with `ZONKeychain`.
- Removed `SFHFKeychainUtils.h/.m` from the active project surface and PBX references.
- Preserved the existing `UDID` / `com.china.TestKeyChain` identity semantics.
- Legacy `getKeychain` remains active for other historical keys and is not part of the current six-button refactor scope.

## 2026-09-20 — P63A Six Button Service Boundary — PLANNED / STARTED
- Scope is limited to six existing action buttons: remote download, VIP cloud save, backup save, restore save, clear game data and clear authorization records.
- First stage will add service/adapter boundaries and redirect `ZONFeatureDispatcher` through them while retaining the current legacy engines internally.
- P63A explicitly forbids deep behavior rewrites of `PubgLoad`, `daochucd`, `YYYPicker` and `WX_NongShiFu123.mm`.
- `ZONAuthorizationResetService` will be reused rather than reimplemented.
- Promotion requires A_customer + B_debug CI and explicit real-device smoke validation of all six buttons.

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
- P51-B was promoted and later superseded.

## 2026-09-18 — v1_p51 Feature Execution Refactor — CI VERIFIED
- Standardized nine feature execution routing and de-duplicated runtime-toggle persistence.
- CI Run `35253980287`: success.
- Device behavior is covered by later promoted baselines.

## 2026-09-18 — v1_p50 Refactor Stabilization / Architecture Freeze
- Work branch: `work/zonoemenu-v1-p50-architecture-freeze`.
- Runtime baseline remained P49 commit `4cebe094ad7a4dd554e8266af34dcf3abe04902a`.
- Added architecture freeze contract, final status matrix and CI guardrails.

## Earlier architecture cleanup
- P49 Active Target / Dead Code / Dependency Audit: device passed.
- P48.1 StoreKit residual cleanup: device passed.
- P47 Repository Hygiene: CI passed.
- P46 Startup Side-Effect Instrumentation & Launch Contract: CI passed.
- P45 Legacy UDID Web/Profile Fallback Adapter Boundary: CI passed.
- P44 Authorization Orchestration Boundary: CI passed; device passed.
- P43 architecture audit: CI passed.
- P42 Zonoe UDID API Boundary: CI passed; device passed.
- P41 UDID Bridge Boundary: CI passed; device passed.

## Later promoted/corrective stages retained in project state
- P56 PubgLoad temp-boundary cleanup: device passed.
- P57 diagnostic stage: abandoned/reverted after server-side cause was confirmed.
- P58 download lifecycle hardening: device passed.
- P59 automatic UDID retry UX: superseded/not promoted.
- P60 UDID acquisition progress/manual retry: device passed.
- P61 offline authorization retry: CI passed; working line superseded by P62.
