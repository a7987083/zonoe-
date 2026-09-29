# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.8d Injected Passive Satella Trigger — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8d`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline: P79.8c server-driven menu permissions + P79.8b persistence cleanup + device-passed P79.8a UDID-first authorization.
- Trigger implementation commit: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- VERSION/build HEAD: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`.
- CI Run `36604169367` / run #38: success.
- Artifact ID `11050622646`, digest `sha256:16569dbb378372b5372dea8e3312549d1fe632f3b85b831dc3d8027ffb445b6e`.
- Raw CI dylib SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Controlled final test dylib SHA256: `bd5b3ca738d6e8041d16b57c4515dffb6f47806da412b0b5f8bd512e1f09d6cd`.
- Controlled final ZIP SHA256: `242a461d27a16a8758c750dbc8ac65ac12f28704996d39d8df9051e5922da3d6`.
- Final artifact: arm64 + arm64e; placeholder `0`; Verify Secret occurrences `2`.

### P79.8d passive trigger contract
1. The menu dylib does **not** load or `dlopen` Satella; the host/injection workflow must inject it before the switch is enabled.
2. Trigger is attached to existing `runtime.iap-noads` / `内购破解+ iGameGod去广告` toggle.
3. Existing `NNGG`, `NNGGNNGG`, and `ImgTool.NeiGou` behavior is preserved.
4. On toggle ON, enumerate already-loaded dyld images and accept only:
   - `1_passive.dylib`
   - `1_passive_zh.dylib`
   - `SatellaJailed_passive.dylib`
5. Validate passive build before calling:
   - image base + `0x847C` must contain ARM64 `RET` bytes `C0 03 5F D6`;
   - image base + `0x888C` must match the expected 16-byte init prologue.
6. If validation succeeds, call image base + `0x888C` on the main thread.
7. arm64e signs the raw function address with the function-pointer PAC key before invocation.
8. The start routine is one-shot per process; later ON events return `already_started` and do not call init again.
9. Toggle OFF does not unload or call an unknown deinitializer.
10. Missing/invalid passive dylib does not roll back the existing iGameGod/IAP toggle; it only records a failure log.

### Device gates for P79.8d
- Inject a known matching passive dylib before opening the switch; first ON must log `validated`, `init=...`, and `started`.
- Confirm the passive feature actually activates after the ON event.
- Toggle OFF then ON again in the same process; init must not execute a second time and log `already_started`.
- Run without injected passive dylib; existing IAP/iGameGod toggle must still work and log `image_not_loaded_or_invalid`.
- Test a mismatched passive build; the trigger must fail closed at ctor/prologue validation and must not jump to `0x888C`.
- Confirm P79.8c VIP cloud-save permissions, P79.8b persistence behavior, and P79.8a UDID-first authorization remain unchanged.

## Inherited server permission contract — P79.8c
- `basic`: `normal_menu=true`, `extra_menu=false`, `extra_features=false`.
- `app_plus`: all three permissions true.
- `global_plus`: all three permissions true.
- `VIP云存档` requires `extra_menu` to render and `extra_features` to execute; actual cloud download re-verifies immediately before download.

## Device-passed baseline — P79.8a
- VERSION: `v1_p79_8a`.
- CI Run `36572203902` / #32: success.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Real-device validation: PASS — fresh App + already-activated UDID skips card input and continues to Verify.

## Protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API base: `https://app3.zonoeios.xyz`
- UDID authorization path: `/index/index/apiface`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_8d`, inject a matching passive dylib, then validate one-shot ON-triggered init plus all inherited authorization/menu/persistence regressions.
