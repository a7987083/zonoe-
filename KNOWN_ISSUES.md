# KNOWN_ISSUES

## Current state
- Active architecture-hardening version: `v1_p79_8e`.
- Product behavior baseline: P79.8d.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `3050a4337ef481f6955b5f9d2000fcde8bd327d3`.
- CI Run `36718795572` / #40: success.
- Artifact ID: `11096879463`.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Raw P79.8e output is byte-identical to P79.8d raw output.
- Current-device validation: inherited functional gates remain pending.
- Last device-passed baseline: P79.8a / controlled SHA256 `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.

## Open architecture risks

### Historical contract tests contain stale assumptions
- The active Dispatcher smoke test was corrected in P79.8e.
- Some older phase tests (for example the dispatcher boundary audit) still describe the pre-split/header-only Dispatcher and retired direct handlers.
- Do not treat “run every file under Tests” as a valid current acceptance suite until historical tests are classified or refreshed.

### `ZONAuthV2Flow` still owns too many responsibilities
- It parses server payloads, classifies authorization state, orchestrates activation/config/Verify, maps errors, presents card UI, notices/updates, and opens the floating entry.
- Future changes should first extract pure decision parsing, then orchestration, then presentation boundaries. Avoid a one-shot rewrite.

### Startup remains order-sensitive
- `main.m +load` enters Bootstrap and synchronous legacy framework preflight before the ready block.
- AppLovin/Unity framework lookup/`dlopen`, customer authorization entry and formal module loading should not be reordered without measurement plus real-device validation.

### Dispatcher still mixes routing with runtime capability implementation
- Current Dispatcher owns server-permission denial UI, service route tables, runtime preference side effects and passive injected-image scanning/PAC/invocation.
- The next safe architecture stage should extract only the passive capability boundary while preserving every P79.8d binary compatibility check.

### Renderer reads raw AuthV2 session schema
- `ZONSectionRenderer` directly obtains `lastVerify`, `permissions`, and `access_level` from `ZONAuthV2Storage`.
- This will become increasingly fragile when local runtime capabilities are added beside server permissions.
- Introduce one access/capability provider before implementing the future new external-dylib button filter.

### Feature registry is weakly typed
- Feature/section descriptors are `NSDictionary` values keyed by strings.
- Misspelled metadata keys compile and fail only at runtime.
- Convert incrementally after capability/access boundaries are stable; preserve identifiers, legacy tags, order and section state keys exactly.

### Duplicate Runtime Config parsing helpers
- `ZONAuthV2API.m` and `ZONAuthV2Verify.m` each implement nested config lookup semantics.
- Schema fallback behavior can drift. Extract a pure shared accessor with tests before changing server config schema.

## Open functional risks inherited from P79.8d

### Passive Satella trigger requires exact matching injected build
- Host does not load the target dylib; it must already be visible in dyld.
- Accepted names: `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Current compatibility contract: `__TEXT vmaddr=0`, ctor RVA `0x847C`, init RVA `0x888C`, exact ctor/prologue signatures.
- Changed target builds intentionally fail closed.

### No passive deinitializer is known
- OFF performs no call/unload.
- First successful initialization is one-shot per process.

### Missing passive dylib intentionally does not fail the existing toggle
- Existing `NNGG/NNGGNNGG` persistence and `ImgTool.NeiGou` side effect happen independently.
- Missing/invalid passive image logs failure but does not revert the switch.

### arm64e PAC path still needs real-device confirmation
- CI compiles arm64 and arm64e successfully.
- Real arm64e hardware still needs functional validation of the indirect target call.

### P79.8c cloud permission and P79.8b persistence remain device-pending
- basic must hide `VIP云存档`; app/global Plus must expose it and fresh Verify must gate download.
- AuthV2 response/config/card state is memory-only while menu/runtime preferences remain unchanged.

## Verification improvements completed in P79.8e
- Active P79 workflow now triggers on `ZONCore`, `ZONServices`, project-file and current test changes.
- Current Dispatcher service-routing contract test passes.
- Passive Satella exact contract test passes.
- Xcode 16.4 arm64 + arm64e build passes.
- P79.8e raw binary equals P79.8d raw binary byte-for-byte, proving this architecture-hardening stage did not alter product runtime bytes.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
