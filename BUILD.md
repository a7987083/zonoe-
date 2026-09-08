# BUILD

## Current build system
- Xcode project: `testmod.xcodeproj`
- Product: `testmod.dylib`
- Target type: dynamic library
- MonkeyDev path: `/opt/MonkeyDev`
- Theos path: `/opt/theos`
- Jailbreak package install path: `/Library/MobileSubstrate/DynamicLibraries`

## Production requirements
- Minimum deployment target: iOS 12.0.
- Architectures: arm64 + arm64e.
- Primary artifact must be usable for IPA injection.
- Secondary packaging path may produce jailbreak MobileSubstrate/ElleKit-compatible package.

## Verified CI build
Verified on GitHub Actions with Xcode 16.4 / iPhoneOS SDK 18.5:

```bash
xcodebuild \
  -project testmod.xcodeproj \
  -target testmod \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  IPHONEOS_DEPLOYMENT_TARGET=12.0 \
  ARCHS="arm64 arm64e" \
  ONLY_ACTIVE_ARCH=NO \
  VALIDATE_PRODUCT=NO \
  MonkeyDevInstallOnAnyBuild=NO \
  MonkeyDevInstallOnProfiling=NO \
  MonkeyDevBuildPackageOnAnyBuild=NO \
  CONFIGURATION_BUILD_DIR="$PWD/build/Release-iphoneos" \
  build
```

Why `VALIDATE_PRODUCT=NO` is required in CI: MonkeyDev's `md --xcbp` treats a Release build with `VALIDATE_PRODUCT=YES` as a packaging/install path and attempts SSH deployment to the configured/default device. CI is compile/artifact verification only, so device deployment is explicitly disabled.

## Verified result
- Workflow run: `34270333942`
- Verified code commit: `095d8d0a3cb960686a30f410bfc6299a914f9ed4`
- Artifact: `zonoemenu-testmod-dylib`
- Artifact ID: `10073571157`
- Product SHA256: `eb3bedb670081760e45a4b8dd1da0222d579e52ebbb96c89b1e616a73e2d0fb6`
- Format: Mach-O universal dynamically linked shared library
- Architectures: `arm64`, `arm64e`
- `xcodebuild`: `BUILD SUCCEEDED`

## Dependency policy
- The user's checked-in legacy dependency sources are authoritative.
- `scripts/bootstrap_vendor.sh` verifies them; it does not replace them from upstream.
- Current checked-in sets include AFNetworking, MBProgressHUD and SCLAlertView.
- Theos shadows the SDK `MobileCoreServices` umbrella; `testmod-Prefix.pch` explicitly imports the public UTI subheaders required by legacy AFNetworking.

## Build policy
- Reuse the current target and dependency set first.
- Do not replace the compiler/toolchain solely to modernize.
- First real compiler/linker error is the source of truth.
- CI build success is not runtime/device verification.
- Runtime and regression state must be recorded separately in `PROJECT_STATE.json`.
