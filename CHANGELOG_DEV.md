# CHANGELOG_DEV

## 2026-09-29 — v1_p79_10 Server-Authoritative Access Model — CI PASSED / DEVICE PENDING
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `3177a4e8dc4ceeaabd97ecdac87a7266b201566a`.
- Build/version commit: `533af1abd09bb2fcf0701ca05c4370d740129459`.
- CI Run `36567247825` / #31: success.
- Artifact ID `11032596408`.
- Raw CI dylib SHA256: `af13c7a69f4a30cb5333d1f04917998f738ba513ca19ea94cf6a24e1dc775552`.
- Device feedback on P79.9: an already-activated UDID in a newly installed App still showed the card prompt.
- Root cause: P79.9 derived authorization locally from legacy fields instead of consuming the server-computed permission model.
- P79.10 uses only server `access_level` and `permissions` for the authorization decision.
- Accepted levels are `global_plus`, `app_plus`, and `basic`; `block` is not accepted.
- Client no longer derives the card class from `scope`, `type`, or `expire`.
- Startup remains UDID-first and queries `/apiface` before any card prompt.
- First activation also re-queries `/apiface` and requires an accepted server access level before continuing.
- CI built arm64 + arm64e successfully.
- Controlled final test dylib SHA256: `6e0a29487b5e5f8c2f9392203e306c59de8140eb2983e5f59f28821f42ebd9e5`.

## 2026-09-29 — v1_p79_9 UDID-First Authorization Gate — CI PASSED / DEVICE FAILED
- Logic commit: `675621f8264e228fc1d578301b17f49e9101a16b`.
- Build commit: `77db45077f6e22e54b7fa9e8c5a0a3924a65747a`.
- CI Run `36564346565` / #29: success.
- UDID-first startup direction was correct, but local permission parsing was wrong.
- Superseded by P79.10.

## 2026-09-29 — v1_p79_8 — CI PASSED / SUPERSEDED
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- CI Run `36560746520` / #27: success.
- Superseded after requirement clarification that startup authorization is UDID-first.

## 2026-09-29 — v1_p79_7 — CI PASSED / DEVICE FAILED
- CI Run `36531465809` / #25: success.
- Same-card/same-UDID reuse still reached the one-time activation path.

## 2026-09-29 — v1_p79_6 — CI PASSED
- Restored strict first-activation state validation before Verify.
- CI Run `36523256192` / #24: success.

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / PROMOTED
- Source commit: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- P64a remains the last promoted/device-verified rollback baseline.

## Operating rules
- CI success does not equal device promotion.
- Keep all five long-project state files synchronized.
