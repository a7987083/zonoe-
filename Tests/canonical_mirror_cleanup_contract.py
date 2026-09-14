#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
P36_RUNTIME = "c85a6a235daf3287b70c13fbe69be455a3aecce2"
ROOT_MIRRORS = ["category", "工具箱", "SVProgressHUD", "Package"]
CANONICAL = ["testmod/category", "testmod/工具箱", "testmod/SVProgressHUD", "testmod/Package"]


def fail(msg: str) -> None:
    print(f"canonical-mirror-contract: FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def sha(ref: str, path: str) -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", f"{ref}:{path}"], text=True).strip()
    except subprocess.CalledProcessError:
        return ""

if (ROOT / "VERSION").read_text().strip() != "v1_p37":
    fail("VERSION must be v1_p37")

for path in ROOT_MIRRORS:
    if (ROOT / path).exists():
        fail(f"retired root mirror still exists: {path}")

for path in CANONICAL:
    if not (ROOT / path).exists():
        fail(f"canonical testmod path missing: {path}")

if sha("HEAD", "testmod") != sha(P36_RUNTIME, "testmod"):
    fail("canonical testmod tree changed from p36 runtime")
if sha("HEAD", "testmod.xcodeproj") != sha(P36_RUNTIME, "testmod.xcodeproj"):
    fail("Xcode project changed from p36 runtime")

registry = (ROOT / "testmod/ZONCore/ZONFeatureRegistry.m").read_text()
for identifier in [
    "base.remote-download", "base.cloud-save", "base.local-files",
    "data.backup-save", "data.restore-save", "data.clear-game-data",
    "auth.clear-records", "runtime.iap-noads", "runtime.ad-speed",
]:
    if f'@"{identifier}"' not in registry:
        fail(f"active feature missing: {identifier}")
if "runtime.placeholder-203" in registry:
    fail("retired placeholder 203 reappeared")

print("canonical-mirror-contract: PASS")
