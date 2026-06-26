#!/usr/bin/env python3
"""Check that installed wacli version is within the tested range."""

import json
import re
import subprocess
import sys
from pathlib import Path

TARGET_MAJOR = 0
TARGET_MINOR = 11


def check(wacli_bin: str = "wacli"):
    try:
        result = subprocess.run(
            [wacli_bin, "--version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except FileNotFoundError:
        return {"installed": False, "supported": False, "error": f"{wacli_bin} not found"}
    except subprocess.TimeoutExpired:
        return {"installed": False, "supported": False, "error": "timeout"}

    text = (result.stdout + result.stderr).strip()
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text)
    if not match:
        return {"installed": True, "supported": False, "raw": text, "error": "cannot parse version"}

    major, minor, patch = map(int, match.groups())
    supported = major == TARGET_MAJOR and minor == TARGET_MINOR
    return {
        "installed": True,
        "supported": supported,
        "version": f"{major}.{minor}.{patch}",
        "target": f"{TARGET_MAJOR}.{TARGET_MINOR}.x",
        "warning": None if supported else f"wacli {major}.{minor}.{patch} is outside tested range {TARGET_MAJOR}.{TARGET_MINOR}.x",
    }


if __name__ == "__main__":
    wacli_bin = sys.argv[1] if len(sys.argv) > 1 else "wacli"
    result = check(wacli_bin)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result.get("supported") else 0)
