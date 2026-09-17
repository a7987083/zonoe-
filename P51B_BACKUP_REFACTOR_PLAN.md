# P51-B Backup Refactor Plan

Baseline: P51-A candidate (`e1be699655cec468c7d69fd15ed60f1810a4f3b1`).
Promoted/device baseline remains P49 (`4cebe094ad7a4dd554e8266af34dcf3abe04902a`).

## Scope
- Refactor only the backup implementation behind `data.backup-save`.
- Preserve `backupasd -> bfcundang:` entry semantics.
- Preserve 50 MiB confirmation threshold and Skip/Backup choices.
- Preserve temp layout `tmp/zonoe/{Documents,Library}`.
- Preserve cleanup of `Library/HeimdallrBU`, `Library/Caches`, `Library/UnityCache`, and `Documents/zonoe` inside the staging tree.
- Preserve archive destination `Documents/zonoe/<name>.zip` and sharing flow.
- Preserve current progress/status strings where practical.

## Non-goals
- No remote/cloud download changes.
- No restore changes.
- No authorization, startup, menu, hook, or persistence changes.
- No semantic change to which top-level Documents/Library items are considered for backup.

## Verification
- Static behavior contract over method names, threshold, staging/archive paths, cleanup paths, and UI labels.
- Exact runtime scope gate.
- A_customer + B_debug arm64/arm64e builds.
- Exported symbols and linked libraries compared to P51-A artifacts.
- Real-device validation required before any promotion.
