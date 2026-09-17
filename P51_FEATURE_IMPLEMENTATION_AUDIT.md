# P51 Nine-Feature Implementation Audit

## Scope
This stage reviews the nine built-in menu features registered by `ZONFeatureRegistry` and refactors execution plumbing without changing user-visible behavior.

Promoted runtime baseline: P49 / P50-frozen product surface.

## Architecture summary

```text
Menu renderer / event bridge
        |
        v
ZONFeatureRegistry
  - 3 sections
  - 9 built-in features
        |
        v
ZONFeatureDispatcher
  - action routes (7)
  - toggle routes (2)
        |
        +--> PubgLoad
        |     - remote download
        |     - cloud save
        |
        +--> SandboxBrowserVC
        |     - local files
        |
        +--> daochucd
        |     - backup
        |
        +--> YYYPicker
        |     - restore
        |
        +--> clear-data / clear-auth confirmation flows
        |
        +--> ImgTool + NSUserDefaults
              - IAP/no-ads
              - ad speed
```

## Nine formal features

| # | Identifier | Title | Execution target | Primary side effects |
|---|---|---|---|---|
| 1 | `base.remote-download` | 远程下载 | `PubgLoad yuanchengdwon` | network/download/UI |
| 2 | `base.cloud-save` | VIP云存档 | `PubgLoad checkCloudSaveStatus` | auth/network/tmp/download/restore |
| 3 | `base.local-files` | 浏览本地文件 | `SandboxBrowserVC` | modal presentation/filesystem |
| 4 | `data.backup-save` | 备份存档 | `daochucd backupasd` | filesystem/zip/share UI |
| 5 | `data.restore-save` | 恢复存档 | `YYYPicker addBtnAction` | document picker/unzip/copy/defaults |
| 6 | `data.clear-game-data` | 清除游戏数据 | dispatcher clear-data flow | destructive filesystem/defaults/exit |
| 7 | `auth.clear-records` | 清除授权记录 | `WX_NongShiFu123 deletekm` | authorization persistence/exit |
| 8 | `runtime.iap-noads` | 内购破解+iGameGod去广告 | defaults + `ImgTool.NeiGou` | persistence/runtime toggle |
| 9 | `runtime.ad-speed` | 广告加速 | defaults + `ImgTool.ADSpeed` | persistence/runtime toggle |

## Priority issues

### P0 — behavior-sensitive monoliths
1. `PubgLoad.mm` mixes remote metadata lookup, purchase validation, download sessions, progress UI, archive extraction and save migration. This is high-risk because network, filesystem and UI lifecycles are interleaved.
2. Clear-data and clear-authorization flows intentionally terminate the process. Timing (`5s` and `3s`) and destructive scope are behavior contracts and must not be casually changed.
3. Restore logic recursively discovers `Documents` / `Library`, overwrites files, skips selected names and then reloads custom defaults. Small path or ordering changes can alter user data.

### P1 — duplication / maintenance risk
1. Dispatcher previously repeated a long identifier `if` chain for all nine features.
2. Both runtime toggles repeated the same `NSUserDefaults` write + `synchronize` sequence with only keys and target property differing.
3. Backup implementation duplicates the top-level Documents and Library copy loops, including size checks, blocking semaphore prompts, overwrite logic and progress reporting.
4. Multiple implementations independently resolve current view controller/window and construct sandbox paths.

### P2 — performance / responsiveness
1. `PubgLoad.mm` contains synchronous URL/string reads (`dataWithContentsOfURL`, `stringWithContentsOfURL`) in flows that can become user-visible stalls depending on queue context.
2. Backup recursively calculates folder sizes before copy and may scan large directory trees twice (size pass + copy pass).
3. Backup uses a background semaphore waiting for a main-thread alert decision. It works but is difficult to cancel/test and can deadlock if presentation fails.
4. Download progress creates/updates multiple HUD surfaces; frequent UI work can be noisy under fast delegate callbacks.

## Refactor plan

### P51-A — execution routing (this change)
- Keep Registry as the source of truth.
- Replace action/toggle identifier `if` chains with route tables.
- Factor repeated toggle persistence into one helper.
- Keep all nine implementation selectors, defaults keys, delays and side effects unchanged.
- Add a static behavior contract that proves all 9 registry entries still map to the promoted implementation surface.

### P51-B — backup service extraction
- Extract one reusable top-level directory-copy routine used for both Documents and Library.
- Preserve the 50 MiB prompt threshold, prompt wording, skip/backup choices, overwrite semantics and progress UI.
- Add filesystem-fixture tests for copy/skip/zip layout.

### P51-C — restore service extraction
- Separate archive discovery/copy policy from document-picker UI.
- Preserve skip set (`__MACOSX`, `.DS_Store`, `Preferences`) and defaults reload ordering.
- Add fixture archives covering nested roots and type collisions.

### P51-D — remote/cloud-save decomposition
- Split `PubgLoad` into request, download, archive and migration responsibilities only after characterization tests capture current URLs, callbacks, tmp layout and UI events.
- Replace synchronous networking only in a dedicated behavior-reviewed stage; do not mix transport changes with structural moves.

## Behavior-equivalence gates
1. Registry contains exactly 9 built-ins with existing identifiers/tags.
2. Seven action identifiers map to the same promoted selectors/classes.
3. Two toggle identifiers preserve exact defaults keys and `ImgTool` properties.
4. Clear-data still preserves `/tmp` directory itself, clears its contents, clears Documents/Library/defaults, and exits on the existing delay.
5. Clear-authorization still calls `deletekm` and exits after the existing delay.
6. Active PBX source count stays unchanged for P51-A.
7. A_customer and B_debug build for arm64 + arm64e.
8. Exported symbols and linked libraries remain identical to the promoted P49 runtime.
9. Real-device promotion is required before this becomes the new runtime baseline.
