#!/usr/bin/env python3
"""Run WhatsApp skill evals against the mock wacli shim.

Usage:
    python3 run-eval.py [--mock-path PATH] [--evals PATH]
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run_case(case, mock_path):
    prompt = case["prompt"]
    # Invoke the model/agent with the prompt and capture the proposed wacli command(s).
    # This stub uses the expected_command(s) directly for deterministic CI; replace with
    # actual model invocation in production eval harness.
    expected = case.get("expected_command") or case.get("expected_commands", [])
    if isinstance(expected, str):
        expected = [expected]

    results = []
    for cmd in expected:
        # Run the command through the mock shim.
        proc = subprocess.run(
            [str(mock_path)] + cmd.split()[1:],  # strip leading 'wacli'
            capture_output=True,
            text=True,
        )
        try:
            envelope = json.loads(proc.stdout)
        except json.JSONDecodeError:
            envelope = {"success": False, "error": "invalid JSON", "raw": proc.stdout}
        results.append({
            "command": cmd,
            "returncode": proc.returncode,
            "success": envelope.get("success", False),
            "error": envelope.get("error"),
        })

    all_pass = all(r["success"] for r in results)
    return {
        "id": case["id"],
        "name": case["name"],
        "pass": all_pass,
        "results": results,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mock-path", default=str(ROOT / "evals" / "mock-wacli.py"))
    parser.add_argument("--evals", default=str(ROOT / "evals" / "evals.json"))
    args = parser.parse_args()

    with open(args.evals) as f:
        suite = json.load(f)

    summary = []
    for case in suite["evals"]:
        summary.append(run_case(case, args.mock_path))

    passed = sum(1 for r in summary if r["pass"])
    total = len(summary)
    print(json.dumps({
        "passed": passed,
        "total": total,
        "results": summary,
    }, indent=2))
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
