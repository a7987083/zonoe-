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

## Build command
Verified CI uses Xcode 16.4 / iPhoneOS SDK 18.5 and the existing target/dependency set:

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

`VALIDATE_PRODUCT=NO` is intentional in CI: MonkeyDev otherwise treats a Release build as a packaging/install path and attempts SSH deployment. CI here verifies compilation/artifacts, not device deployment.

## Latest v1_p26 Menu Coordinator CI verification
p26 source commit: `b1f3eb25b1ea170c3dddadf746fe07ca9654ea80`.

An isolated validation branch `test/zonoemenu-v1-p26-build` was created from that source. Its only additional change was enabling that branch as a workflow push trigger; the p26 work branch workflow/source was not modified for the validation run.

- Workflow: `iOS Dylib Build`
- Run number: `96`
- Run ID: `34653448146`
- Validation commit: `a09b1fd35950c65386be3b4e70e689ae2c804d10`
- Result: success
- Xcode: 16.4
- iPhoneOS SDK: 18.5
- Deployment target: iOS 12.0
- Mach-O architectures: arm64 + arm64e

### A_customer
- Job result: success
- Artifact: `testmod-v1_p26-A_customer`
- Artifact ID: `10198416330`
- Artifact ZIP SHA256: `0a071bbe62248e38a70763ea12ceacde29b3b5d0467ed6377c80b85c0fea8e00`

### B_debug
- Job result: success
- Artifact: `testmod-v1_p26-B_debug`
- Artifact ID: `10198366721`
- Artifact ZIP SHA256: `102ae95930ef5e1b6aca7789dd10a744ba13e128f0de3b69760807804442de79`

Both variants passed compilation, linking, versioned dylib packaging, `file`, `lipo -info`, `otool -L` verification and artifact upload.

The listed SHA256 values are the GitHub Actions ZIP artifact digests, not the internal dylib hashes. The workflow also runs `shasum -a 256` on each dylib, but the log/artifact download endpoint returned 404 when this handoff was updated, so the internal dylib hashes are deliberately left unrecorded rather than inferred.

## Last device-verified build baseline
The device/runtime baseline remains the earlier verified build until p26 is tested on hardware:
- Workflow run: `34271970872`
- Verified code commit: `7120f92f978b99931444903b6f95b2e56a1bd594`
- Artifact: `zonoemenu-testmod-dylib`
- Artifact ID: `10074199433`
- Product SHA256: `c19c792e25f9cf65792992098f15b43621c7e3022a33781daddf5cc102970c71`
- Format: Mach-O universal dynamically linked shared library
- Architectures: arm64 + arm64e

## Dependency policy
- The user's checked-in legacy dependency sources are authoritative.
- `scripts/bootstrap_vendor.sh` verifies them; it does not replace them from upstream.
- Current checked-in sets include AFNetworking, MBProgressHUD and SCLAlertView.
- Theos shadows the SDK `MobileCoreServices` umbrella; `testmod-Prefix.pch` explicitly imports the public UTI subheaders required by legacy AFNetworking.

## Build policy
- Reuse the current target and dependency set first.
- Do not replace compiler/toolchain solely to modernize.
- First real compiler/linker error is the source of truth.
- CI build success is not runtime/device verification.
- Runtime and regression state must be recorded separately in `PROJECT_STATE.json`.
