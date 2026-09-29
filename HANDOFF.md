# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current target — P79.8d Injected Passive Satella Trigger
- VERSION: `v1_p79_8d`.
- Trigger implementation: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- Build HEAD: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`.
- CI Run `36604169367` / #38: success.
- Artifact ID `11050622646`, digest `sha256:16569dbb378372b5372dea8e3312549d1fe632f3b85b831dc3d8027ffb445b6e`.
- Raw CI SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Controlled final dylib SHA256: `bd5b3ca738d6e8041d16b57c4515dffb6f47806da412b0b5f8bd512e1f09d6cd`.
- Controlled ZIP SHA256: `242a461d27a16a8758c750dbc8ac65ac12f28704996d39d8df9051e5922da3d6`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

## Passive Satella behavior
- Integration point: `runtime.iap-noads` / `内购破解+ iGameGod去广告` toggle in `ZONFeatureDispatcher.m`.
- The menu dylib never `dlopen`s Satella. Another injection layer must preload the passive dylib.
- Accepted loaded-image suffixes: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Current passive-build contract assumes `__TEXT vmaddr = 0` and validates:
  - RVA `0x847C` = ARM64 `RET` (`C0 03 5F D6`);
  - RVA `0x888C` = expected 16-byte init prologue.
- First ON event runs init at `image_base + 0x888C` on the main thread.
- arm64e uses function-pointer PAC signing before the call.
- Startup is one-shot per process (`already_started` on subsequent ON events).
- OFF never attempts unload or deinit.
- Missing/invalid target logs failure but leaves the existing IAP/iGameGod toggle enabled.
- Primary log prefix: `[zonoemenu][P79.8D_SATELLA]`.

## Inherited authorization/menu contracts
1. Acquire/reuse Keychain `DZUDID` first.
2. `/apiface` checks whether the UDID has active activation before card prompt.
3. Active UDID proceeds Runtime Config → Verify; Verify owns App applicability and `permissions`.
4. P79.8c consumes server `permissions`; `VIP云存档` requires `extra_menu` for visibility and `extra_features` for execution.
5. P79.8b keeps AuthV2 response/config/card values in memory; only notice fingerprint is intentionally persistent in AuthV2 UserDefaults.

## Device test order for P79.8d
1. Inject a matching passive dylib before enabling the IAP/iGameGod switch.
2. First OFF→ON: expect `validated`, `init=...`, `started`; verify passive functionality is active.
3. OFF→ON again: expect `already_started`; init must not run twice.
4. No passive dylib injected: expect `image_not_loaded_or_invalid`; original IAP/iGameGod behavior must remain functional.
5. Wrong passive version: expect ctor/prologue mismatch and no jump.
6. Regression: basic hides VIP cloud save; app/global Plus exposes it correctly; UDID-first and persistence behavior remain intact.

## Last device-passed baseline
- P79.8a / `v1_p79_8a`.
- CI Run `36572203902` / #32.
- Controlled final SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- User confirmed fresh App + already-activated UDID works without card re-entry.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized.
- Do not commit or print the real/test Verify Secret.
