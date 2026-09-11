# KNOWN ISSUES

## P0
1. Legacy authorization secrets/configuration are embedded directly in client source (`Bsphp/Config.h`). Treat current values as exposed and rotate during backend migration.
2. Build settings contain inconsistent deployment targets (project-level 8.0 vs target-level 13.0 observed). Production CI explicitly builds for iOS 12.0+; normalization must be handled carefully.

## P1
1. Current `+load` path performs framework probing/dlopen and menu startup immediately; this can be fragile across host apps. Move toward a minimal bootstrap and deferred UI initialization only in a separately verified phase.
2. Large legacy files still mix network/auth/UI/runtime responsibilities, notably `Bsphp/WX_NongShiFu123.mm` and tooling sources.
3. Repository contains generated/user-specific Xcode state (`xcuserdata`, `UserInterfaceState.xcuserstate`, breakpoints) and built package artifacts.
4. Several source placeholders are one-byte files; confirm whether intentional before deletion.

## P2
1. Legacy AFNetworking is retained for compatibility; new networking should remain isolated so transport can be replaced later.
2. External dylib loading needs ABI/version/hash/signature policy before remote module distribution is production-safe.
3. The p19-p27 `ZONCore` files are not explicitly enumerated in the legacy Xcode target. p27 resolves the previous `ZONMenuCoordinator.h` interface+implementation problem by making the public header interface-only and moving implementation to `ZONMenuCoordinator.m`, but `PopupMenuVC.m` still imports that `.m` exactly once as a compatibility compilation bridge. Proper PBX target integration remains a future cleanup and should be verified separately.

## Resolved / closed
- `v1_p26` Menu Coordinator ownership boundary: device/runtime regression passed; p26 is the current device-verified structural baseline.
- Previous risk: `ZONMenuCoordinator.h` contained `@implementation`; resolved in p27 by moving implementation/private dependencies to `.m`.
- Previously suspected keyboard/presentation defect: user confirmed it was a testing mistake. No project fix is required; do not modify keyboard/presentation logic for it.

## Regression-sensitive behavior
- Floating icon must appear; tap opens the menu and drag must not false-open.
- Menu outside-tap close, section fold/unfold, relayout and layout refresh must remain correct.
- Existing card/grid actions, switches, ad switch and slider must preserve dispatch behavior.
- Existing BS/PHP activation/session behavior must not change during compatibility work.
- Existing authorization, UDID, VIP cloud save and clear-game-data behavior must not change in p27.
- Existing backup/restore, downloader, file browser, memory, hook and speed functions must remain reachable.
