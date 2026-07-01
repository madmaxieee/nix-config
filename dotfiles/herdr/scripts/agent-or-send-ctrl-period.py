#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys


def herdr_bin() -> str:
    return os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"


def run_json(*args: str) -> dict | None:
    try:
        proc = subprocess.run(
            [herdr_bin(), *args],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
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


def deep_get(data: object, *keys: str) -> object:
    current = data
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def current_pane_id() -> str | None:
    pane_id = os.environ.get("HERDR_ACTIVE_PANE_ID")
    if pane_id:
        return pane_id

    data = run_json("pane", "current", "--current")
    pane_id = deep_get(data, "result", "pane", "pane_id")
    return pane_id if isinstance(pane_id, str) else None


def pane_info(pane_id: str) -> dict:
    data = run_json("pane", "get", pane_id)
    pane = deep_get(data, "result", "pane")
    return pane if isinstance(pane, dict) else {}


def is_agent_pane(pane: dict) -> bool:
    return bool(pane.get("agent") or pane.get("agent_session"))


def send_ctrl_period(pane_id: str) -> int:
    return subprocess.run(
        [herdr_bin(), "pane", "send-keys", pane_id, "ctrl+period"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode


def focus_other_pane(pane_id: str) -> int:
    for direction in ("left", "right", "down", "up"):
        data = run_json("pane", "focus", "--direction", direction, "--pane", pane_id)
        if deep_get(data, "result", "focus", "changed") is True:
            return 0

    return 1


def main() -> int:
    pane_id = current_pane_id()
    if not pane_id:
        return 1

    pane = pane_info(pane_id)
    if is_agent_pane(pane):
        return focus_other_pane(pane_id)

    return send_ctrl_period(pane_id)


if __name__ == "__main__":
    sys.exit(main())
