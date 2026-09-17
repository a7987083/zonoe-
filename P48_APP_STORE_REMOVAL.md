# P48 — Remove Legacy App Store Version Checker

## Baseline
- P47 real-device result: PASS as explicitly reported by user.
- P47 A_customer dylib is byte-identical to P46 and therefore closes the inherited P45/P46/P47 device gate.
- P48 runtime predecessor: P47.

## Scope
Remove the legacy App Store version-check category completely rather than extracting it.

Removed product surface:
- `testmod/导入导出/fuzhu.h`
- `testmod/导入导出/fuhzu.m`
- `#import "fuzhu.h"` from `WX_NongShiFu123.mm`
- both `[NSObject checkbanben]` post-activation calls
- all PBX header/source/file/group membership for the removed pair

The deleted implementation contained the international and China `itunes.apple.com` lookup paths, version parsing/comparison, and the associated version metadata caching keys.

## Protected behavior
- Authorization success flow continues directly to `[NSObject 显示图标]` after the removed version-check call.
- No authorization, UDID, fallback, menu, module loading, startup trace, persistence, queue, timeout, or protocol behavior is otherwise changed.
- No replacement App Store checker is introduced.

## Verification
- Active PBX Sources must be exactly 78 (P47 79 minus `fuhzu.m`).
- Canonical runtime must contain none of: `checkbanben`, `checkAppStoreVersionWithAppId`, `compareVersion:`, `compareVersioncn:`, `itunes.apple.com/lookup`, `itunes.apple.com/cn/lookup`, or `#import "fuzhu.h"`.
- A_customer and B_debug must build arm64 + arm64e.
- Exported symbols and load libraries must be compared with P47.
- Real-device promotion remains required because this intentionally changes post-activation behavior by removing the version check.
