# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.6] - 2026-11-05

### Added
- 通用多廠區環境驗證支援：新增泰國廠 MES IP (`10.51.64.67`) ping 檢測，並支援 `ACBEL_MES_IP` 環境變數動態覆寫。

### Changed
- 升級為通用多廠區驗證架構（Universal Multi-Site Validation）：依序以短路求值檢查台灣 PNT52 網芳、泰國 MES 系統與備用網路主機，任一站點符合即授權啟用。

## [2.0.5] - 2026-08-27

### Fixed
- Removed the forced PNT52 validation bypass so environment checks now use the actual PNT52 share status.

### Changed
- Added `LWS.acbel.com` as a backup fallback network host alongside `dq-ework.apitech.com.tw`.

## [2.0.4] - 2026-04-24

### Fixed
- Wrap `clear()` in try-except to ignore unsupported VISA command on Chroma models (#3)

## [2.0.3] - 2026-04-10

### Changed
- Disable stub generation in pyc_config to fix project/package name collision bug
- Set model to haiku for release-pyc skill

## [2.0.2] - 2026-04-07

### Added
- 加入備用驗證機制

## [2.0.1] - 2026-03-13

### Added
- Add `py.typed` marker file for PEP 561 type hint compliance

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
