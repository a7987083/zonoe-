# BUILD

## Current build system
- Project: `testmod.xcodeproj`
- Target/product: `testmod` / `testmod.dylib`
- Target type: dynamic library
- Xcode CI: 16.4
- iPhoneOS SDK CI: 18.5
- Minimum production deployment target: iOS 12.0
- Architectures: arm64 + arm64e
- Primary runtime: IPA injection
- Secondary runtime: jailbreak injection

## p28 target integration
`testmod/ZONCore/ZONMenuCoordinator.m` is now explicitly registered in `testmod.xcodeproj/project.pbxproj` with:
- one `PBXFileReference`
- one `PBXBuildFile`
- one `PBXSourcesBuildPhase` entry

`PopupMenuVC.m` imports `ZONMenuCoordinator.h` only. The p27 direct `.m` import bridge is removed.

## Verified CI build command
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

## Latest v1_p28 CI
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`
- Validation branch: `test/zonoemenu-v1-p28-build`
- Workflow: `p28 Integrate and Build`
- Run ID: `34657710034`
- Result: success

### A_customer
- Artifact ID: `10286438074`
- Artifact ZIP SHA256: `86b899de9b04772f02a9a879bdbbf4138a6e3711f890bb0fca503e31877defaf`
- Dylib SHA256: `2a0bf1f10c490dd4d8a239943365b0d3fe71d35ee2109e968297307a599dfccc`

### B_debug
- Artifact ID: `10285962447`
- Artifact ZIP SHA256: `1a664beb7261164d7dc48a810c9f594d94f0ed80ede1c67a8f04b731fa645149`
- Dylib SHA256: `720a457df07ea8f5d4ddc6f7460357a193a98907a23d05d1fe50889f74b90437`

Both variants passed compile/link/package and Mach-O arm64+arm64e verification. No duplicate implementation/link error was produced.

## Device baseline
- Current device-verified version: `v1_p27`
- Source commit: `314dace8ebb8cf3b1ffaeec19bf0a2cf7fe7c311`
- `v1_p28` remains device-runtime pending until user regression testing passes.

## Build policy
- CI success is not device verification.
- Preserve the existing target/toolchain unless a proven build defect requires a change.
- Fix the first real compiler/linker error only; do not bundle unrelated refactors.
