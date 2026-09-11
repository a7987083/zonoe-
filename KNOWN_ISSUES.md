# KNOWN ISSUES

## P0
1. Legacy authorization secrets/configuration are embedded directly in client source (`Bsphp/Config.h`). Treat current values as exposed and rotate during backend migration.
2. Build settings contain inconsistent deployment targets (project-level 8.0 vs target-level 13.0 observed). Production target is iOS 12.0+ and must be normalized carefully.

## P1
1. Current `+load` path performs framework probing/dlopen and menu startup immediately; this can be fragile across host apps. Move toward a minimal bootstrap and deferred UI initialization without changing behavior.
2. `v1_p26` has completed the structural split of `PopupMenuVC` into a compatibility shell plus `ZONMenuCoordinator`, but this new ownership boundary has only CI/static verification so far. Treat it as unverified for device runtime until the p26 regression checklist passes.
3. Large legacy files still mix network/auth/UI/runtime responsibilities, notably `Bsphp/WX_NongShiFu123.mm` and tooling sources.
4. Repository contains generated/user-specific Xcode state (`xcuserdata`, `UserInterfaceState.xcuserstate`, breakpoints) and built package artifacts.
5. Several source placeholders are one-byte files; confirm whether intentional before deletion.

## P2
1. Legacy AFNetworking is retained for compatibility; new networking should be isolated so transport can be replaced later.
2. External dylib loading needs ABI/version/hash/signature policy before remote module distribution is considered production-safe.
3. `ZONMenuCoordinator.h` currently contains both interface and implementation. This is safe with the current single importing compilation unit, but importing it from multiple translation units would create duplicate implementation/link risk. Do not refactor solely for style; split to `.h/.m` only when needed or during a separately verified structural phase.

## Regression-sensitive behavior
- Floating icon must still appear in currently supported host apps.
- Tap must open the menu; drag must not false-open.
- Menu outside-tap close, section fold/unfold, relayout and rotation/layout refresh must remain correct after p26 coordinator ownership changes.
- Existing card/grid actions, switches, ad switch and slider must preserve dispatch behavior.
- Existing BS/PHP activation/session behavior must not change during compatibility phase.
- Existing authorization, UDID, VIP cloud save and clear-game-data behavior must not change in p26.
- Existing backup/restore, downloader, file browser, memory, hook and speed functions must remain reachable.

## Not part of p26
The separately observed keyboard/presentation issue is intentionally excluded from the Menu Coordinator change set. Do not mix its diagnosis/fix into p26 regression work.
