#!/usr/bin/env python3
"""Lint reference files for global-flag ordering convention.

Global flags (--json, --read-only, --account, --store, --timeout, --full, --events)
must appear immediately after the 'wacli' token and before the subcommand.
"""

import json
import re
import sys
from pathlib import Path

GLOBAL_FLAGS = {"--json", "--read-only", "--account", "--store", "--timeout", "--full", "--events"}


def find_violations(text: str, source: str):
    violations = []
    # Match fenced bash blocks containing wacli invocations.
    for block in re.finditer(r"```bash\n(.*?)\n```", text, re.DOTALL):
        for line in block.group(1).splitlines():
            line = line.strip()
            if not line.startswith("wacli "):
                continue
            tokens = line.split()
            # tokens[0] == 'wacli'
            subcommand_idx = None
            for i, tok in enumerate(tokens[1:], start=1):
                if tok.startswith("-"):
                    continue
                subcommand_idx = i
                break
            if subcommand_idx is None:
                continue
            for i, tok in enumerate(tokens[1:subcommand_idx], start=1):
                if tok in GLOBAL_FLAGS:
                    continue
                if tok.startswith("-"):
                    violations.append(
                        f"{source}: non-global flag '{tok}' before subcommand at position {i}: {line}"
                    )
            for i, tok in enumerate(tokens[subcommand_idx:], start=subcommand_idx):
                if tok in GLOBAL_FLAGS:
                    violations.append(
                        f"{source}: global flag '{tok}' after subcommand: {line}"
                    )
    return violations


def lint(skill_dir: Path):
    refs_dir = skill_dir / "references"
    all_violations = []
    for path in sorted(refs_dir.glob("*.md")):
        all_violations.extend(find_violations(path.read_text(), path.name))
    return {
        "valid": len(all_violations) == 0,
        "violations": all_violations,
    }


if __name__ == "__main__":
    skill_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    result = lint(skill_dir)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["valid"] else 1)
