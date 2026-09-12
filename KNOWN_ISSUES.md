# KNOWN_ISSUES

## Current

### v1_p30 device regression pending
- Severity: validation gate, not a known defect.
- `v1_p30` passed A/B CI and universal Mach-O verification but has not yet been promoted by hardware testing.
- Because p30 is built on p29, a successful p30 hardware regression will also cover the pending p29 structural changes.
- Until then, `v1_p28` / `350a46deb089a05fc599e641bd1eeb419c36c0d5` remains the device-verified fallback baseline.

### Remaining header-only ZONCore boundaries
Still pending isolated review:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONModuleLoader.h`

`ZONFeatureDispatcher.h` directly owns protected business paths such as cloud save, clear-game-data and clear-authorization. Do not convert or alter it as part of unrelated cleanup.

## Closed

### p30 first CI protection-check failure
- Cause: build checkout used shallow history while the protection assertion referenced the p29 commit.
- Impact: A/B compile steps did not run in that attempt; p30 source was unchanged.
- Resolution: full-history checkout plus corrected `git diff --exit-code` ordering; successful rerun ID `34672196947`.

### p29 initial workflow YAML validation failure
- Test-only CI definition issue; no p29 source impact.

### Keyboard/presentation suspicion
- Closed as a user/test-side mistake; not a project defect.
