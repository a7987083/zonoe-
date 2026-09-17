# DEVICE TEST MATRIX

## Rule
Every runtime-affecting development version must define its required real-device regression scope before promotion. CI success alone never changes `last_device_verified_*`. Repository-only candidates may inherit a pending runtime gate when their produced runtime binary is proven identical to the predecessor.

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

Unverified device behavior is inherited by P46/P47 and included in the combined gate below.

## v1_p46 — Startup Side-Effect Instrumentation & Launch Contract
Source: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`  
CI head: `4cb21f21c76b359fbf7ad13e7d514df39ce83645`  
CI Run: `35167182449` / success  
Status: **pending real-device validation; superseded as test vehicle by byte-identical P47 candidate**  
Rollback baseline: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`

Product/CI evidence:
- Added header-only `ZONLaunchTrace.h`; PBX unchanged and Active Sources remain **79**.
- Trace events use monotonic uptime + main-thread flag + legacy `os_signpost`/`NSLog`.
- P46 observational contract passed: stripping trace imports/calls reproduces all touched P45 runtime files exactly.
- Trace header adds no dispatch/timer/sleep scheduling primitives.
- Independent iPhoneOS trace probe passed with `-Wall -Wextra -Werror`.
- A_customer/B_debug builds passed for `arm64 + arm64e`.
- P46/P45 exported symbol sets and linked load libraries: identical.
- A_customer dylib SHA256 `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.

## v1_p47 — Repository Hygiene / Generated Artifact Cleanup
Repository candidate: `64f8575966d62695123b9f8444f89dbc98e796df`  
Runtime source: unchanged P46 `83a49f46c1d0e4eecf5a52a485ebc35442786f67`  
CI head: `eed8c8aca74a8c6e6985848a11c76d5a52cc2f40`  
CI Run: `35169166129` / success  
Status: **CI verified / inherited combined device gate pending**  
Rollback baseline: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`

Product/repository evidence:
- Removed only tracked generated package ZIP after zero-consumer search evidence.
- Added `.gitignore` rule `Packages/*.zip`.
- `testmod/` and `testmod.xcodeproj/` tree SHAs are exactly equal to P46.
- Active Sources remain **79**.
- Inherited P46 launch contract passed.
- A_customer/B_debug builds passed for `arm64 + arm64e`.
- P47/P46 exported symbols and linked load libraries: identical.
- A_customer artifact `10476362290`, digest `sha256:f913b210dd80e2438af1bfc13b8b8b3aafe3ab3837c8d4507935abb10adfdfe5`.
- A_customer dylib SHA256 `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`, **exactly equal to P46 A_customer**.
- B_debug artifact `10476157646`, digest `sha256:d2f57b2f041b533a40dcfdec43e691c274822b97214deeeb5acaac3e115a7bcd`.

### Required combined P45 + P46 + P47 device gate
1. **Existing `DZUDID`**: normal startup, no unnecessary Zonoe/fallback, authorization continues normally.
2. **Fresh Zonoe path**: after clear auth/UDID, Zonoe request/return/callback works and authorization continues normally.
3. **Legacy fallback path where practical**: when Zonoe is unavailable, fallback starts once, does not duplicate/loop, valid `DZUDID` bridges back and authorization continues; foreground return does not crash.
4. **Launch trace visibility/order**: `[zonoemenu][TRACE][launch]` events appear for the exercised path, including startup/preflight, authorization/fallback as applicable, module load, floating entry and menu presentation. No trace point should cause a visible stall.
5. **Common menu smoke**: floating icon/menu/basic controls remain normal.

### Promotion rule
- Because P47 A_customer is byte-identical to P46, one explicit user PASS on P47 satisfies the still-pending P46 runtime device gate and covers inherited P45 fallback behavior for the exercised combined checklist.
- P47 may then be promoted directly; P45/P46 remain intermediate verified stages in history.
- Until then, P44 remains the mandatory promoted/rollback baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
