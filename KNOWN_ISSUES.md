# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- P44 CI Run `35020232205`: success; real-device validation passed.
- P45 source `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`: CI success, not promoted separately.
- P46 runtime source `83a49f46c1d0e4eecf5a52a485ebc35442786f67`: CI Run `35167182449` success, device status pending.
- P47 repository candidate `64f8575966d62695123b9f8444f89dbc98e796df`: CI Run `35169166129` success; runtime/product trees byte-identical to P46; promotion blocked on inherited P46 device gate.
- Active Sources: 79 for P45-P47 runtime.
- Canonical plan: `ROADMAP.md`.

## Open risks

### P46/P47 combined real-device launch/lifecycle gate pending
- P47 does not change runtime; its A_customer dylib SHA256 is exactly the same as P46: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- P46 is CI-verified as observational-only, but static/build checks cannot prove that logging/signpost calls have no device-visible timing/lifecycle effect.
- One explicit P47 device PASS can cover the pending P46 runtime gate because the P47 candidate binary is byte-identical to P46.
- Required evidence: normal startup/auth, fresh UDID path, inherited legacy fallback where practical, launch trace sequence, module load, floating entry/menu smoke, no freeze/crash/regression.
- Rollback remains P44 until explicit PASS.

### P45 fallback behavior was never promoted separately
- P45 mechanically isolated `WX_NongShiFu123 getUDID:` fallback behind `ZONLegacyUDIDFallbackAdapter` and CI passed.
- No separate explicit P45 real-device PASS was recorded before P46/P47 work.
- Combined promotion gate must therefore verify fallback starts only when Zonoe is unavailable, one-in-flight guard works, valid `DZUDID` resumes authorization, invalid/empty result does not crash/loop, and foreground return does not duplicate fallback.

### Global startup side effects remain order-sensitive
- `main.m +load`, framework preflight, Bootstrap, authorization, module loading and floating-entry lifecycle remain order-sensitive.
- P46 measures/records this ordering; P47 does not alter it.
- Any later startup simplification must use device trace evidence first.

### Instrumentation overhead exists by design
- `ZONLaunchTraceRecord` performs `NSLog`, monotonic timestamp conversion and `os_signpost_event_emit` at defined lifecycle points.
- CI confirms no new queues/timers/sleeps and unchanged ABI/load libraries, but device testing is still required to establish acceptable launch behavior.

### `WX_NongShiFu123.mm` remains a high-risk legacy god object
- It remains active and still owns `loada`, authorization/network/server state, UDID/IDFV branches, activation UI and status behavior.
- P45 only hides its fallback entry behind an adapter; it does not rewrite the legacy implementation.
- P48 must select exactly one responsibility from evidence and move it mechanically first.

### Other large active legacy surfaces remain coupled
- `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain active/candidate legacy units.
- `JiangHuHook.m` remains a protected runtime-hook surface; opportunistic cleanup can alter StoreKit/ad/video/menu behavior.

### Historical CI/scripts remain intentionally tracked
- P47 did not delete historical phase scripts/tests/workflows because they provide reproducibility and audit evidence.
- Their age is not evidence of deadness. Any future removal requires explicit reachability/policy proof.

### Dead-code assumptions can be wrong
- Historical audits showed apparently stale dependencies may still be live, including JDStatusBarNotification paths.
- PBX membership, caller/import reachability and runtime/symbol evidence are required before deletion.
- P49 performs the dedicated dead-code/dependency audit.

## Closed / corrected

### Tracked generated package ZIP — CLOSED BY P47
- `Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip` was the sole tracked `Packages/` entry and had no repository consumers by exact filename / path searches.
- P47 removed it and added narrow ignore rule `Packages/*.zip`.
- P47 contract proves canonical product trees remain byte-identical to P46 and Active Sources remain 79.

### P44 device validation — CLOSED
- P44 source `aee574d180da7cc82db54be7ab5aeaa9d072c561`, CI `35020232205`.
- User explicitly reported real-device validation normal.
- P44 is the current promoted/device rollback baseline.

### Authorization orchestration mixed into main.m — CLOSED
- P44 mechanically moved the selected authorization/reset block into `ZONAuthorizationCoordinator.h/.m` and passed CI/device validation.

### ZonoeUDIDAPI ownership mixed with UI — CLOSED
- Closed by P42; later device-verified baselines cover it.

### ZONUDIDBridge implementation-heavy header — CLOSED
- Closed by P41 and covered by later device-verified baselines.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership is authoritative.

## Tracking rule
Move an open risk to fully closed only after the required CI and, where applicable, real-device gate passes. Source edits or CI success alone do not equal promotion.
