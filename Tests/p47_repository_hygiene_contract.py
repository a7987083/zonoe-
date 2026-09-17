#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = "d88ccd28d1e282860baed0b40d3997629b8205b8"


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def fail(msg: str) -> None:
    raise AssertionError(msg)

# P47 is repository-only: canonical product trees must be byte-identical to P46.
for path in ("testmod", "testmod.xcodeproj"):
    base_sha = git("rev-parse", f"{BASE}:{path}")
    head_sha = git("rev-parse", f"HEAD:{path}")
    if head_sha != base_sha:
        fail(f"canonical product tree drift: {path}: {base_sha} -> {head_sha}")

version = (ROOT / "VERSION").read_text().strip()
if version != "v1_p47":
    fail(f"unexpected VERSION: {version}")

tracked = set(git("ls-files").splitlines())

# Removed package artifact must not return.
old_pkg = "Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip"
if old_pkg in tracked:
    fail("old generated package artifact is still tracked")

# No user/build/package outputs may be tracked after P47.
for path in sorted(tracked):
    low = path.lower()
    if "/xcuserdata/" in f"/{low}" or low.endswith(".xcuserstate"):
        fail(f"tracked Xcode user state: {path}")
    if low == ".ds_store" or low.endswith("/.ds_store"):
        fail(f"tracked macOS metadata: {path}")
    if low.startswith("build/") or "/deriveddata/" in f"/{low}":
        fail(f"tracked build output: {path}")
    if low.startswith("packages/") and low.endswith(".zip"):
        fail(f"tracked generated package ZIP: {path}")

ignore = (ROOT / ".gitignore").read_text()
required = [
    "xcuserdata/",
    "build/",
    "DerivedData/",
    "*.dylib",
    "*.deb",
    ".DS_Store",
    "Packages/*.zip",
]
for rule in required:
    if rule not in ignore:
        fail(f"missing ignore rule: {rule}")

pbx = (ROOT / "testmod.xcodeproj/project.pbxproj").read_text()
source_members = sum(1 for line in pbx.splitlines() if " in Sources */" in line)
if source_members != 79:
    fail(f"active PBX Sources drift: {source_members}, expected 79")

print("p47-repository-hygiene-contract: OK")
print("canonical product trees identical to P46")
print("active PBX Sources: 79")
