# CHANGELOG_DEV

## 2026-09-12 — v1_p32-B Dispatcher Source Split
- Bumped `VERSION` to `v1_p32`.
- Converted `testmod/ZONCore/ZONFeatureDispatcher.h` from header-owned inline implementation to declarations-only functions; existing imports were intentionally retained to minimize unrelated compile-surface change.
- Added `testmod/ZONCore/ZONFeatureDispatcher.m` with the seven audited function bodies moved mechanically from the p31 header.
- No intended changes to action identifiers, selectors, confirmation text, delay timings, tmp preservation, persistence keys or `ImgTool` side effects.
- Added `Tests/dispatcher_contract_smoke.py` and wired it into permanent `module-abi.yml`.
- Added the p32 real-device checklist to `DEVICE_TEST_MATRIX.md` before artifact handoff.
- PBX registration and A/B CI are pending at this source commit.

## 2026-09-12 — v1_p32-A Dispatcher Boundary Audit
- Audit commit: `e7dddfbb5bb9cd597f6a194d9bee06e0cbba7988`.
- Workflow Run `34703403975`: **success**.
- Confirmed active Dispatcher ownership and locked seven action / three toggle routes without changing product source.
- Approved an isolated mechanical Dispatcher `.h` -> `.h + .m` split.

## 2026-09-12 — v1_p31 Feature Registry Boundary Cleanup
- Integrated source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- CI Run `34673034214`: A/B, Registry equivalence/smoke and Module ABI passed.
- User reported cumulative p29+p30+p31 real-device regression passed; p31 is the current device-verified baseline.

## 2026-09-12 — v1_p30 EventBridge Boundary Cleanup
- Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`.
- A/B CI passed; hardware covered by p31 cumulative regression.

## 2026-09-12 — v1_p29 Rendering Boundary Cleanup
- Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- A/B CI passed; hardware covered by p31 cumulative regression.

## 2026-09-12 — v1_p28 ZONCore Build Integration
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- A/B CI and hardware regression passed.
