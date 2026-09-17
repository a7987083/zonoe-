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

## Intermediate runtime history
### P45
- Product source: `841da61c51e8c7fef81c15a56ecdb92c31b9f96d`; CI Run `35036655523`: success.
- Added the legacy UDID fallback adapter; Active Sources became 79.
- No separate explicit device promotion was recorded.

### P46
- Runtime source: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`; CI Run `35167182449`: success.
- Added header-only `ZONLaunchTrace.h`; PBX stayed unchanged from P45 and Active Sources stayed 79.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- Device status remains pending; its gate includes P45 fallback behavior.

## P47 — current candidate
- Version: `v1_p47`.
- Work branch: `work/zonoemenu-v1-p47-repository-hygiene`.
- Test branch: `test/zonoemenu-v1-p47-repository-hygiene-build`.
- Repository candidate commit: `64f8575966d62695123b9f8444f89dbc98e796df`.
- Runtime source remains P46: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- Successful CI head: `eed8c8aca74a8c6e6985848a11c76d5a52cc2f40`.
- CI Run `35169166129`: **success**.
- Active Sources: **79**.
- `testmod/` and `testmod.xcodeproj/`: byte-identical to P46.
- A_customer artifact: `10476362290`, digest `sha256:f913b210dd80e2438af1bfc13b8b8b3aafe3ab3837c8d4507935abb10adfdfe5`.
- A_customer dylib SHA256: `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2` — byte-identical to P46.
- B_debug artifact: `10476157646`, digest `sha256:d2f57b2f041b533a40dcfdec43e691c274822b97214deeeb5acaac3e115a7bcd`.
- Architectures: `arm64 + arm64e`.
- P47/P46 exports and load libraries: identical.
- Device status: **inherits P46 combined gate / pending**.

## P47 repository changes
- Removed tracked generated package `Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip` after repository searches found no consumers.
- Added narrow `.gitignore` rule `Packages/*.zip`.
- Existing ignores already cover Xcode user state, build/DerivedData, dylib/deb/dSYM, `.DS_Store`, and local secrets/config.
- Historical phase scripts, tests, audit docs, and workflows remain intentionally tracked as reproducibility/evidence material.
- `P47_REPOSITORY_HYGIENE_AUDIT.md` documents the evidence and boundary.

## Proof that P47 does not change runtime
`Tests/p47_repository_hygiene_contract.py` enforces:
- `testmod/` tree equals P46 exactly;
- `testmod.xcodeproj/` tree equals P46 exactly;
- Active PBX Sources remain 79;
- removed package ZIP does not return;
- no tracked Xcode user/build/package ZIP debris;
- required ignore rules remain present.

The P47 CI also runs the inherited P46 launch contract, builds A_customer/B_debug for arm64+arm64e, and compares exports/load libraries with P46. The final P47 A_customer dylib SHA equals P46 exactly.

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
P47 does not modify this chain.

## Important current risk / promotion rule
P47 itself adds no runtime behavior, but P46 was never explicitly device-promoted and P45 was not separately promoted either. Because the P47 A_customer dylib is byte-identical to P46, one explicit real-device PASS on P47 can satisfy the pending combined P45/P46 runtime gate while simultaneously allowing P47 promotion. Until that PASS, keep P44 as rollback/device baseline.

## Real-device gate for P47 (inherited P46 combined gate)
1. Normal existing/cached `DZUDID` startup and authorization remain normal.
2. Fresh Zonoe acquisition returns and authorization continues normally.
3. Where practical, force Zonoe unavailable and verify legacy fallback starts once, valid `DZUDID` resumes authorization, and foreground return does not duplicate/loop/crash.
4. Confirm `[zonoemenu][TRACE][launch]` events appear in plausible lifecycle order without visible stalls.
5. Floating icon appears, menu opens/closes, and basic controls smoke normally.

## Takeover rules
- Never optimize startup timing based only on source inspection; use device trace evidence first.
- Do not change `+load`, queues, timeouts, retries, callback order or module loading timing during structural cleanup.
- Verify PBX membership and repository reachability before deleting/moving code.
- One architectural concern per version.
- CI success never equals device promotion.
- For P48, re-read P43/current reachability evidence and select exactly one legacy responsibility; do not guess a target from chat memory.

## Immediate Next Task
Real-device validate the P47 A_customer candidate using the combined inherited gate above. If explicitly passed, promote P47, record that P46 runtime gate is covered/superseded by the byte-identical P47 device result, then define P48 — Legacy God-Object Split #1 from current evidence.
