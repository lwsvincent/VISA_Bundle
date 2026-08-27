# Release Notes

All release notes for the visa_bundle project.

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
