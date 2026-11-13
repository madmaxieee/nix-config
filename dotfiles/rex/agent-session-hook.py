#!/usr/bin/env python3
"""Record which agent session runs in a Rex pane, for restart-agent.py.

Agent hooks call this with the agent kind and the hook payload on stdin. It writes
$XDG_STATE_HOME/rex/agents/<REX_BLOCK>.json on the machine the agent runs on,
which is also where restart-agent.py runs, so it works on remote hosts too.

Usage (from the agent's hook config):
  agent-session-hook.py agy     # Antigravity CLI PreInvocation hook
  agent-session-hook.py claude  # Claude Code SessionStart hook
  agent-session-hook.py codex   # Codex SessionStart hook
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import time
from pathlib import Path

# Payload field holding the session ID, keyed by agent kind.
SESSION_FIELDS = {
    "agy": "conversationId",
    "claude": "session_id",
    "codex": "session_id",
}


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "rex" / "agents"


def record(kind: str) -> None:
    block_id = os.environ.get("REX_BLOCK")
    field = SESSION_FIELDS.get(kind)
    if not block_id or not field:
        return

    payload = json.load(sys.stdin)
    if not isinstance(payload, dict):
        return
    session_id = payload.get(field)
    if not isinstance(session_id, str) or not session_id:
        return
    cwd = payload.get("cwd")
    if not isinstance(cwd, str) or not cwd:
        cwd = os.getcwd()

    entry = {
        "kind": kind,
        "session_id": session_id,
        "cwd": cwd,
        "block_id": block_id,
        "rex_session": os.environ.get("REX_SESSION"),
        "updated_at": time.time(),
    }
    directory = state_dir()
    directory.mkdir(parents=True, exist_ok=True)
    # Write atomically: the hook can fire on every prompt.
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".tmp-")
    with os.fdopen(fd, "w") as f:
        json.dump(entry, f)
    os.replace(tmp, directory / f"{block_id}.json")


def main() -> int:
    kind = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        record(kind)
    except Exception:  # Never break the agent over bookkeeping.
        pass
    # Antigravity CLI expects a JSON object on stdout. Claude Code and Codex
    # would add SessionStart stdout to the model's context, so print nothing.
    if kind == "agy":
        print("{}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
