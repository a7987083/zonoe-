# ZONAuthV2 — Secretless Auth v3

This directory owns the active server-driven authorization flow for `zonoe-`.

Current contract:

- UDID-first startup: `/index/index/apiface?udid=<UDID>` decides active / missing / expired / blocked.
- Card is activation-only and is sent only to `/appstore` when a UDID needs activation/renewal.
- Active `/apiface` responses provide the short-lived session `auth_proof` used by v3 verification.
- The signed GitHub bootstrap document is the Runtime Config; there is no second `/index/dylib_verify/config` hop.
- Runtime Config authenticity is verified with the embedded RSA-2048 public key.
- Each App keeps its own ECDSA P-256 private key in Keychain and proves possession through `/challenge` → `/verify`.
- The same short-lived `auth_proof` is bound to Challenge and Verify and is covered by the canonical device signature.
- Verify returns the session token / access level / permissions consumed by the feature-access layer.
- No shared Verify Secret, HMAC Verify path, or secondary enrollment card prompt exists in the active AuthV2 implementation.

P79.8j cleanup:

- Removed the detached `ZONAuthV2BindingProbe` compatibility/swizzle source.
- Removed the duplicate `ZONAuthV2API.postVerifyBody` / Verify URL builder; `ZONAuthV2Verify` is the sole Challenge/Verify owner.
- Removed card propagation/storage from the Verify stage.
- Removed write-only `lastActivation` and duplicate `lastBootstrap` caches.
- `lastRuntimeConfig` remains intentionally because the cloud-save path performs a fresh Verify using the current signed Runtime Config.
- Legacy `WX_NongShiFu123` / `Config` source remains for now because live legacy-UDID fallback and cloud-save compatibility paths still reference it; it is not dead code yet.
