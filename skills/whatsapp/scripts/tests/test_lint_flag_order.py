import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint-flag-order.py"


def test_script_exists():
    assert SCRIPT.exists()


def test_valid_templates_pass():
    result = subprocess.run(
        ["python3", str(SCRIPT), str(ROOT)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = json.loads(result.stdout)
    assert data["valid"] is True
    assert data["violations"] == []
