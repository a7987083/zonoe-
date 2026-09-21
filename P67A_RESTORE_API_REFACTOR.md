# P67a Restore API Refactor

## Root cause

P67 replaced the historical remote/cloud restore tail:

`PubgLoad -> YYYPicker yidongwenjian -> PreferenceManager -> synchronize -> cleanup -> exit(0)`

with a direct call:

`PubgLoad -> ZONRestoreService`

The filesystem restore completed, but the P66 post-success lifecycle was skipped. Device symptom: remote-download and cloud-save restores reported success but the game did not terminate.

## P67a architecture

`YYYPicker / PubgLoad -> ZONRestoreAPI -> ZONRestoreService -> filesystem`

Responsibilities:

- `ZONRestoreService`: archive extraction, validation, Documents/Library apply, staging cleanup.
- `ZONRestoreAPI`: complete restore business transaction and preserved P66 post-success lifecycle.
- `YYYPicker`: picker/UI orchestration only.
- `yidongwenjian`: legacy compatibility shim that forwards to the semantic prepared-staging restore entry.
- `PubgLoad`: download/cloud UI and download orchestration; no direct restore-service or PreferenceManager bypass.

## Preserved P66 success tail

On successful restore, `ZONRestoreAPI` calls:

`[PreferenceManager loadCustomPlistIntoUserDefaults:@"MyCustomSettings"]`

The existing PreferenceManager behavior performs restored preference loading, `NSUserDefaults` synchronization, legacy staging cleanup and `exit(0)` after successful synchronization.

## CI

- Version: `v1_p67a`
- Branch: `work/p67a-remote-download-post-restore-exit-fix`
- Actual build commit: `0433ab7f3ce24f5a11dd3d8a4fe3be360a233d61`
- GitHub Actions run: `35578207158`
- Result: SUCCESS
- Architectures: `arm64`, `arm64e`

Artifacts:

- A_customer artifact `10628789806`
- A_customer dylib SHA-256 `e36ff45ad1191528856cc8c1ba92d4d17e5eb098c0bf50c6889a6d324744a7f6`
- B_debug artifact `10627714943`
- B_debug dylib SHA-256 `57c585ec57f6109bf03e6c522a440474e68256e9e1491d65ad5cedfdfca20594`

## Device validation

Status: **PASSED / PROMOTED**

User reported the complete scoped real-device validation as normal:

1. local imported ZIP restore succeeds and exits the game;
2. remote URL ZIP restore succeeds and exits the game;
3. cloud-save restore succeeds and exits the game;
4. restored data is correct after relaunch;
5. invalid/damaged/failed restores do not incorrectly terminate the game;
6. baseline startup/menu/six-button regression checks are normal.

P67a is now the promoted runtime/rollback baseline. P67 remains a non-promoted regression build. The verified runtime source remains `0433ab7f3ce24f5a11dd3d8a4fe3be360a233d61`; later documentation commits are not runtime build commits.
