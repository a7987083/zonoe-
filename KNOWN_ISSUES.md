# KNOWN ISSUES

## P0
1. Legacy authorization secrets/configuration are embedded directly in client source (`Bsphp/Config.h`). Treat current values as exposed and rotate during backend migration.
2. Build settings contain inconsistent deployment targets (project-level 8.0 vs target-level 13.0 observed). Production target is iOS 12.0+ and must be normalized carefully.

## P1
1. Current `+load` path performs framework probing/dlopen and menu startup immediately; this can be fragile across host apps. Move toward a minimal bootstrap and deferred UI initialization without changing behavior.
2. Main menu logic is concentrated in `菜单/PopupMenuVC.m`; feature registration and UI rendering are tightly coupled.
3. Large legacy files mix network/auth/UI/runtime responsibilities, notably `Bsphp/WX_NongShiFu123.mm` and tooling sources.
4. Repository contains generated/user-specific Xcode state (`xcuserdata`, `UserInterfaceState.xcuserstate`, breakpoints) and built package artifacts.
5. Several source placeholders are one-byte files; confirm whether intentional before deletion.

## P2
1. Legacy AFNetworking is retained for compatibility; new networking should be isolated so transport can be replaced later.
2. External dylib loading needs ABI/version/hash/signature policy before remote module distribution is considered production-safe.

## Regression-sensitive behavior
- Floating icon must still appear in currently supported host apps.
- Existing BS/PHP activation/session behavior must not change during compatibility phase.
- Existing backup/restore, downloader, file browser, memory, hook and speed functions must remain reachable.
