"""
Unit tests for Universal Multi-Site Validation (Taiwan PNT52, Thailand MES, Fallback hosts).
"""

import os
import sys
import subprocess
import pytest
from unittest.mock import patch, MagicMock

src_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src")
if src_path not in sys.path:
    sys.path.insert(0, src_path)


def _clean_visa_modules():
    for mod_name in ["visa_bundle.VISA", "visa_bundle"]:
        sys.modules.pop(mod_name, None)


def test_validation_passes_when_pnt52_exists(monkeypatch):
    """When Taiwan PNT52 share exists, import succeeds immediately without pinging."""
    monkeypatch.setattr(os.path, "exists", lambda p: True)
    
    # Subprocess.run should NOT even be called because of short-circuiting
    mock_run = MagicMock()
    monkeypatch.setattr(subprocess, "run", mock_run)

    _clean_visa_modules()
    import importlib
    visa_mod = importlib.import_module("visa_bundle.VISA")
    assert visa_mod._pnt52_ok is True
    assert visa_mod._thailand_mes_ok is False
    assert visa_mod._fallback_ok is False
    mock_run.assert_not_called()


def test_validation_passes_when_thailand_mes_pings(monkeypatch):
    """When PNT52 is unreachable but Thailand MES IP pings, import succeeds."""
    monkeypatch.setattr(os.path, "exists", lambda p: False)
    monkeypatch.setenv("ACBEL_MES_IP", "10.51.64.67")

    def mock_run(cmd, *args, **kwargs):
        res = MagicMock()
        # Ping to Thailand MES succeeds
        if "10.51.64.67" in cmd:
            res.returncode = 0
        else:
            res.returncode = 1
        return res

    monkeypatch.setattr(subprocess, "run", mock_run)

    _clean_visa_modules()
    import importlib
    visa_mod = importlib.import_module("visa_bundle.VISA")
    assert visa_mod._pnt52_ok is False
    assert visa_mod._thailand_mes_ok is True
    assert visa_mod._fallback_ok is False


def test_validation_passes_when_fallback_host_pings(monkeypatch):
    """When PNT52 and Thailand MES fail, fallback host ping succeeds."""
    monkeypatch.setattr(os.path, "exists", lambda p: False)
    monkeypatch.setenv("ACBEL_MES_IP", "10.51.64.67")

    def mock_run(cmd, *args, **kwargs):
        res = MagicMock()
        if "LWS.acbel.com" in cmd:
            res.returncode = 0
        else:
            res.returncode = 1
        return res

    monkeypatch.setattr(subprocess, "run", mock_run)

    _clean_visa_modules()
    import importlib
    visa_mod = importlib.import_module("visa_bundle.VISA")
    assert visa_mod._pnt52_ok is False
    assert visa_mod._thailand_mes_ok is False
    assert visa_mod._fallback_ok is True


def test_validation_fails_when_all_fail(monkeypatch):
    """When PNT52, Thailand MES, and all fallback hosts fail, EnvironmentError is raised."""
    monkeypatch.setattr(os.path, "exists", lambda p: False)
    
    def mock_run(*args, **kwargs):
        res = MagicMock()
        res.returncode = 1
        return res

    monkeypatch.setattr(subprocess, "run", mock_run)

    _clean_visa_modules()
    with pytest.raises(EnvironmentError, match="VISA Bundle 環境驗證失敗"):
        import importlib
        importlib.import_module("visa_bundle.VISA")

