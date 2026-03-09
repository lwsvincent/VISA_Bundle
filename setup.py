"""
setup.py - Custom build hooks for PYC wheel packaging.

Overrides build_py to:
  1. Compile visa_bundle implementation .py files to .pyc in the build directory.
  2. Remove those .py files from the build directory (keep __init__.py).

Overrides bdist_wheel to force cp311-cp311-win_amd64 wheel tag.
"""

import compileall
from pathlib import Path
from setuptools import setup
from setuptools.command.build_py import build_py
from wheel.bdist_wheel import bdist_wheel


# .py filenames to always KEEP (never delete)
KEEP_FILES = {"__init__.py"}


class BuildPyWithPyc(build_py):
    """Custom build_py that compiles protected modules and removes source."""

    def run(self):
        # Step 1: Let setuptools copy all .py files into build/lib/ normally
        super().run()

        # Step 2: Locate the visa_bundle package in the build directory
        build_lib = self.build_lib  # e.g., build/lib
        pkg_build_dir = Path(build_lib) / "visa_bundle"

        if not pkg_build_dir.exists():
            return

        # Step 3: Compile root package modules (non-recursive)
        compileall.compile_dir(
            str(pkg_build_dir),
            force=True,
            quiet=1,
            legacy=True,   # Use __pycache__/name.cpython-311.pyc layout
            optimize=0,     # Standard .pyc (no optimization)
        )

        # Step 4: Remove .py files, keeping KEEP_FILES
        for py_file in pkg_build_dir.glob("*.py"):
            if py_file.name not in KEEP_FILES:
                py_file.unlink()


class BdistWheelCp311(bdist_wheel):
    """Force cp311-cp311-win_amd64 wheel tag."""

    def get_tag(self):
        return ("cp311", "cp311", "win_amd64")


setup(
    cmdclass={
        "build_py": BuildPyWithPyc,
        "bdist_wheel": BdistWheelCp311,
    },
)
