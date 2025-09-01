#!/usr/bin/env python3
"""Pytest wrapper for shell script smoke tests (cross-platform CI helper)."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "scripts"


def run_script(name: str, *args: str) -> subprocess.CompletedProcess[str]:
    script = SCRIPTS / name
    assert script.exists(), f"missing script: {script}"
    return subprocess.run(
        ["bash", str(script), *args],
        capture_output=True,
        text=True,
        check=False,
        env={**os.environ, "PATH": f"{SCRIPTS}{os.pathsep}{os.environ.get('PATH', '')}"},
    )


def test_health_check_smoke() -> None:
    result = run_script("health-check.sh")
    assert result.returncode == 0, result.stderr
    assert "Health check complete" in result.stdout


def test_disk_alert_invalid_threshold() -> None:
    result = run_script("disk-alert.sh", "not-a-number")
    assert result.returncode == 2


def test_log_parser_sample(tmp_path: Path) -> None:
    logfile = tmp_path / "access.log"
    logfile.write_text(
        '127.0.0.1 - - [10/Oct/2023:13:55:36 +0000] "GET / HTTP/1.1" 200 10\n',
        encoding="utf-8",
    )
    result = run_script("log-parser.sh", str(logfile))
    assert result.returncode == 0
    assert "total_requests 1" in result.stdout


if __name__ == "__main__":
    import pytest

    raise SystemExit(pytest.main([__file__]))
