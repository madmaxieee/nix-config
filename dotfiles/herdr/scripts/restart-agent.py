#!/usr/bin/env python3
"""Restart the agent in the focused herdr pane, resuming the same session.

Mirrors agentmux's herdr backend restart (~/.config/nvim/lua/agentmux/backend/
herdr.lua): read the agent's name, kind, cwd and session id, close its pane and
start the same agent kind under the same name with resume arguments.

Unlike agentmux, the replacement pane is split off the agent pane *before* the
old pane is closed, so it takes over the old pane's slot in the layout.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from typing import Callable

# Agent arguments that resume a given session, keyed by herdr agent kind.
# Keep in sync with `resume_args` of the agentmux providers in nvim.
RESUME_ARGS: dict[str, Callable[[str], list[str]]] = {
    "agy": lambda session_id: ["--conversation", session_id],
    "opencode": lambda session_id: ["--session", session_id],
    "codex": lambda session_id: ["resume", session_id],
    "claude": lambda session_id: ["--resume", session_id],
}


def herdr_bin() -> str:
    return os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [herdr_bin(), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def run_json(*args: str) -> dict | None:
    try:
        proc = run(*args)
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


def notify(title: str, body: str = "") -> None:
    args = ["notification", "show", title]
    if body:
        args += ["--body", body]
    subprocess.run(
        [herdr_bin(), *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def current_pane_id() -> str | None:
    pane_id = os.environ.get("HERDR_ACTIVE_PANE_ID")
    if pane_id:
        return pane_id

    data = run_json("pane", "current", "--current")
    pane_id = deep_get(data, "result", "pane", "pane_id")
    return pane_id if isinstance(pane_id, str) else None


def main() -> int:
    pane_id = current_pane_id()
    if not pane_id:
        return 1

    agent = deep_get(run_json("agent", "get", pane_id), "result", "agent")
    if not isinstance(agent, dict):
        # Focused pane is not an agent: nothing to restart.
        return 0

    kind = agent.get("agent")
    name = agent.get("name")
    cwd = agent.get("cwd")
    session_id = deep_get(agent, "agent_session", "value")

    resume_args = RESUME_ARGS.get(kind) if isinstance(kind, str) else None
    if resume_args is None:
        notify("Restart agent", f"No resume args for agent kind {kind!r}")
        return 1
    if not isinstance(session_id, str) or not session_id:
        notify("Restart agent", "Agent has no session id, not restarting")
        return 1

    # Split the replacement off the agent pane so that, once the old pane is
    # closed, the new one occupies exactly the old pane's slot.
    split_cmd = ["pane", "split", pane_id, "--direction", "right", "--focus"]
    if isinstance(cwd, str) and cwd:
        split_cmd += ["--cwd", cwd]
    new_pane_id = deep_get(run_json(*split_cmd), "result", "pane", "pane_id")
    if not isinstance(new_pane_id, str):
        notify("Restart agent", "Failed to split pane")
        return 1

    # Close the old pane (and wait) so the agent name is released before reuse.
    run("pane", "close", pane_id)

    start_cmd = ["agent", "start"]
    if isinstance(name, str) and name:
        start_cmd.append(name)
    else:
        start_cmd.append(f"{kind}-{session_id[:8]}")
    start_cmd += ["--kind", kind, "--pane", new_pane_id, "--"]
    start_cmd += resume_args(session_id)

    # The new pane's shell may not be at its prompt yet; retry like agentmux.
    res = None
    for _ in range(10):
        res = run(*start_cmd)
        if res.returncode == 0:
            return 0
        time.sleep(0.1)

    notify("Restart agent", "Failed to start agent: " + (res.stderr.strip() if res else ""))
    return 1


if __name__ == "__main__":
    sys.exit(main())
