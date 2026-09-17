# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- P44 CI Run `35020232205`: success; real-device validation passed.
- P45 source `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`: CI success, device status pending/not promoted separately.
- P46 source `83a49f46c1d0e4eecf5a52a485ebc35442786f67`: CI Run `35167182449` success, device status pending.
- P46 Active Sources: 79; PBX unchanged from P45.
- Canonical plan: `ROADMAP.md`.

## Open risks

### P46 real-device launch/lifecycle gate pending
- P46 is CI-verified as observational-only: removing all trace imports/calls restores the touched runtime files exactly to P45 and the PBX remains byte-identical.
- Static/build checks cannot prove that extra logging/signpost calls have no device-visible timing/lifecycle side effect.
- Required device evidence: normal startup/auth, fresh UDID path, launch trace sequence, module load, floating entry/menu smoke, no visible freeze/crash/regression.
- Rollback remains P44 until explicit P46 device PASS.

### P45 fallback behavior was never promoted separately
- P45 mechanically isolated `WX_NongShiFu123 getUDID:` fallback behind `ZONLegacyUDIDFallbackAdapter` and CI passed.
- User did not explicitly report a P45 real-device PASS before P46 development began.
- P46 contains the P45 runtime, so P46 promotion must include the P45 device gate: fallback starts only when Zonoe is unavailable, one-in-flight guard works, valid `DZUDID` resumes authorization, invalid/empty result does not crash/loop, and foreground return does not duplicate fallback.

### Global startup side effects remain order-sensitive
- `main.m +load`, framework preflight, Bootstrap, authorization, module loading and floating-entry lifecycle are still order-sensitive.
- P46 only measures/records this ordering; it does not authorize optimization or reordering.
- Any later startup simplification must use P46 device trace evidence first.

### Instrumentation overhead exists by design
- `ZONLaunchTraceRecord` performs `NSLog`, monotonic timestamp conversion and `os_signpost_event_emit` at defined lifecycle points.
- CI confirms no new queues/timers/sleeps and unchanged ABI/load libraries, but only device testing can establish that this observational overhead is acceptable in the real launch path.

### `WX_NongShiFu123.mm` remains a high-risk legacy god object
- It remains active and still owns `loada`, authorization/network/server state, UDID/IDFV branches, activation UI and status behavior.
- P45 only hides its fallback entry behind an adapter; it does not rewrite the legacy implementation.
- Any P48 split must be evidence-driven, one responsibility at a time.

### Other large active legacy surfaces remain coupled
- `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain active/candidate legacy units.
- `JiangHuHook.m` remains a protected runtime-hook surface; opportunistic cleanup can alter StoreKit/ad/video/menu behavior.

### Repository hygiene
- Generated/package binaries, user-specific Xcode state and historical/reproducible material may remain tracked.
- P47 must remove only items proven not to be PBX/script/release/runtime inputs.

### Dead-code assumptions can be wrong
- Historical audits showed apparently stale dependencies may still be live, including JDStatusBarNotification paths.
- PBX membership, caller/import reachability and runtime/symbol evidence are required before deletion.
- P49 performs the dedicated dead-code/dependency audit.

## Closed / corrected

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