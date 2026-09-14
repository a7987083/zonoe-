#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

P36_DOC_HEAD = "ffb90dbdc0be28f90db7648f6ad3e7e09462109d"
P36_RUNTIME = "c85a6a235daf3287b70c13fbe69be455a3aecce2"

MIRRORS = {
    "category": "testmod/category",
    "工具箱": "testmod/工具箱",
    "SVProgressHUD": "testmod/SVProgressHUD",
    "Package": "testmod/Package",
}

ACTIVE_FEATURE_IDS = [
    "base.remote-download",
    "base.cloud-save",
    "base.local-files",
    "data.backup-save",
    "data.restore-save",
    "data.clear-game-data",
    "auth.clear-records",
    "runtime.iap-noads",
    "runtime.ad-speed",
]


def out(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def run(*args: str) -> None:
    subprocess.check_call(args)


def tree_sha(ref: str, path: str) -> str:
    return out("git", "rev-parse", f"{ref}:{path}")


def main() -> None:
    head = out("git", "rev-parse", "HEAD")
    if head != P36_DOC_HEAD:
        raise SystemExit(f"expected p36 documentation head {P36_DOC_HEAD}, got {head}")

    # Proof gate 1: every root mirror must be byte/tree-identical to its canonical testmod copy.
    for root_path, canonical_path in MIRRORS.items():
        if not Path(root_path).exists():
            raise SystemExit(f"expected root mirror missing before cleanup: {root_path}")
        if not Path(canonical_path).exists():
            raise SystemExit(f"canonical path missing: {canonical_path}")
        root_sha = tree_sha("HEAD", root_path)
        canonical_sha = tree_sha("HEAD", canonical_path)
        if root_sha != canonical_sha:
            raise SystemExit(
                f"mirror diverged; refusing cleanup: {root_path}={root_sha} {canonical_path}={canonical_sha}"
            )
        print(f"mirror proof PASS: {root_path} == {canonical_path} ({root_sha})")

    # Proof gate 2: product source and project metadata are exactly the p36 runtime baseline.
    if tree_sha("HEAD", "testmod") != tree_sha(P36_RUNTIME, "testmod"):
        raise SystemExit("testmod tree diverged from p36 runtime before p37 cleanup")
    if tree_sha("HEAD", "testmod.xcodeproj") != tree_sha(P36_RUNTIME, "testmod.xcodeproj"):
        raise SystemExit("Xcode project diverged from p36 runtime before p37 cleanup")

    # Remove only the proven-identical root mirrors. Canonical copies stay under testmod/.
    for root_path in MIRRORS:
        run("git", "rm", "-r", "--", root_path)

    Path("VERSION").write_text("v1_p37\n")

    # P36 behavior contract is inherited by p37; relax only its version gate.
    contract_path = Path("Tests/udid_web_fallback_contract.py")
    contract = contract_path.read_text()
    old_gate = 'if (ROOT / "VERSION").read_text().strip() != "v1_p36":\n    fail("VERSION must be v1_p36")\n'
    new_gate = 'if (ROOT / "VERSION").read_text().strip() not in {"v1_p36", "v1_p37"}:\n    fail("VERSION must preserve the p36 UDID fallback contract")\n'
    if contract.count(old_gate) != 1:
        raise SystemExit("unexpected p36 UDID contract version gate")
    contract_path.write_text(contract.replace(old_gate, new_gate, 1))

    # Runtime safety locks: p37 is repository-only cleanup.
    if tree_sha("HEAD", "testmod") != tree_sha(P36_RUNTIME, "testmod"):
        raise SystemExit("p37 unexpectedly changed canonical testmod runtime tree")
    if tree_sha("HEAD", "testmod.xcodeproj") != tree_sha(P36_RUNTIME, "testmod.xcodeproj"):
        raise SystemExit("p37 unexpectedly changed Xcode project")

    registry = Path("testmod/ZONCore/ZONFeatureRegistry.m").read_text()
    for identifier in ACTIVE_FEATURE_IDS:
        if f'@"{identifier}"' not in registry:
            raise SystemExit(f"active feature missing: {identifier}")
    if "runtime.placeholder-203" in registry:
        raise SystemExit("retired placeholder 203 reappeared")

    bridge = Path("testmod/ZONServices/ZONUDIDBridge.h").read_text()
    ui = Path("testmod/视图菜单/NSObject+UI.m").read_text()
    for marker in [
        "ZONUDIDBridgeRequestIfNeededWithUnavailableHandler",
        "unable to open zonoe://udid; using web fallback",
    ]:
        if marker not in bridge:
            raise SystemExit(f"p36 UDID fallback marker missing: {marker}")
    for marker in [
        "ZonoeStartLegacyWebUDIDFallback",
        "ZONUDIDBridgeStoreUDID(udid);",
    ]:
        if marker not in ui:
            raise SystemExit(f"p36 fallback wiring missing: {marker}")

    for root_path, canonical_path in MIRRORS.items():
        if Path(root_path).exists():
            raise SystemExit(f"root mirror still exists: {root_path}")
        if not Path(canonical_path).exists():
            raise SystemExit(f"canonical copy was damaged: {canonical_path}")

    run("git", "diff", "--check")
    print("p37 canonical mirror cleanup: PASS")


if __name__ == "__main__":
    main()
