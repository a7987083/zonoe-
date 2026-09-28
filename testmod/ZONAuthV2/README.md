# ZONAuthV2 phase 1

This directory is the new server-driven authorization adapter for `zonoe-`.

Current status:

- Storage namespace isolated from legacy Bsphp keys.
- `/appstore`, `/index/index/apiface`, and `/index/dylib_verify/config` transports implemented.
- Existing P76 UDID/menu entry is intended to remain the owner of UDID acquisition.
- Legacy Bsphp remains untouched as reference code.
- The exact Protocol v2 canonical/HMAC implementation is intentionally not invented here; it must be imported from the validated auth implementation before this adapter becomes the active authorization path.

Until Verify v2 is connected, this module must not persist a card as successfully authorized and must not replace the P76 runtime entry.
