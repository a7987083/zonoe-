# zonoemenu HANDOFF

## Repository
- Repository: a7987083/zonoe-
- Stable branch: main
- Production branch: dev/zonoemenu-production-v1
- Stable baseline commit: 68329ee5844f3899d369a778073e5586d8bc4e1f

## Product goal
Build zonoemenu as a production-grade universal iOS injected dylib menu.

## Hard constraints
- Primary runtime: non-jailbroken IPA injection.
- Secondary runtime: jailbreak injection (MobileSubstrate/ElleKit compatible path).
- Minimum iOS: 12.0.
- Architectures: arm64 + arm64e.
- Existing features must remain functional during migration.
- Existing BS/PHP authorization is compatibility baseline; replace later behind a service abstraction.
- zonoemenu is the universal host/core menu, not a game-specific implementation.
- Game/project-specific functionality must be loadable later via dlopen() as external dylib modules.
- Prefer minimal-risk migration over rewrite.

## Existing functional baseline
- Floating menu entry.
- PopupMenuVC menu UI.
- Remote download.
- VIP cloud save.
- Local file browser.
- Import/export.
- Backup/restore.
- Memory tooling.
- Hook tooling.
- Speed controls.
- Authorization/config persistence.

## Current important files
- Bsphp/main.m: current dylib +load bootstrap.
- Bsphp/Config.h: legacy BS/PHP client configuration.
- Bsphp/WX_NongShiFu123.mm: legacy auth/business logic.
- 菜单/PopupMenuVC.m: current main menu UI.
- 工具箱/: hook/memory/runtime tooling.
- testmod.xcodeproj/project.pbxproj: Xcode dylib target.

## Migration strategy
1. Freeze current main as stable baseline.
2. Add production documentation and build invariants.
3. Introduce Core bootstrap/environment/logger without changing feature behavior.
4. Introduce module registry and external dylib loader.
5. Wrap legacy BS/PHP behind ZONAuthService-compatible adapter.
6. Split UI/features gradually; retain old implementations until each replacement is verified.
7. Add CI build + smoke/static tests.
8. Remove committed generated/user files only after reproducible build is confirmed.

## Verification state
- Source audit: partial, core structure confirmed.
- Build: not yet run on production branch.
- Runtime verification: not yet run.
- Regression verification: not yet run.

## Next Task
Add the production bootstrap/module ABI with no behavior regression, then wire it into the current load path and build-test the dylib.
