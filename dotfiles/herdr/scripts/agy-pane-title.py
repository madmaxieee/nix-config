#!/usr/bin/env python3
"""Antigravity CLI hook: show the current tool call as the Herdr pane title.

Display-only. It uses `pane.report_metadata`, so working/idle/blocked state
keeps coming from Herdr's screen detection, and session restore keeps coming
from the herdr-managed `antigravity-cli` integration hook.

Usage (from ~/.gemini/config/hooks.json):
  agy-pane-title.py pre_tool   # PreToolUse: set title to the tool summary
  agy-pane-title.py stop       # Stop: clear the title
"""

from __future__ import annotations

import json
import os
import socket
import sys
import time

SOURCE = "user:agy-pane-title"
AGENT = "agy"
MAX_TITLE_CHARS = 80


def summarize_tool(payload: dict) -> str:
    tool_call = payload.get("toolCall")
    if not isinstance(tool_call, dict):
        return ""
    name = str(tool_call.get("name") or "")
    args = tool_call.get("args")
    if not isinstance(args, dict):
        args = {}

    summary = str(args.get("toolSummary") or "").strip()
    if summary:
        return summary[:MAX_TITLE_CHARS]

    if name == "run_command":
        lines = str(args.get("CommandLine") or "").strip().splitlines()
        detail = lines[0] if lines else ""
    else:
        path = (
            args.get("AbsolutePath")
            or args.get("TargetFile")
            or args.get("Path")
            or ""
        )
        detail = os.path.basename(str(path)) if path else ""

    text = f"{name}: {detail}" if detail else name
    return text[:MAX_TITLE_CHARS]


def report_metadata(socket_path: str, params: dict) -> None:
    seq = time.time_ns()
    request = {
        "id": f"{SOURCE}:{seq}",
        "method": "pane.report_metadata",
        "params": {"source": SOURCE, "agent": AGENT, "seq": seq, **params},
    }
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(0.3)
            client.connect(socket_path)
            client.sendall((json.dumps(request) + "\n").encode())
            client.recv(4096)
    except OSError:
        pass


def main() -> int:
    # Print nothing: empty stdout means "no opinion" and the hook result is
    # skipped for every event. Do NOT print `{}` here -- on PreToolUse a result
    # with no `decision` falls back to the deprecated `allowTool` (false) and is
    # treated as DENY, blocking every tool call.
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    pane_id = os.environ.get("HERDR_PANE_ID", "").strip()
    socket_path = os.environ.get("HERDR_SOCKET_PATH", "").strip()
    if os.environ.get("HERDR_ENV") != "1" or not pane_id or not socket_path:
        return 0

    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        payload = {}
    if not isinstance(payload, dict):
        payload = {}

    if mode == "pre_tool":
        title = summarize_tool(payload)
        if title:
            report_metadata(socket_path, {"pane_id": pane_id, "title": title})
    elif mode == "stop":
        report_metadata(socket_path, {"pane_id": pane_id, "clear_title": True})
    return 0


if __name__ == "__main__":
    sys.exit(main())
