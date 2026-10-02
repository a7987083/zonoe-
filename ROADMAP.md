# ROADMAP

> Canonical refactor plan for `zonoemenu`. CI success is not device promotion.

## Modifier integration
- Added “修改器” directly below `VIP云存档`.
- Runtime contract: `bool ZonoePatchActivate(void)` exported by an already-loaded external dylib.
- Visibility: `extra_menu` + runtime symbol available.
- Activation: fresh Verify + `extra_features` + runtime symbol available.
- Source complete; build/device validation pending.

## Menu continuation
- Sequential menu processing: `base.remote-download` → `base.cloud-save` → `base.local-files`.
- Current source-complete item: `base.local-files` (“浏览本地文件”, tag 3).
- Commits: `a81b0579cdc9d1631e37fe68fcf982a615d2588e`, `d9dbd49c3a542adbe73018964b59a85d052a2929`.
- Build/device validation pending.
- Next registry item after validation: `data.backup-save` (“备份存档”, tag 100).

## Current active stage — P79.8j Auth Verification Residue Cleanup — CI PASSED / DEVICE REGRESSION PENDING
- VERSION: `v1_p79_8j`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Runtime cleanup commit: `b18d6d7b003ab6c227e3890a4fb60b81acf5125c`.
- CI build commit: `7a69b75edf552221cedd7501a80324f69f5b185d`.
- CI Run `36865866031` / #87: success.
- Artifact ID `11163511291`, digest `sha256:a97467ceb0fc7f401f7a94efa9fa6c6ecaefceea87921d7c1dbdbc23ccb00df1`.
- Dylib SHA256: `3c67df496c1987fb0560e4178852a7fcba376fad0ca804585a139c14f1a7d80d`, size 3,303,232 bytes.
- Universal `arm64 + arm64e (PAC00)`.

## Frozen authorization model
1. Startup is UDID-first: `/index/index/apiface?udid=<UDID>` determines active / missing / expired / blocked.
2. Card is activation-only. `/appstore` is called only for missing/expired authorization, followed by `/apiface` confirmation.
3. Active UDID does not show a card prompt.
4. Signed GitHub bootstrap is Runtime Config; there is no `/index/dylib_verify/config` hop.
5. Secretless v3 Verify is `/challenge` → ECDSA P-256 proof → `/verify`, with session-only `auth_proof` and token.
6. No shared Verify Secret/HMAC or secondary enrollment-card UI may return.

## P79.8j cleanup delivered
- Removed detached `ZONAuthV2BindingProbe.h/.m` compatibility/swizzle source.
- Removed obsolete `ZONAuthV2API.postVerifyBody` and Verify URL builder; `ZONAuthV2Verify` is the single Challenge/Verify owner.
- Removed card propagation/storage from the Verify stage.
- Removed write-only `lastActivation` and duplicate `lastBootstrap` session caches.
- Kept `lastRuntimeConfig` because `ZONSaveTransferCoordinator` performs a fresh Verify for cloud-save actions.
- Replaced the old generic “check card” mapping for English Verify failures with protocol-aware v3 messages.
- One-shot P79.8j cleanup workflow/tool were removed after successful use.

## Intentionally retained compatibility code
`WX_NongShiFu123` / `Config` are not dead yet. They remain because:
- `ZONLegacyUDIDFallbackAdapter` still uses `WX_NongShiFu123 getUDID:` for legacy web UDID fallback.
- `ZONSaveTransferCoordinator` still consumes compatibility globals/config for cloud-save purchase/config paths.
Do not delete these until those live consumers are migrated.

## CI evidence
- Auth cleanup preflight/contract run `36865668377`: PASS.
- `dispatcher-contract`: PASS.
- `p79.8d-passive-contract`: PASS.
- `p79.8f-p0-safety`: PASS.
- `p79.8g-runtime-capability`: PASS.
- `p79.8h-feature-access`: PASS.
- `p79.8i-secretless-auth-v3-contract`: PASS with P79.8j residue assertions.
- Xcode 16.4 `arm64 + arm64e`: PASS.

## Next Task
Run a short real-device regression on the P79.8j dylib: active UDID startup, missing/expired activation, challenge/verify, menu access, and cloud-save fresh Verify. Preserve the existing UDID-first behavior.
