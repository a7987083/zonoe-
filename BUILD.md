# BUILD

## Current build system
- Xcode project: `testmod.xcodeproj`
- Product: `testmod.dylib`
- Target type: dynamic library
- MonkeyDev path: `/opt/MonkeyDev`
- Theos path: `/opt/theos`
- Primary runtime: IPA injection
- Secondary runtime: jailbreak injection
- Minimum deployment target: iOS 12.0
- Architectures: arm64 + arm64e

## Verified CI command
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

`VALIDATE_PRODUCT=NO` prevents MonkeyDev Release CI from attempting device deployment. CI verifies compilation/artifacts only.

## Latest v1_p27 CI verification
- Source commit: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`
- Isolated validation branch: `test/zonoemenu-v1-p27-build`
- Test-only validation commit: `b5b8d8c20da0fd1cb358956036ff4e532216339e`
- Workflow: `iOS Dylib Build`
- Run number: `97`
- Run ID: `34656320290`
- Result: success
- Xcode: 16.4
- iPhoneOS SDK: 18.5
- Deployment target: iOS 12.0
- Mach-O architectures: arm64 + arm64e

### A_customer
- Result: success
- Artifact: `testmod-v1_p27-A_customer`
- Artifact ID: `10286251100`
- Artifact ZIP SHA256: `2af95debe4ee769a03642bd5d7d31330dacbb8bfb1b8264e7ff3164663b08a05`

### B_debug
- Result: success
- Artifact: `testmod-v1_p27-B_debug`
- Artifact ID: `10286565630`
- Artifact ZIP SHA256: `f50b96bc3fb6e0b7e5a358a544888409c135c99bea488df95ae36b21ff82b683`

Both variants passed dependency/layout verification, compilation, linking, versioned dylib packaging, `file`, `lipo -info`, `otool -L` and artifact upload. Artifact ZIP digests are not per-dylib SHA256 values.

## Device-verified baseline
- Version: `v1_p26`
- Verified source commit: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`
- Runtime regression: passed by user on device.

`v1_p27` is not yet device-verified; CI success does not promote the runtime baseline.

## ZONCore compilation note
The legacy `testmod.xcodeproj/project.pbxproj` does not currently enumerate the p19-p27 `ZONCore` source files. p27 therefore keeps a narrow compatibility bridge: `PopupMenuVC.m` imports `ZONMenuCoordinator.m` exactly once. Public code imports only `ZONMenuCoordinator.h`, which is now interface-only. Explicitly integrating ZONCore `.m` files into the target should be a separate, carefully verified cleanup rather than hidden inside p27.

## Dependency/build policy
- Checked-in legacy dependency sources are authoritative.
- `scripts/bootstrap_vendor.sh` verifies rather than replaces them.
- Reuse the current target/toolchain before modernization.
- First real compiler/linker error is the source of truth.
- Record CI and device/runtime verification separately.
