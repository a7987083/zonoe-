# KNOWN ISSUES

## P0
1. Legacy authorization secrets/configuration are embedded in client source (`Bsphp/Config.h`). Treat them as recoverable and rotate during future backend migration.
2. Legacy project/target deployment settings are inconsistent (project 8.0 vs target 13.0 observed). Production CI explicitly builds with iOS 12.0; normalization remains separate work.

## P1
1. Current `+load` bootstrap still performs framework probing/dlopen/menu startup early. Any lifecycle cleanup must be a separately verified phase.
2. Large legacy files still mix network/auth/UI/runtime responsibilities, notably `Bsphp/WX_NongShiFu123.mm` and tooling sources.
3. Repository still contains generated/user-specific Xcode state and old package artifacts that require careful cleanup.

## P2
1. Legacy AFNetworking remains for compatibility; new networking should stay isolated.
2. External dylib loading still needs a production manifest/hash/signature policy before remote distribution.
3. Other p19-p26 ZONCore helpers remain header-oriented. p28 intentionally integrates only `ZONMenuCoordinator.m`; do not bulk-convert remaining ZONCore files without an isolated phase and regression proof.

## Resolved
- p26 Menu Coordinator runtime ownership change: passed device regression.
- p27 public-header `@implementation` risk: resolved by interface-only header + `.m` implementation; p27 passed device regression.
- p27 temporary direct `.m` compilation bridge: resolved in p28 by explicit Xcode target source integration; A/B CI passed.
- Previously suspected keyboard/presentation problem: closed as a test/user-side mistake; no code change required.

## Regression-sensitive behavior
- Floating icon/tap/drag behavior.
- Menu open/close/outside-tap close.
- Section render/fold/relayout/layout refresh.
- Card/grid/switch/ad-switch/slider dispatch.
- Authorization, UDID, VIP cloud save and clear-game-data behavior.
- Backup/restore, downloader, file browser, memory, hook and speed functions remain reachable.
