# KNOWN_ISSUES

## Current

### v1_p29 device regression pending
- Severity: validation gate, not a known defect.
- `v1_p29` passed A/B CI and universal Mach-O verification but has not yet been promoted by hardware testing.
- Until the user confirms the A_customer build, `v1_p28` / `350a46deb089a05fc599e641bd1eeb419c36c0d5` remains the device-verified fallback baseline.

### Remaining header-only ZONCore boundaries
The following were deliberately not included in p29 and remain candidates for later isolated review:
- `ZONFeatureRegistry.h`
- `ZONFeatureDispatcher.h`
- `ZONMenuEventBridge.h`
- `ZONModuleLoader.h`

Do not combine their conversion with p29 runtime validation because Dispatcher/EventBridge connect protected business behavior.

## Closed

### p29 initial workflow YAML validation failure
- Cause: test-only workflow embedded multiline source text with invalid YAML block indentation.
- Impact: no job was created and the p29 work branch was not modified by that run.
- Resolution: source was committed normally and CI was reduced to PBX registration/build verification.

### Keyboard/presentation suspicion
- Closed as a user/test-side mistake; not a project defect.
- No keyboard/presentation code change is required.
