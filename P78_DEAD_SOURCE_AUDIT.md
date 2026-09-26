# P78 Dead Source Audit

## Baseline
- Repository: `a7987083/zonoe-`
- Device-verified baseline: `v1_p76`
- Baseline runtime SHA: `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`
- P78 branch: `work/p78-dead-source-audit`

## Full static audit
- `.m/.mm/.h` files audited under `testmod/`: **203**
- Initial SAFE_DELETE (not in target + no refs): **0**
- Known compatibility forwarding surfaces: **4 files** (`daochucd.m/.h`, `PubgLoad.mm/.h`)
- Initial REVIEW: **58**
- Initial ACTIVE: **141**

## Zero-external-reference target members
Seven target members had zero external static/dynamic references and required manual implicit-entry review:

1. `testmod/category/wyURLProtocol.h`
2. `testmod/工具箱/Hook/BUPlayableAd.h`
3. `testmod/工具箱/Hook/JiangHuHook.h`
4. `testmod/工具箱/Hook/JiangHuHook.m`
5. `testmod/工具箱/变速器/HookClass.h`
6. `testmod/工具箱/变速器/HookClass.m`
7. `testmod/工具箱/变速器/ZSHeader.h`

Manual review proved:
- `JiangHuHook.m` is **ACTIVE** through `CHConstructor` and installs CaptainHook hooks without an external caller.
- `HookClass.m` is **ACTIVE** through Objective-C `+load` and installs a fishhook for `gettimeofday` without an external caller.
- Their matching headers are retained with their implementations.

The following three headers were proven dead and removed:
- `testmod/category/wyURLProtocol.h` — orphan declaration, no implementation, no registration, no reference.
- `testmod/工具箱/Hook/BUPlayableAd.h` — declaration-only header, not imported by current hook runtime and no other reference.
- `testmod/工具箱/变速器/ZSHeader.h` — legacy aggregate macro header, no imports/references.

The corresponding PBXBuildFile/PBXFileReference/PBXGroup/PBXHeadersBuildPhase entries were also removed.

## Cleanup runtime candidate
- Actual cleanup commit: `6b5841e8c76ba54ca0d97749fb198b40ef8bc4fb`
- CI Run: `36256085072`
- migrate: **success**
- inherited P65-P76 contracts: **success**
- A_customer Xcode 16.4 build: **success**
- B_debug Xcode 16.4 build: **success**
- dylib verification/upload: **success**

## Binary-equivalence proof
P78 output dylib hashes are byte-identical to the promoted P76 outputs:

- A_customer SHA256: `9e7310cc52ac44bcd34e31fcd20df28474c46f79bea675be5ae60b7306af5e2e`
- B_debug SHA256: `ac336bad7cd75b6e197a6aa1dee65c1475adfca459f998cf5a29a5a0911d6456`

Therefore this first cleanup changes repository/project metadata only and does not change the produced dylib bytes.

## Status
- P76 remains the promoted/device-verified runtime baseline until explicit device confirmation.
- P78 is a cleanup candidate with CI PASS.
- `WX_NongShiFu123.mm` remains frozen.
- Remote-restore P77 remains abandoned after device regression.

## Next audit targets
The next phase should focus on compiled files that have references only through legacy compatibility layers, while explicitly preserving `+load`, constructor, CaptainHook, fishhook, Objective-C category and runtime-selector entry points.
