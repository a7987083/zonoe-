# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read `ROADMAP.md` first and `PROJECT_STATE.json` second. If chat history conflicts with them, repository docs win.

## Current promoted baseline
- Version: `v1_p44`.
- Product source: `aee574d180da7cc82db54be7ab5aeaa9d072c561`.
- CI Run `35020232205`: success.
- Real-device validation: passed, explicitly reported by user.
- Active Sources: 78.
- P44 is the rollback/device baseline until a later candidate explicitly passes its real-device gate.

## P45 state
- Version: `v1_p45`.
- Product source: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`.
- CI Run `35036655523`: success.
- Active Sources: 79.
- Device status: **pending / not promoted separately**.
- `ZONLegacyUDIDFallbackAdapter.h/.m` mechanically hides the existing `WX_NongShiFu123 getUDID:` fallback details from `ZonoeUDIDAPI.m`.
- P45/P44 exports and load libraries are identical.

## P46 — current candidate
- Version: `v1_p46`.
- Work branch: `work/zonoemenu-v1-p46-launch-contract`.
- Test branch: `test/zonoemenu-v1-p46-launch-contract-build`.
- Product source commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- Successful CI head: `4cb21f21c76b359fbf7ad13e7d514df39ce83645`.
- CI Run `35167182449`: **success**.
- Active Sources: **79**, unchanged from P45.
- PBX versus P45: byte-identical.
- A_customer artifact: `10475352058`, digest `sha256:79c34fd78c0071ed2a865ee24082806f6289e5a6615a0d022446dc6aa84ad0e1`.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- B_debug artifact: `10475337852`, digest `sha256:7cf081e2956a0a293f6deafbea20c680350dbf5356f87edfdc4affba915fb6dd`.
- Architectures: `arm64 + arm64e`.
- P46/P45 exports and load libraries: identical.
- Device status: **pending**.

## P46 implementation
`testmod/ZONServices/ZONLaunchTrace.h` is header-only and uses:
- `mach_absolute_time()` for monotonic uptime;
- `NSLog` with `[zonoemenu][TRACE][launch]`;
- legacy `os_signpost_event_emit` under subsystem `com.zonoemenu.launch` / category `startup` for iOS 12-compatible Instruments visibility.

Trace points were inserted without moving existing statements in:
- `testmod/Bsphp/main.m`;
- `testmod/ZONBootstrap/ZONBootstrap.m`;
- `testmod/ZONCore/ZONModuleLoader.m`;
- `testmod/ZONServices/ZONAuthorizationCoordinator.m`;
- `testmod/ZONServices/ZONLegacyUDIDFallbackAdapter.m`;
- `testmod/视图菜单/NSObject+UI.m`.

Events cover `+load`, reset install, Bootstrap/preflight, variant entry, authorization cached/fresh paths, legacy fallback, module scan/load, floating-entry attach and menu presentation.

## P46 proof of observational-only behavior
`Tests/p46_launch_contract.py` enforces:
- removing `ZONLaunchTrace.h` imports and every `ZONLaunchTraceRecord(...)` line restores all touched runtime files exactly to P45 content;
- protected authorization/UDID/legacy/menu runtime files remain byte-identical to P45;
- `testmod.xcodeproj/project.pbxproj` is byte-identical to P45;
- Active Sources remain 79;
- the trace header contains no `dispatch_async`, `dispatch_after`, timers, sleeps or other scheduling primitives;
- key startup order in `main.m` is unchanged.

A separate iPhoneOS arm64 trace probe compiles with `-Wall -Wextra -Werror`.

## Runtime chain to preserve
```text
dyld
  -> main.m +load
     -> authorization reset install
     -> ZONBootstrapStart
        -> AppLovinSDK / UnityFramework preflight
        -> A_customer authorization or B_debug floating entry
        -> ZONLoadBundledModules
           -> module directory scan / dlopen
        -> bootstrap ready
  -> floating entry/menu lifecycle
```
P46 observes this chain only. It does not authorize reordering or optimization.

## Important current risk
P46 is built on P45, and P45 never received a separate explicit device PASS. Therefore a P46 device PASS must cover the inherited P45 fallback behavior as well as launch instrumentation. Do not mark P45 or P46 promoted based on CI alone.

## Real-device gate for P46
1. Normal existing/cached `DZUDID` startup and authorization remain normal.
2. Fresh Zonoe acquisition returns and authorization continues normally.
3. Where practical, force Zonoe unavailable and verify legacy fallback starts once, valid `DZUDID` resumes authorization, and foreground return does not duplicate/loop/crash.
4. Confirm `[zonoemenu][TRACE][launch]` events are emitted in the expected lifecycle order; no trace point may introduce a visible stall or behavior change.
5. Floating icon appears, menu opens/closes, and basic controls smoke normally.

## Takeover rules
- Never optimize startup timing based only on source inspection; use P46 device trace evidence first.
- Do not change `+load`, queues, timeouts, retries, callback order or module loading timing during structural cleanup.
- Verify PBX membership before deleting/moving code.
- One architectural concern per version.
- CI success never equals device promotion.

## Immediate Next Task
Real-device validate P46 A_customer with the combined P45+P46 gate above. Keep P44 as rollback. If P46 passes, promote P46 directly (P45 may remain an intermediate CI-verified version) and start P47 repository hygiene.