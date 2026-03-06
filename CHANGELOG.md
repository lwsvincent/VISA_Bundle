# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-03-06

### Added
- `setup.py` with custom `BuildPyWithPyc` command that compiles protected
  `.py` modules to `.pyc` bytecode and removes source files from the build
  directory, keeping only `__init__.py` as plain source.
- `BdistWheelCp311` command in `setup.py` that forces the wheel platform tag
  to `cp311-cp311-win_amd64` for explicit CPython 3.11 targeting.
- `scripts/build_pyc_wheel.bat` orchestration script that runs stubgen to
  generate `.pyi` stubs, invokes the custom wheel build, and verifies that
  `.pyc` files are present and no unprotected `.py` files leaked into the
  final wheel.
- `.claude/skills/release-pyc/skill.md` for an automated PYC release
  workflow within Claude Code.
- `pyproject.toml` package-data entry `__pycache__/*.pyc` to ensure compiled
  bytecode is included when setuptools collects package data.

### Changed
- Major version incremented to 2.0.0 to reflect the new bytecode-compiled
  distribution model.

## [1.0.0] - 2026-02-12

### Fixed
- Bug fix for initialization process

### Added
- Protected wheel build script for bytecode-compiled distribution