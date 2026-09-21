# P67 Remote Download Engine Audit

## Baseline
- Promoted real-device baseline: `v1_p66`
- Baseline runtime source: `5cd3667754449b9a7630ba2d1e7db472d692377b`
- P67 branch: `work/p67-remote-download-engine-audit`

## Audit findings
`PubgLoad.mm` mixed UI/cloud entitlement orchestration with NSURLSession transport, progress, temporary-file ownership, ZIP validation, extraction, and restore dispatch.

Two active download entry families converge on the same archive/restore path:
- user-entered remote archive URL (`yuanchengdwon` / `xiazaidz:`),
- cloud-save download (`checkCloudSaveStatus` -> cloud action -> download).

A legacy `loadddd` compatibility path also retained broad application `/tmp` cleanup. P67 removes that broad cleanup rather than weakening the safety contract.

## P67 boundary
- `PubgLoad` keeps UI, cloud list/entitlement logic, and presentation.
- `ZONRemoteDownloadService` owns URL validation, single active download task, progress delivery, HTTP status validation, ZIP filename validation, temporary archive persistence, cancellation, and transport errors.
- Successful downloads are handed directly to promoted P66 `ZONRestoreService`.
- `PubgLoad` no longer owns the active NSURLSession download delegate implementation or duplicate unzip/restore tail.
- Download-owned files live under `/tmp/zonoe-download`.
- P67 does not enumerate and delete the entire application `/tmp` tree.

## Compatibility intentionally preserved
- Existing `yuanchengdwon` entry remains.
- Existing `checkCloudSaveStatus` / entitlement flow remains.
- Existing B_debug cloud-test-mode switch remains.
- Existing P66 restore engine, merge semantics, ZIP path-containment guard, and legacy restore compatibility remain.
- Legacy `loadddd` is retained as an entry but its download transport and unsafe broad tmp cleanup are routed through the P67 boundary.

## CI evidence
- Version: `v1_p67`
- Actual migrated/build source: `71410f993dc9c00d16586af75c7d8e05bcdc8307`
- CI Run: `35574929300`
- Result: `success`
- Migration: PASS
- P67 contract: PASS
- A_customer arm64 + arm64e: PASS
- B_debug arm64 + arm64e: PASS

## Deferred / real-device-sensitive items
- Server `Content-Disposition` filename behavior should be verified on real cloud/download endpoints; P67 currently requires the resolved download filename to be ZIP-compatible.
- Starting a new cloud download during an already-running restore is an edge case not promoted until real-device behavior is known.
- P68 remains responsible for separating cloud-save business/API orchestration from `PubgLoad`; P67 intentionally does not move purchase/entitlement/cloud-list policy.
