# Release Notes

All release notes for the visa_bundle project.

---

## v2.0.6 - 2026-11-05

### Summary
Adds universal multi-site environment validation with support for Thailand MES IP ping verification.

### Added
- Thailand plant MES IP ping validation: `10.51.64.67`.
- Support for `ACBEL_MES_IP` environment variable override.

### Changed
- Refactored environment validation into a Universal Multi-Site model using short-circuit evaluation (Taiwan PNT52 share -> Thailand MES IP -> Backup network hosts).
- Added comprehensive unit tests for multi-site validation (47 passed).

### Upgrade Notes
- No API changes. Fully compatible with `tm_updater`.

---

## v2.0.5 - 2026-08-27

### Summary
Restores real PNT52 environment validation and adds the backup LWS network host.

### Fixed
- Removed the forced `_pnt52_ok = True` bypass from `VISA.py`.

### Changed
- Environment validation now accepts either `dq-ework.apitech.com.tw` or `LWS.acbel.com` when the PNT52 share is unavailable.

### Upgrade Notes
- No API changes.
- The package may now raise its environment validation error again if neither PNT52 nor either fallback host is reachable.
