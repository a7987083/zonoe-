# KNOWN_ISSUES

## Current state
- Active version: `v1_p79_8j`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Runtime cleanup commit: `b18d6d7b003ab6c227e3890a4fb60b81acf5125c`.
- CI build commit: `7a69b75edf552221cedd7501a80324f69f5b185d`.
- CI Run `36865866031` / #87: success.
- Artifact ID `11163511291`, digest `sha256:a97467ceb0fc7f401f7a94efa9fa6c6ecaefceea87921d7c1dbdbc23ccb00df1`.
- Dylib SHA256 `3c67df496c1987fb0560e4178852a7fcba376fad0ca804585a139c14f1a7d80d`, 3,303,232 bytes, arm64 + arm64e PAC00.
- P79.8j real-device regression is still required after the cleanup.

## No current auth blocker in CI
The Secretless v3 client contracts and Xcode build pass. Proven-dead verification residue has been removed without changing the UDID-first business activation model.

## Compatibility debt still open
`WX_NongShiFu123` / `Config` cannot yet be removed safely:
- `ZONLegacyUDIDFallbackAdapter` uses `WX_NongShiFu123 getUDID:` when the primary UDID path is unavailable.
- `ZONSaveTransferCoordinator` still consumes compatibility globals/config for cloud-save purchase/config behavior.
- `lastRuntimeConfig` is still consumed by cloud-save fresh Verify and therefore is intentionally retained.
These pieces should only be removed after their consumers are migrated.

## Device-equivalence risk
CI does not prove runtime equivalence. P79.8j device regression should cover:
- active UDID startup with no card prompt;
- missing/expired card activation and post-activation `/apiface` confirmation;
- signed bootstrap → `/challenge` → `/verify`;
- menu permission/access results;
- cloud-save fresh Verify;
- passive runtime/Satella path.

## Remaining separate regression gates
- P79.8c cloud permission matrix: `basic` hides VIP cloud-save; `app_plus/global_plus` expose it; action still requires fresh Verify.
- P79.8b persistence/reset regression beyond the protected authorization-reset boundary.

## Deferred architecture work
- Feature registry remains weakly typed; R4 typed descriptors remain paused.
- `ZONAuthV2Flow` remains relatively large; broad R5 decomposition remains paused.

## Tracking rules
- CI success alone does not equal device promotion.
- Never reintroduce a long-lived shared Verify Secret/HMAC into the client.
- Keep server private signing material server-side.
