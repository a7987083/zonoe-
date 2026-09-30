# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8e Architecture/Test Hardening
- VERSION: `v1_p79_8e`.
- Product behavior baseline remains P79.8d; P79.8e changes verification infrastructure only.
- Build HEAD: `3050a4337ef481f6955b5f9d2000fcde8bd327d3`.
- CI Run `36718795572` / #40: success.
- Artifact ID `11096879463`, digest `sha256:83c8e47a9eb1a679d8a56eef69bdc0c48e6e475042f526600d5070391ec88eef`.
- Raw CI SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Raw P79.8e dylib is byte-identical to raw P79.8d (`cmp` equal; size 3,246,160 bytes).
- Current Dispatcher service-routing contract test: PASS.
- P79.8d passive injected-module contract test: PASS.
- Xcode 16.4 arm64 + arm64e build: PASS.
- No real-device promotion was made from CI alone.

## What changed in P79.8e
1. Removed the orphan `ZONInjectedPassiveSatellaAvailable` header declaration that had no implementation/use and was added after the P79.8d verified build.
2. Rewrote `Tests/dispatcher_contract_smoke.py` to describe current service/coordinator routing instead of obsolete direct `PubgLoad/daochucd/YYYPicker/WX_NongShiFu123` calls.
3. Added `Tests/p79_8d_passive_satella_contract.py` to lock accepted image names, RVAs, binary signatures, no-dlopen ownership, PAC, main-thread and one-shot semantics.
4. Expanded the active P79 workflow to trigger for `ZONCore`, `ZONServices`, project-file and current test changes, and to run these contracts before Xcode build.
5. Refreshed `ARCHITECTURE.md` and `REFACTOR_REVIEW.md` to the current P79 tree.

## Current architecture ownership
- Startup: `Bsphp/main.m +load` → `ZONBootstrap`.
- Customer identity/entry: `ZONAuthorizationCoordinator` + `ZonoeUDIDAPI`/bridge.
- Authorization state machine: `ZONAuthV2Flow` → `ZONAuthV2API` → Runtime Config/`ZONAuthV2Verify`.
- Menu: `ZONMenuCoordinator` → section/feature renderers → `ZONMenuEventBridge` → `ZONFeatureDispatcher`.
- Business actions: service/coordinator layer under `testmod/ZONServices`.
- Formal plugin loading: `ZONModuleLoader` ABI boundary.
- Passive Satella: externally preloaded image, dyld probe + signature/RVA validation in Dispatcher, no host `dlopen`.

## Highest-priority next refactors
- R2: extract passive runtime capability probing/invocation from Dispatcher without changing any binary contract.
- R3: introduce one feature-access provider combining server permissions and local runtime capabilities; renderer should not parse raw AuthV2 storage.
- R4: migrate feature metadata from string-key dictionaries toward typed descriptors.
- R5: split `ZONAuthV2Flow` starting with pure decision parsing; do not combine protocol/state/UI decomposition into one large rewrite.
- R6: measure `+load`/preflight/module-load startup cost before optimizing.

## P79.8d passive behavior that must remain exact
- Trigger feature: `runtime.iap-noads` / `内购破解+ iGameGod去广告`.
- Existing `NNGG`, `NNGGNNGG`, `ImgTool.NeiGou` semantics remain first-class behavior.
- Accepted names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- `0x847C` must be ARM64 `RET`; `0x888C` must match the expected 16-byte init prologue.
- Main-thread invocation; arm64e PAC; one-shot per process; no OFF unload/deinit.
- Missing/invalid target does not roll back original toggle.

## Inherited authorization/menu contracts
1. Acquire/reuse Keychain `DZUDID` first.
2. `/apiface` determines active UDID activation before card prompt.
3. Verify determines current-App applicability and server permissions.
4. P79.8c `VIP云存档`: `extra_menu` visibility + `extra_features` action + fresh Verify before download.
5. P79.8b AuthV2 response/config/card state remains memory-only; notice fingerprint is the only intended persistent AuthV2 default.

## Last device-passed baseline
- P79.8a / `v1_p79_8a`.
- CI Run `36572203902` / #32.
- Controlled final SHA256: `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Fresh App + already-activated UDID was confirmed to work without card re-entry.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Do not commit or print the real/test Verify Secret.
- Historical phase tests are evidence, not automatically part of the active suite; refresh/classify them before global execution.
