#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TEMP_DIR = Path(os.environ.get("TMPDIR", "/tmp"))


def state_file(name: str) -> Path:
    session = get_session_name()
    return TEMP_DIR / f"herdr_mru_workspaces.{session}{name}"


def safe_state_part(value: str) -> str:
    return "".join(c if c.isalnum() or c in "._-" else "_" for c in value) or "default"


def get_herdr_bin():
    return os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"


def get_session_name():
    session = os.environ.get("HERDR_SESSION")
    if session:
        return safe_state_part(session)

    socket_path = os.environ.get("HERDR_SOCKET_PATH")
    data = run_json([get_herdr_bin(), "session", "list", "--json"])
    sessions = data.get("sessions") if isinstance(data, dict) else None
    if isinstance(sessions, list):
        default_session = None
        for item in sessions:
            if not isinstance(item, dict):
                continue
            if socket_path and item.get("socket_path") == socket_path:
                return safe_state_part(str(item.get("name") or "default"))
            if item.get("default") is True:
                default_session = str(item.get("name") or "default")

        if default_session:
            return safe_state_part(default_session)

    return "default"


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

    current_workspace_file = state_file("")
    last_workspace_file = state_file(".last")

    if current_workspace_file.exists():
        try:
            prev = current_workspace_file.read_text().strip()
            if prev and prev != current:
                last_workspace_file.write_text(f"{prev}\n")
                current_workspace_file.write_text(f"{current}\n")
        except Exception as e:
            sys.stderr.write(f"Error updating state files: {e}\n")
    else:
        try:
            current_workspace_file.write_text(f"{current}\n")
        except Exception as e:
            sys.stderr.write(f"Error creating state file: {e}\n")


def toggle():
    last_workspace_file = state_file(".last")

    if last_workspace_file.exists():
        try:
            target = last_workspace_file.read_text().strip()
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
