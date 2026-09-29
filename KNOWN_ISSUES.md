# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_8d`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Trigger implementation: `985f85073d89cb46aff8fd940ee50f1ed6175f3f`.
- Build HEAD: `6ab1494bb11afc228fe78cd7087b97c4c04d9b2d`.
- CI Run `36604169367` / #38: success.
- Artifact ID: `11050622646`.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `1c7e788f60c79679af7cf06b8427b559364fa7c4374901f455260c0057778d35`.
- Controlled final SHA256: `bd5b3ca738d6e8041d16b57c4515dffb6f47806da412b0b5f8bd512e1f09d6cd`.
- Current-device validation: pending.
- Last device-passed baseline: P79.8a / controlled SHA256 `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.

## Open risks

### Passive Satella trigger requires exact matching injected build
- P79.8d does not load the target dylib; it must already be present in dyld when the switch is enabled.
- Accepted suffixes are `1_passive.dylib`, `1_passive_zh.dylib`, and `SatellaJailed_passive.dylib`.
- Runtime address contract is tied to the supplied passive build: ctor RVA `0x847C`, init RVA `0x888C`, `__TEXT vmaddr=0`.
- The implementation checks the ctor `RET` bytes and 16-byte init prologue before calling. A changed target build will intentionally fail closed.

### No passive deinitializer is known
- OFF does not call into Satella and does not unload the image.
- First successful start is one-shot per process; later ON events log `already_started`.
- If a future passive build exposes a documented shutdown entry, add it as a separate versioned contract rather than guessing an inverse operation.

### Missing passive dylib does not fail the existing toggle
- This is intentional: the original `NNGG/NNGGNNGG` persistence and `ImgTool.NeiGou` side effect are applied first.
- If no valid injected image is found, P79.8d logs `image_not_loaded_or_invalid` but does not revert the switch.
- Device testing must confirm this fallback is acceptable in the real injection workflow.

### arm64e PAC path needs device confirmation
- Xcode 16.4 compiled both arm64 and arm64e successfully.
- arm64e signs the raw `base + 0x888C` address using the function-pointer PAC key before invocation.
- Real arm64e hardware still needs confirmation that the target passive dylib's entry behaves correctly with this indirect call.

### P79.8c permission-gated cloud menu remains device-pending
- Verify-only/basic must not render `VIP云存档`.
- `app_plus/global_plus` must render it and actual download must still pass fresh Verify.

### P79.8b persistence cleanup remains device-pending
- Authorization response/config/card state is memory-only; menu/runtime preferences remain unchanged.

### Raw CI artifact has no Verify Secret
- CI Run `36604169367` produced the placeholder build.
- Controlled final artifact uses equal-length post-build injection into both architecture slices.
- Placeholder remaining `0`; Secret occurrences `2`; 128 bytes differ from raw CI.
- Public source remains placeholder-only.

## Corrected / intentionally preserved

### Passive trigger does not use dlopen — P79.8d
- Earlier candidate design included optional loading; final user requirement is preload/inject externally and only activate on switch ON.
- The committed implementation enumerates loaded dyld images only.

### Ungated VIP cloud-save — corrected in P79.8c
- Menu visibility and action execution consume server permissions, with a fresh Verify before cloud download.

### Excess AuthV2 persistence — corrected in P79.8b
- AuthV2 response/config/card state is process-memory only; only notice fingerprint remains persistent.

### P79.8 saved-card-first startup — corrected in P79.8a
- Startup checks server authorization by UDID first; user confirmed the real-device scenario works.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Acceptance testing must use the Secret-configured controlled artifact.
