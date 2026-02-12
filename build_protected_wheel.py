"""
Build wheel with compiled .pyc bytecode for source protection.

Keeps __init__.py as readable source (for LSP/type hints),
compiles VISA.py and Setting.py to .pyc only.
"""

import subprocess
import sys
import zipfile
import shutil
import py_compile
import hashlib
import base64
import csv
import io
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent
SRC_PKG = PROJECT_ROOT / "src" / "visa_bundle"
DIST_DIR = PROJECT_ROOT / "dist"

# Files to compile (remove source, keep only .pyc)
FILES_TO_COMPILE = ["VISA.py", "Setting.py"]

# Files to keep as source
FILES_TO_KEEP = ["__init__.py"]


def build_wheel():
    """Step 1: Build normal wheel."""
    if DIST_DIR.exists():
        shutil.rmtree(DIST_DIR)

    subprocess.check_call(
        [sys.executable, "-m", "build", "--wheel"],
        cwd=str(PROJECT_ROOT),
    )

    wheels = list(DIST_DIR.glob("*.whl"))
    if not wheels:
        raise FileNotFoundError("No wheel found after build")
    return wheels[0]


def record_hash(data: bytes) -> str:
    """Calculate RECORD hash (sha256 in urlsafe-base64, no padding)."""
    digest = hashlib.sha256(data).digest()
    return "sha256=" + base64.urlsafe_b64encode(digest).rstrip(b"=").decode()


def patch_wheel(whl_path: Path) -> Path:
    """Step 2: Replace .py source with .pyc in the wheel."""
    tmp_whl = whl_path.with_suffix(".tmp.whl")
    pkg_prefix = "visa_bundle/"

    # Compile .py -> .pyc
    pyc_data = {}
    for fname in FILES_TO_COMPILE:
        src = SRC_PKG / fname
        pyc_path = SRC_PKG / (fname + "c")
        py_compile.compile(str(src), cfile=str(pyc_path), doraise=True)
        pyc_data[fname] = pyc_path.read_bytes()
        pyc_path.unlink()  # clean up temp .pyc

    # Rewrite the wheel zip
    with zipfile.ZipFile(whl_path, "r") as zin, \
         zipfile.ZipFile(tmp_whl, "w", zipfile.ZIP_DEFLATED) as zout:

        record_path = None
        record_entries = []

        for item in zin.infolist():
            data = zin.read(item.filename)
            base = item.filename.split("/")[-1]

            # Find RECORD file path
            if item.filename.endswith("/RECORD"):
                record_path = item.filename
                continue  # rebuild later

            # Skip source files that should be compiled
            if base in FILES_TO_COMPILE and item.filename.startswith(pkg_prefix):
                # Write .pyc instead
                pyc_name = item.filename + "c"  # e.g. visa_bundle/VISA.pyc
                pyc_bytes = pyc_data[base]
                zout.writestr(pyc_name, pyc_bytes)
                record_entries.append((
                    pyc_name,
                    record_hash(pyc_bytes),
                    str(len(pyc_bytes)),
                ))
                continue

            # Keep everything else as-is
            zout.writestr(item, data)
            record_entries.append((
                item.filename,
                record_hash(data),
                str(len(data)),
            ))

        # Write updated RECORD
        if record_path:
            buf = io.StringIO()
            writer = csv.writer(buf)
            for entry in record_entries:
                writer.writerow(entry)
            writer.writerow((record_path, "", ""))
            record_bytes = buf.getvalue().encode("utf-8")
            zout.writestr(record_path, record_bytes)

    # Replace original wheel
    whl_path.unlink()
    tmp_whl.rename(whl_path)
    return whl_path


def main():
    print("=== Building protected wheel ===")
    print()

    print("[1/2] Building wheel...")
    whl = build_wheel()
    print(f"  Built: {whl.name}")

    print("[2/2] Patching wheel (compiling .py -> .pyc)...")
    whl = patch_wheel(whl)
    print(f"  Done: {whl.name}")

    # Verify contents
    print()
    print("=== Wheel contents ===")
    with zipfile.ZipFile(whl, "r") as z:
        for name in sorted(z.namelist()):
            if "visa_bundle/" in name:
                print(f"  {name}")

    print()
    print(f"Output: {whl}")


if __name__ == "__main__":
    main()
