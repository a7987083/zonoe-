# CHANGELOG_DEV

## 2026-09-17 — v1_p46 Startup Side-Effect Instrumentation & Launch Contract
- Work branch: `work/zonoemenu-v1-p46-launch-contract`.
- Product source commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- Test branch: `test/zonoemenu-v1-p46-launch-contract-build`.
- Successful CI head: `4cb21f21c76b359fbf7ad13e7d514df39ce83645`.
- CI Run `35167182449`: **success**.
- Added header-only `testmod/ZONServices/ZONLaunchTrace.h` using `mach_absolute_time`, structured `NSLog`, and legacy `os_signpost_event_emit` for iOS 12-compatible launch observability.
- Added trace points around `main.m +load`, reset installation, Bootstrap/preflight, A_customer/B_debug variant entry, authorization cached/fresh paths, legacy fallback, module scan/load, floating-entry attach and menu presentation.
- No PBX registration was added; Active Sources remain **79**.
- `Tests/p46_launch_contract.py` proves that removing trace imports/calls restores every touched runtime file exactly to P45 and that the PBX is byte-identical to P45.
- Trace header contains no queue/timer/sleep scheduling primitives; key startup ordering remains unchanged by contract.
- Independent iPhoneOS arm64 trace probe compiled with `-Wall -Wextra -Werror`.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- P46/P45 exported symbol sets are identical.
- P46/P45 load-library sets are identical.
- A_customer artifact ID `10475352058`, digest `sha256:79c34fd78c0071ed2a865ee24082806f6289e5a6615a0d022446dc6aa84ad0e1`.
- A_customer dylib SHA256 `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- B_debug artifact ID `10475337852`, digest `sha256:7cf081e2956a0a293f6deafbea20c680350dbf5356f87edfdc4affba915fb6dd`.
- P46 status: **CI verified / device pending**. It inherits P45 runtime, so its device gate must also cover P45 legacy fallback behavior. P44 remains promoted rollback baseline.

## 2026-09-16 — v1_p45 Legacy UDID Web/Profile Fallback Adapter Boundary
- Work branch: `work/zonoemenu-v1-p45-legacy-udid-fallback-adapter`.
- Product source commit: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`.
- Test branch: `test/zonoemenu-v1-p45-legacy-udid-fallback-adapter-build`.
- Successful CI head: `ae57fdd5f61a0901f559083a95d0f984a6f2da84`.
- CI Run `35036655523`: **success**.
- Added `ZONLegacyUDIDFallbackAdapter.h/.m` and mechanically moved the existing legacy `WX_NongShiFu123 getUDID:` fallback block out of `ZonoeUDIDAPI.m` without changing main-queue, one-in-flight, `DZUDID`, plausibility-check, log or bridge-store semantics.
- Active Sources changed **78 → 79**, sole new active source `ZONLegacyUDIDFallbackAdapter.m`.
- Adapter independent iPhoneOS compile passed; A_customer/B_debug arm64+arm64e builds passed.
- P45/P44 exports and load libraries are identical.
- A_customer artifact `10424070482`, digest `sha256:5b81d2d673b970518c84a35e271e1a2f74ffcbee907d319d39a9f18bdf96747a`, dylib SHA256 `15c7d06db2afd08ab1de014d00a0992e76666031b6b4219efb2d82792a19dc56`.
- B_debug artifact `10423676606`, digest `sha256:c5b2ca0a36a518a92a660f9ffde4a94b22054e5eec0af331d5cb8cdd79012477`.
- P45 did not receive a separate explicit real-device PASS before P46 development; it remains an intermediate CI-verified version.

## 2026-09-16 — v1_p44 Authorization Orchestration Boundary
- Work branch: `work/zonoemenu-v1-p44-authorization-orchestration-boundary`.
- Product source commit: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- Test branch: `test/zonoemenu-v1-p44-authorization-orchestration-boundary-build`.
- Successful CI head: `d6a110befbbc8c96dfffcae1f942c94b6011fe2d`.
- CI Run `35020232205`: **success**.
- Added `testmod/ZONServices/ZONAuthorizationCoordinator.h/.m` and mechanically moved authorization/reset orchestration out of `main.m` while preserving `+load`, Bootstrap call position and framework preflight order.
- Active Sources changed **77 → 78**.
- A_customer/B_debug arm64+arm64e builds passed; P44/P42 exports/load libraries are identical.
- A_customer artifact `10417242852`, digest `sha256:d9ce3432727b1c2ce5302ad4e732237ac7c45261ebd65cc3e7eda291ae2c71b8`, dylib SHA256 `f8d33f888ea5466217938af1cd338765252effb2cc4eda039a871579346e0435`.
- User explicitly reported P44 real-device validation normal; **P44 is the current promoted device baseline**.

## 2026-09-16 — P43 Architecture State Refresh & Remaining Ownership Audit
- Work branch `work/zonoemenu-v1-p43-architecture-audit`; test `test/zonoemenu-v1-p43-architecture-audit`.
- Audit head `aed6b72e15a5d7096b42b2dbf4f8fa467c963150`; CI Run `35001000784`: success.
- Canonical runtime/PBX remained identical to P42; Active Sources stayed 77.
- Selected the authorization/reset helper block in `main.m` as P44 target and excluded direct `WX_NongShiFu123.mm` rewrite.

## 2026-09-16 — Canonical Post-P42 Refactor Plan
- Published complete P43–P50 sequence in `ROADMAP.md` with goals, scope, forbidden changes, gates and promotion rules.

## 2026-09-16 — v1_p42 Zonoe UDID API Boundary
- Source `e87b683a9c868e00d13582c8145bb9368878fee3`; CI `34995566144` success; Active Sources 77.
- Moved `ZonoeUDIDAPI` implementation from `NSObject+UI.m` to `ZONServices/ZonoeUDIDAPI.m` mechanically.
- A_customer artifact `10407391591`; dylib SHA256 `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- User explicitly reported P42 device validation normal; later superseded by P44.

## 2026-09-15 — v1_p41 UDID Bridge Boundary
- Source `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`; CI `34959813770` success; Active Sources 76.
- `ZONUDIDBridge.h` became declaration-only and implementation moved to `ZONUDIDBridge.m`; device passed, later superseded.

## Earlier architecture cleanup
- P40 zero-behavior cleanup: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`, CI `34915266733` success.
- P39 active target slimming: `613882da7068795533c530d45775f7ae5f79ed56`, device passed.
- P33 Bootstrap / ModuleLoader boundary: `0f12e4353e8859c585fe2975812964a28b7410d1`.
- P32 Dispatcher split: `84f8b3898bee9d95ed4034d12842879cc56280d3`, device passed.
