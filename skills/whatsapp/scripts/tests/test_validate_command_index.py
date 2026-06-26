import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "validate-command-index.py"
INDEX = ROOT / "references" / "command-index.md"


def test_script_exists():
    assert SCRIPT.exists(), f"missing {SCRIPT}"


def test_index_exists():
    assert INDEX.exists(), f"missing {INDEX}"


def test_validate_passes():
    result = subprocess.run(
        ["python3", str(SCRIPT), str(ROOT)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = json.loads(result.stdout)
    assert data["valid"] is True
    assert data["error_count"] == 0
