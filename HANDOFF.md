# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Current VERSION: `v1_p79_8k2`.

## Current startup compatibility candidate
- Startup gate commit: `b0ead52f680945f5b9377a3eb57e78732ae89a5e`.
- Bootstrap contract comment commit: `9b588ac9d4b2798ebfe2757256d4588d8f315e9a`.
- CI path-trigger fix commit: `83fd0faff225754dc2dfb7d72d53a2b0fc81c0ad`.
- Behavior: dylib/`+load` returns without synchronous framework preflight; startup waits for host UIKit/window readiness, then preserves the existing preflight → authorization → bundled-module order.
- Validation status: source committed; compile/CI result not yet observed through the available connector; real-device regression pending.
- Primary regression target: Apps that previously flashed back/crashed during early injected startup.

## Current build evidence
- Runtime cleanup commit: `b18d6d7b003ab6c227e3890a4fb60b81acf5125c`.
- CI build commit: `7a69b75edf552221cedd7501a80324f69f5b185d`.
- P79 Server Driven Auth Build Run `36865866031` / #87: success.
- Artifact ID `11163511291`.
- Artifact digest: `sha256:a97467ceb0fc7f401f7a94efa9fa6c6ecaefceea87921d7c1dbdbc23ccb00df1`.
- Dylib SHA256: `3c67df496c1987fb0560e4178852a7fcba376fad0ca804585a139c14f1a7d80d`.
- Dylib size: 3,303,232 bytes.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / P79.8j DEVICE REGRESSION PENDING.

## Authorization model — do not reinterpret
- Authorization root is UDID-level.
- Startup calls `/index/index/apiface?udid=<UDID>` first.
- Active UDID skips card and `/appstore`.
- Missing/expired UDID uses card → `/appstore` → `/apiface` confirmation.
- Card is activation-only and must not be carried into Verify.
- Signed GitHub bootstrap is Runtime Config; no second `/index/dylib_verify/config` request exists.
- Secretless v3 Verify uses `auth_proof`, `/challenge`, App-local ECDSA P-256 proof, then `/verify`.
- Shared Verify Secret/HMAC and the secondary enrollment card prompt remain removed.

## P79.8j cleanup
- Deleted `ZONAuthV2BindingProbe.h/.m`.
- Deleted duplicate `ZONAuthV2API.postVerifyBody` and `verifyURLForRuntimeConfig` path.
- Removed AuthV2 session card getter/setter and card forwarding through Verify.
- Removed write-only `lastActivation` and duplicate `lastBootstrap` caches.
- Retained `lastRuntimeConfig`: cloud-save action still performs a fresh Verify using it.
- Updated Verify failure mapping so auth-proof/challenge/device-key failures no longer misleadingly tell the user to check the card.
- Updated v3 contract tests to forbid these residues returning.
- Removed the completed one-shot cleanup script/workflow after the cleanup succeeded.

## Compatibility code intentionally retained
Do not delete `WX_NongShiFu123` / `Config` yet:
- `ZONLegacyUDIDFallbackAdapter.m` still invokes `WX_NongShiFu123 getUDID:`.
- `ZONSaveTransferCoordinator.m` still references compatibility purchase/cloud configuration and `lastRuntimeConfig` for fresh Verify.
This is live compatibility code, not unused residue.

## Preserved architecture
- `ZONRuntimeCapabilityService`.
- `ZONFeatureAccessProvider`.
- `ZONFeatureDispatcher`.
- `ZONFeatureRegistry`.
- Passive Satella/runtime capability behavior unchanged.
- R4 typed descriptors / R5 broad decomposition remain paused.

## Next validation
Use the P79.8j CI dylib and verify: active UDID launch, missing/expired card activation, `/challenge` + `/verify`, menu permissions, cloud-save fresh Verify, and passive runtime behavior. Do not promote solely from CI.
