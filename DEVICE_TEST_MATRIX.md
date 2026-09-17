# DEVICE TEST MATRIX

## Rule
Every runtime-affecting development version must define its required real-device regression scope before promotion. CI success alone never changes `last_device_verified_*`.

## Common device smoke test
- App launches normally; floating entry appears normally.
- Menu opens/closes normally; outside-tap close works.
- Section fold/unfold and relayout work.
- Card/grid buttons, switches, ad switch and speed slider remain usable.
- No obvious freeze/crash while opening, closing, folding, or operating controls.

## v1_p41 — UDID Bridge Boundary
Source: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`  
CI: `34959813770` / success  
Status: passed; superseded.

## v1_p42 — Zonoe UDID API Boundary
Source: `e87b683a9c868e00d13582c8145bb9368878fee3`  
CI: `34995566144` / success  
Status: passed; superseded by P44.

## v1_p44 — Authorization Orchestration Boundary
Source: `aee574d180da7cc82db54be7ab5aeaa9d072c561`  
CI head: `d6a110befbbc8c96dfffcae1f942c94b6011fe2d`  
CI Run: `35020232205` / success  
Status: **passed / current promoted device baseline**.

Result:
- User explicitly reported P44 real-device validation normal.
- Existing/cached authorization startup normal.
- Cleared auth/UDID continuation normal.
- Return/fallback behavior showed no reported regression.
- Floating entry/menu smoke normal.

## v1_p45 — Legacy UDID Web/Profile Fallback Adapter Boundary
Source: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`  
CI head: `ae57fdd5f61a0901f559083a95d0f984a6f2da84`  
CI Run: `35036655523` / success  
Status: **CI verified / no separate explicit device PASS**.

CI evidence:
- Active Sources: 78 → 79; sole new active source `ZONLegacyUDIDFallbackAdapter.m`.
- Mechanical fallback extraction and independent iPhoneOS compile passed.
- A_customer/B_debug `arm64 + arm64e` builds passed.
- P45/P44 exports and load libraries identical.
- A_customer artifact `10424070482`; dylib SHA256 `15c7d06db2afd08ab1de014d00a0992e76666031b6b4219efb2d82792a19dc56`.

Unverified device behavior is inherited by P46 and included in the P46 combined gate below.

## v1_p46 — Startup Side-Effect Instrumentation & Launch Contract
Source: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`  
CI head: `4cb21f21c76b359fbf7ad13e7d514df39ce83645`  
CI Run: `35167182449` / success  
Status: **pending real-device validation**  
Rollback baseline: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`

Product/CI evidence:
- Added header-only `ZONLaunchTrace.h`; PBX unchanged and Active Sources remain **79**.
- Trace events use monotonic uptime + main-thread flag + legacy `os_signpost`/`NSLog`.
- P46 observational contract passed: stripping trace imports/calls reproduces all touched P45 runtime files exactly.
- Trace header adds no dispatch/timer/sleep scheduling primitives.
- Independent iPhoneOS trace probe passed with `-Wall -Wextra -Werror`.
- A_customer/B_debug builds passed for `arm64 + arm64e`.
- P46/P45 exported symbol sets: identical.
- P46/P45 linked load libraries: identical.
- A_customer artifact `10475352058`, digest `sha256:79c34fd78c0071ed2a865ee24082806f6289e5a6615a0d022446dc6aa84ad0e1`.
- A_customer dylib SHA256 `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- B_debug artifact `10475337852`, digest `sha256:7cf081e2956a0a293f6deafbea20c680350dbf5356f87edfdc4affba915fb6dd`.

### Required combined P45 + P46 device gate
1. **Existing `DZUDID`**: normal startup, no unnecessary Zonoe/fallback, authorization continues normally.
2. **Fresh Zonoe path**: after clear auth/UDID, Zonoe request/return/callback works and authorization continues normally.
3. **Legacy fallback path where practical**: when Zonoe is unavailable, fallback starts once, does not duplicate/loop, valid `DZUDID` bridges back and authorization continues; foreground return does not crash.
4. **Launch trace visibility/order**: `[zonoemenu][TRACE][launch]` events appear for the exercised path, including startup/preflight, authorization/fallback as applicable, module load, floating entry and menu presentation. No trace point should cause a visible stall.
5. **Common menu smoke**: floating icon/menu/basic controls remain normal.

### Promotion rule
- An explicit user PASS for this combined gate promotes P46 directly and supersedes the intermediate P45 candidate.
- Until then, P44 remains the mandatory promoted/rollback baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
