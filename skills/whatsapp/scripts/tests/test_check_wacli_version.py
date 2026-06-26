import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "check-wacli-version.py"


def test_script_exists():
    assert SCRIPT.exists()


def test_with_mock_version():
    fake_wacli = ROOT / "scripts" / "tests" / "fake-wacli"
    try:
        fake_wacli.write_text("#!/bin/sh\necho 'wacli version 0.11.4'\n")
        fake_wacli.chmod(0o755)
        result = subprocess.run(
            ["python3", str(SCRIPT), str(fake_wacli)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["supported"] is True
        assert data["version"] == "0.11.4"
    finally:
        if fake_wacli.exists():
            fake_wacli.unlink()
