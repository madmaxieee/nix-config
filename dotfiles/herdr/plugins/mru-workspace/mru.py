#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TEMP_DIR = Path(os.environ.get("TMPDIR", "/tmp"))
CURRENT_WORKSPACE_FILE = TEMP_DIR / "herdr_mru_workspaces"
LAST_WORKSPACE_FILE = TEMP_DIR / "herdr_mru_workspaces.last"


def get_herdr_bin():
    return os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"


def run_json(argv: list[str]) -> dict | list | None:
    try:
        proc = subprocess.run(
            argv,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError:
        return None
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None


def get_active_workspace_id():
    data = run_json([get_herdr_bin(), "workspace", "list"])
    if not isinstance(data, dict):
        return None

    result = data.get("result")
    if not isinstance(result, dict):
        return None

    workspaces = result.get("workspaces")
    if not isinstance(workspaces, list):
        return None

    for ws in workspaces:
        if isinstance(ws, dict) and ws.get("focused") is True:
            return ws.get("workspace_id")

    return None


def track():
    current = get_active_workspace_id()
    if not current:
        return

    if CURRENT_WORKSPACE_FILE.exists():
        try:
            prev = CURRENT_WORKSPACE_FILE.read_text().strip()
            if prev and prev != current:
                LAST_WORKSPACE_FILE.write_text(f"{prev}\n")
                CURRENT_WORKSPACE_FILE.write_text(f"{current}\n")
        except Exception as e:
            sys.stderr.write(f"Error updating state files: {e}\n")
    else:
        try:
            CURRENT_WORKSPACE_FILE.write_text(f"{current}\n")
        except Exception as e:
            sys.stderr.write(f"Error creating state file: {e}\n")


def toggle():
    if LAST_WORKSPACE_FILE.exists():
        try:
            target = LAST_WORKSPACE_FILE.read_text().strip()
            if target:
                subprocess.run(
                    [get_herdr_bin(), "workspace", "focus", target], check=False
                )
        except Exception as e:
            sys.stderr.write(f"Error focusing workspace: {e}\n")


def main():
    parser = argparse.ArgumentParser(description="MRU Workspace Manager for Herdr")
    subparsers = parser.add_subparsers(dest="action", required=True)

    subparsers.add_parser("track", help="Track current focused workspace")
    subparsers.add_parser("toggle", help="Toggle to the previously active workspace")

    args = parser.parse_args()

    if args.action == "track":
        track()
    elif args.action == "toggle":
        toggle()


if __name__ == "__main__":
    main()
