# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-07-11

### Added
- Initial release of VISA Bundle package
- VISA class for instrument communication management
- Opened_List for tracking active connections
- Setting module for global configuration
- Support for automatic connection management
- Error handling and auto-reconnection features
- Test mode support (VISA_Send_Enable setting)
- Debug output control (VISA_Print_Enable setting)
- Comprehensive documentation and examples
- Development tools and build scripts

### Features
- 🚀 **統一管理**: 封裝 pyvisa 為易用的類別介面
- 🔌 **連線管理**: 自動管理 VISA 連線，避免重複開啟
- 🎛️ **全域設定**: 統一控制通訊啟用/除錯列印等功能
- 📊 **錯誤處理**: 完善的錯誤回報和自動重連機制
- 🔧 **測試友善**: 支援測試模式，可模擬儀器回應

### Dependencies
- pyvisa >= 1.11.0
- Python >= 3.8

[Unreleased]: https://github.com/dsplatform/visa-bundle/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dsplatform/visa-bundle/releases/tag/v0.1.0
