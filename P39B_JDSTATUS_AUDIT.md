# P39-B JDStatusBarNotification Audit

## Baseline
- Device-verified baseline: `v1_p39`.
- Runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Active PBX Sources at baseline: **75**.
- P39-B work branch: `work/zonoemenu-v1-p39b-jdstatus-audit`.
- Audit CI Run: `34894434619` / **success**.
- Audit artifact: `p39b-jdstatus-audit` / ID `10368133245` / digest `sha256:5b46890e7594493ba4a2ee89e3c1b1a9e77dd66e09134d33577d49adf9ebf5ef`.
- Audit-only phase: no product runtime source, PBX membership, or behavior was changed.

## Group inventory
`testmod/导入导出/JDStatusBarNotification/` contains **8 PBX-active Objective-C implementation files**:
- `JDStatusBarNotificationStyle.m`
- `JDStatusBarNotificationPresenter.m`
- `JDSBNotificationStyleCache.m`
- `JDSBNotificationWindow.m`
- `UIApplication+JDSB_MainWindow.m`
- `JDSBNotificationView.m`
- `JDSBNotificationAnimator.m`
- `JDSBNotificationViewController.m`

The group also contains **11 headers** and `NotificationPresenter.swift`. The Swift wrapper has **0 PBX hits** and is not compiled into the current target.

## Product imports
Five product files import `JDStatusBarNotification.h`:
- `testmod/菜单/PubgLoad.mm`
- `testmod/Bsphp/main.m`
- `testmod/Bsphp/WX_NongShiFu123.mm`
- `testmod/导入导出/PreferenceManager.m`
- `testmod/工具箱/Hook/JiangHuHook.m`

## Proven live call sites
### `testmod/菜单/PubgLoad.mm`
This is a real runtime dependency, not a stale import. Current code calls the presenter to:
- show “准备下载存档,请稍后.” before a save/download operation;
- update notification text during `NSURLSession` download progress;
- update the JDStatusBarNotification progress bar;
- show “下载成功” after completion;
- show load/unzip/download-address status messages on additional save paths.

This reaches the protected cloud-save/download product path, so removing the dependency would alter current user-visible behavior and can break active code.

### `testmod/Bsphp/main.m`
This is a real startup/UDID dependency. `ZONShowCustomerStatus(...)` uses `JDStatusBarNotificationPresenter` and is called by the customer authorization flow for:
- UDID acquisition status;
- UDID write failure;
- UDID acquisition success / continuing authorization;
- other startup status notifications.

This is part of the protected authorization/UDID bootstrap path.

### `testmod/Bsphp/WX_NongShiFu123.mm`
This is a real authorization dependency. Current code uses the presenter for messages including:
- first activation;
- ad-speed authorization activation;
- software-source authorization activation;
- authorization-query status;
- activation completion.

This is part of the protected authorization path.

## Stale import candidates only
The audit found no JDStatusBarNotification class/API call sites in:
- `testmod/导入导出/PreferenceManager.m`
- `testmod/工具箱/Hook/JiangHuHook.m`

Their imports are candidates for later include/dependency hygiene, but removing those two import lines does **not** make the JDStatusBarNotification library removable because three protected runtime paths still depend on it.

## Runtime/dynamic-entry scan
- External dynamic JDStatus references: **none**.
- Internal `+load`: **none**.
- Internal constructor attributes: **none**.
- Internal swizzle/fishhook/`dlopen` entry points: **none**.
- The group contains `UIApplication (JDSB_MainWindow)` as an Objective-C category, but the audit found no automatic-entry behavior in that category.

These findings reduce hidden-entry risk but do not override the direct live call-site evidence above.

## Decision
**KEEP_LIVE_DEPENDENCY**

`JDStatusBarNotification` is **not** a whole-group removal candidate. Its eight PBX-active implementation files must remain in the current target because live product code directly uses the presenter in cloud-save/download, startup/UDID, and authorization flows.

P39 remains unchanged at **75 active Sources**. No JDStatusBarNotification file should be removed in the P39 lineage.

## P39 active-target audit closure
With this decision:
- AFNetworking: keep, live dependency.
- MBProgressHUD: keep, live dependency.
- SCLAlertView: keep, live dependency.
- SSZipArchive/minizip: keep, live dependency.
- SVProgressHUD: keep, live dependency.
- JDStatusBarNotification: keep, live dependency.
- `NSString+Tools`: already removed in P39 and device-verified.

The P39 active-target deletion audit is therefore complete. The next version should not continue deleting vendor groups without new evidence; move to structural/source-layout cleanup while preserving the promoted P39 runtime behavior.
