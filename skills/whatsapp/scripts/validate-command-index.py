#!/usr/bin/env python3
"""Validate references/command-index.md integrity rules."""

import json
import sys
from pathlib import Path

REQUIRED_REF_FILES = {
    "install.md",
    "auth-sync.md",
    "send.md",
    "messages.md",
    "messages-mutate.md",
    "addressbook.md",
    "calls.md",
    "profile-presence.md",
    "safety.md",
    "command-index.md",
}

VALID_CLASSIFICATIONS = {"read", "write", "mixed"}

CLASSIFICATION_MAP = {
    "read": "read",
    "write": "write",
    "mixed": "mixed",
    "读": "read",
    "写": "write",
    "混合": "mixed",
}


def parse_table(markdown: str):
    rows = []
    in_table = False
    for line in markdown.splitlines():
        if line.startswith("| 命令"):
            in_table = True
            continue
        if in_table and line.startswith("|---"):
            continue
        if in_table and line.startswith("|"):
            # Preserve escaped pipes while splitting cells.
            placeholder = "\x00PIPE\x00"
            safe = line.replace("\\|", placeholder)
            cells = [c.strip().replace(placeholder, "|") for c in safe.strip("|").split("|")]
            if len(cells) >= 4:
                rows.append(
                    {
                        "subcommand": cells[0],
                        "classification": CLASSIFICATION_MAP.get(cells[1].lower(), cells[1].lower()),
                        "reference": cells[2].strip("`"),
                        "notes": cells[3],
                    }
                )
        elif in_table:
            in_table = False
    return rows


def validate(skill_dir: Path):
    errors = []
    refs_dir = skill_dir / "references"
    index_path = refs_dir / "command-index.md"

    if not index_path.exists():
        return {"valid": False, "error_count": 1, "errors": [f"missing {index_path}"]}

    rows = parse_table(index_path.read_text())

    # All reference files exist.
    for name in REQUIRED_REF_FILES:
        if not (refs_dir / name).exists():
            errors.append(f"missing reference file: {name}")

    # Every referenced file exists.
    referenced = {r["reference"] for r in rows}
    for ref in referenced:
        if not (refs_dir / ref).exists():
            errors.append(f"referenced file missing: {ref}")

    # Classification values are valid.
    for r in rows:
        if r["classification"] not in VALID_CLASSIFICATIONS:
            errors.append(
                f"invalid classification '{r['classification']}' for {r['subcommand']}"
            )

    # Subcommand strings are non-empty.
    for r in rows:
        if not r["subcommand"]:
            errors.append("empty subcommand row")

    return {
        "valid": len(errors) == 0,
        "error_count": len(errors),
        "errors": errors,
        "command_count": len(rows),
    }


if __name__ == "__main__":
    skill_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    result = validate(skill_dir)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["valid"] else 1)
