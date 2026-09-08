# BUILD

## Current build system
- Xcode project: `testmod.xcodeproj`
- Product: `testmod.dylib`
- Target type: dynamic library
- Current project integrates MonkeyDev/Theos paths.
- Package install path: `/Library/MobileSubstrate/DynamicLibraries`.

## Production requirements
- Minimum deployment target: iOS 12.0.
- Architectures: arm64 + arm64e.
- Primary artifact must be usable for IPA injection.
- Secondary packaging path may produce jailbreak MobileSubstrate/ElleKit-compatible package.

## Initial local build command
Exact scheme/configuration will be verified before CI is enabled. Expected form:

```bash
xcodebuild \
  -project testmod.xcodeproj \
  -target testmod \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0 \
  ARCHS="arm64 arm64e" \
  build
```

Do not treat this command as verified until the production branch CI/local build has passed.

## Build policy
- Reuse the current target and dependency set first.
- Do not replace the compiler/toolchain solely to modernize.
- First real compiler/linker error is the source of truth.
- A change is not considered finished until build state is recorded in PROJECT_STATE.json.
