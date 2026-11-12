#!/usr/bin/env python3
"""Restart the agent in a Rex pane, resuming the same session.

Rex counterpart of ~/nix-config/dotfiles/herdr/scripts/restart-agent.py. The
restart_agent action in init.lua runs this in a detached block on the pane's
host, so it works in remote sessions as well. It reads what
agent-session-hook.py recorded for the pane, splits a replacement off the
agent pane (so it takes the old pane's slot once that closes), starts the same
agent kind there with resume arguments and closes the old pane.

Usage: restart-agent.py SESSION_ID BLOCK_ID
"""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Callable

# Agent commands that resume a given session, keyed by agent kind.
# Keep in sync with RESUME_ARGS in dotfiles/herdr/scripts/restart-agent.py.
RESUME_COMMANDS: dict[str, Callable[[str], list[str]]] = {
    "agy": lambda session_id: ["agy", "--conversation", session_id],
    "opencode": lambda session_id: ["opencode", "--session", session_id],
    "codex": lambda session_id: ["codex", "resume", session_id],
    "claude": lambda session_id: ["claude", "--resume", session_id],
}

# After the agent exits, leave a shell in the pane like herdr's restart does.
KEEP_SHELL = '"$@"; exec "${SHELL:-/bin/sh}" -l'


def setup_path() -> None:
    # Same as sesh-picker.py: keep Rex's own CLI first.
    user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""
    prefixes = [
        os.environ.get("REX_BIN_DIR"),
        f"/etc/profiles/per-user/{user}/bin",
        "/run/current-system/sw/bin",
        "/opt/homebrew/bin",
        str(Path.home() / ".nix-profile/bin"),
        "/nix/var/nix/profiles/default/bin",
    ]
    os.environ["PATH"] = ":".join(
        part for part in [*prefixes, os.environ.get("PATH")] if part
    )


def state_file(block_id: str) -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "rex" / "agents" / f"{block_id}.json"


def log(message: str) -> None:
    # The detached block has no visible screen; leave a trace for debugging.
    path = state_file("restart").with_name("restart.log")
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a") as f:
            f.write(message + "\n")
    except OSError:
        pass


def rex(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["rex", *args], text=True, capture_output=True, check=False
    )


def restart(session_id: str, block_id: str) -> None:
    path = state_file(block_id)
    try:
        entry = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        log(f"{block_id}: no agent session recorded, not restarting")
        return

    kind = entry.get("kind")
    agent_session = entry.get("session_id")
    cwd = entry.get("cwd")
    resume = RESUME_COMMANDS.get(kind) if isinstance(kind, str) else None
    if resume is None or not isinstance(agent_session, str) or not agent_session:
        log(f"{block_id}: cannot resume {entry!r}")
        return

    split = ["split", "-s", session_id, "-b", block_id, "--split", "right"]
    if isinstance(cwd, str) and os.path.isdir(cwd):
        split += ["--cwd", cwd]
    split += ["--interactive", "--json", "--", "sh", "-c", KEEP_SHELL, "sh"]
    split += resume(agent_session)
    res = rex(*split)
    if res.returncode != 0:
        log(f"{block_id}: rex {shlex.join(split)} failed: {res.stderr.strip()}")
        return

    # Move the record to the new pane right away. Its own hook only fires on
    # the next prompt (agy) or never for a resume (SessionStart may not), so
    # without this a second restart would find nothing.
    try:
        new_block = json.loads(res.stdout)["block_ids"][0]
    except (json.JSONDecodeError, KeyError, IndexError, TypeError):
        new_block = None
    if isinstance(new_block, str) and new_block:
        entry["block_id"] = new_block
        new_path = state_file(new_block)
        tmp = new_path.with_name(f".tmp-{new_block}")
        tmp.write_text(json.dumps(entry))
        os.replace(tmp, new_path)
    else:
        log(f"{block_id}: no block ID in split output {res.stdout!r}")
    path.unlink(missing_ok=True)
    res = rex("block", "close", "-s", session_id, block_id)
    if res.returncode != 0:
        log(f"{block_id}: closing old pane failed: {res.stderr.strip()}")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 0
    setup_path()
    try:
        restart(sys.argv[1], sys.argv[2])
    except Exception as e:  # noqa: BLE001
        log(f"{sys.argv[2]}: {e!r}")
    # Always exit 0: Rex keeps a block whose command fails quickly, and this
    # one is detached, so it would linger out of sight.
    return 0


if __name__ == "__main__":
    sys.exit(main())
