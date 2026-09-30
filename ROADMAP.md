# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d/e` suffixes.

## Current active stage — P79.8e Architecture/Test Hardening — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8e`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Product behavior baseline: P79.8d injected passive Satella trigger, inheriting P79.8c menu permissions, P79.8b persistence cleanup and device-passed P79.8a UDID-first authorization.
- P79.8e is intentionally behavior-preserving: no production `.m` runtime logic changed.
- Removed the unfinished/orphan public declaration introduced after P79.8d.
- Updated `Tests/dispatcher_contract_smoke.py` to current service/coordinator routing.
- Added `Tests/p79_8d_passive_satella_contract.py` for the exact passive image/signature/RVA/PAC/one-shot contract.
- Expanded P79 workflow path coverage to `ZONCore`, `ZONServices`, project-file and current contract-test changes.
- VERSION/build HEAD: `3050a4337ef481f6955b5f9d2000fcde8bd327d3`.
- CI Run `36718795572` / run #40: success.
- Artifact ID `11096879463`, digest `sha256:83c8e47a9eb1a679d8a56eef69bdc0c48e6e475042f526600d5070391ec88eef`.
- Raw CI dylib SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- P79.8e raw dylib is byte-for-byte identical to P79.8d raw dylib (`cmp` equal, same SHA256 and size 3,246,160 bytes).
- CI contract tests: PASS.
- Xcode 16.4 `arm64 + arm64e` build: PASS.
- Real-device promotion is not inferred; functional device gates remain those of P79.8d/P79.8c/P79.8b.

### Next architecture stages
1. R2 — extract passive injected-image probing/invocation from `ZONFeatureDispatcher` into a dedicated runtime-capability boundary without changing behavior.
2. R3 — introduce a feature-access context so renderers/dispatchers do not parse raw AuthV2 storage independently; this will support future “show button only when external dylib is loaded” cleanly.
3. R4 — migrate dictionary-only feature metadata toward typed descriptors while preserving identifiers/tags/order exactly.
4. R5 — decompose `ZONAuthV2Flow` beginning with pure authorization decision parsing, then orchestration/presentation separation.
5. R6 — measure startup/preflight/module-load timing before any optimization or reordering.
6. R7 — classify active vs historical tests/workflows/generated artifacts before cleanup.

## Functional baseline — P79.8d Injected Passive Satella Trigger
- VERSION: `v1_p79_8d`.
- Trigger implementation commit: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- Build HEAD: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`.
- CI Run `36604169367` / #38: success.
- Controlled final test dylib SHA256: `bd5b3ca738d6e8041d16b57c4515dffb6f47806da412b0b5f8bd512e1f09d6cd`.
- The host does not `dlopen` Satella; another injection layer must preload it.
- Accepted names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Validate RVA `0x847C` ARM64 `RET` and RVA `0x888C` 16-byte init prologue before call.
- Invoke `image_base + 0x888C` on main thread; arm64e PAC-signs the function pointer.
- One-shot per process; OFF does not unload/deinit; missing target does not roll back original IAP/iGameGod state.

### Device gates inherited from P79.8d
- Matching injected passive dylib: first ON logs `validated`, `init=...`, `started` and functionality activates.
- Second ON in same process: `already_started`; no second init.
- No injected passive dylib: original IAP/iGameGod toggle still works; log `image_not_loaded_or_invalid`.
- Mismatched target: fail closed before jump.
- Confirm P79.8c VIP cloud-save permissions, P79.8b persistence behavior and P79.8a UDID-first authorization remain unchanged.

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
Proceed with R2 only after keeping P79.8d runtime behavior fixed: isolate passive capability probing/invocation behind a dedicated service, then prove source-contract, arm64/arm64e build and real-device equivalence before using that boundary for the future new external-dylib button.
