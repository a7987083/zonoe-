# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_10`.
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `3177a4e8dc4ceeaabd97ecdac87a7266b201566a`.
- Build commit: `533af1abd09bb2fcf0701ca05c4370d740129459`.
- CI Run `36567247825` / #31: success.
- Architectures: `arm64 + arm64e`.
- Controlled final test dylib SHA256: `6e0a29487b5e5f8c2f9392203e306c59de8140eb2983e5f59f28821f42ebd9e5`.
- Real-device validation: pending.
- Last promoted/device baseline remains P64a / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### P79.10 server access model requires real-device confirmation
- Startup is UDID-first and queries `/index/index/apiface` before card state or prompts.
- Client no longer interprets `scope/type/expire` to decide card class.
- Authorization is server-authoritative through `access_level` + `permissions`.
- Usable levels are `global_plus`, `app_plus`, `basic`; `block` is not usable.
- Device regression must confirm an already-activated UDID receives one of the usable access levels and bypasses the card prompt.

### Online `/apiface` response could not be fetched from the tool environment
- The exact user-supplied endpoint was not reachable from the external tool environment during this change.
- Implementation therefore follows the documented server contract supplied by the project: `global_plus > app_plus > basic > block` and client-only consumption of `access_level/permissions`.
- Device logs now print `P79.10_UDID_GATE access_level=... authorized=... permissions_count=...` so the real server result is directly observable on-device.

### `app_plus` applicability remains server/Verify-owned
- Startup treats `app_plus` as an already-activated UDID and does not show a card prompt.
- Whether that authorization applies to the newly installed App is resolved later by Verify using current App identity.
- `app_not_authorized` still returns to the card prompt so another valid card can be entered.

### Lookup failure must not look like no authorization
- Network errors and HTTP 5xx show a validation/server error and must not open the card prompt.

### Cross-App authorization clearing remains bounded by Keychain visibility
- Local reset deletes authorization-related Generic Password services visible to the current process.
- Apps using separate/default Keychain access groups cannot clear each other's private entries.
- True cross-App local reset requires shared access groups; server records require a real revoke/reset API.

### Raw CI artifact has no Verify Secret
- CI Run `36567247825` reported `verify_secret_configured=0`.
- Raw CI dylib SHA256: `af13c7a69f4a30cb5333d1f04917998f738ba513ca19ea94cf6a24e1dc775552`.
- Controlled artifact uses equal-length post-build injection into both architecture slices; placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ.
- Public source must retain only the placeholder.

## Corrected / superseded
- P79.9 UDID-first startup direction was correct, but its client-side `scope/type/expire` parser was wrong; superseded by P79.10 server `access_level/permissions` handling.
- P79.8 exact card+UDID startup reuse is superseded by UDID-first startup.
- P79.7 `/authorization` probe is retired.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Verify acceptance testing must use the Secret-configured controlled artifact.
