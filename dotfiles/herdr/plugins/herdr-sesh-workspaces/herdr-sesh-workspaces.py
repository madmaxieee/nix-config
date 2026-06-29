#!/usr/bin/env python3
"""herdr-sesh-workspaces: a tiny herdr workspace picker backed by sesh.

What it does:

  - Shows existing herdr workspaces and focuses the selected one.
  - Shows `sesh list --json --zoxide` entries and creates/focuses a new herdr
    workspace rooted at the selected zoxide path.

No cloud/CITC/custom session types yet; this only covers sesh's built-in zoxide
source plus herdr's own workspaces.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


PLUGIN_ID = "madmax.herdr-sesh-workspaces"
PICKER_ENTRYPOINT = "picker"


@dataclass(frozen=True)
class Entry:
    kind: str
    title: str
    subtitle: str
    value: str

    def line(self, index: int) -> str:
        cyan = "\033[36m"
        yellow = "\033[33m"
        dim = "\033[90m"
        reset = "\033[0m"

        color = cyan if self.kind == "workspace" else yellow
        if self.title:
            title_part = f"{color}{self.title[0]}{reset}{self.title[1:]}"
        else:
            title_part = ""

        if self.subtitle:
            subtitle_part = f"{dim}{self.subtitle}{reset}"
            return f"{index:3d}. {title_part}  {dim}—{reset} {subtitle_part}"
        return f"{index:3d}. {title_part}"


def herdr_bin() -> str:
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


def run_checked(argv: list[str]) -> None:
    proc = subprocess.run(argv, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.returncode)


def workspace_entries() -> list[Entry]:
    data = run_json([herdr_bin(), "workspace", "list"])
    if not isinstance(data, dict):
        return []
    result = data.get("result")
    if not isinstance(result, dict):
        return []
    workspaces = result.get("workspaces")
    if not isinstance(workspaces, list):
        return []

    entries: list[Entry] = []
    for ws in workspaces:
        if not isinstance(ws, dict):
            continue
        wid = str(ws.get("workspace_id") or "")
        if not wid:
            continue
        focused = "*" if ws.get("focused") else " "
        number = ws.get("number", "?")
        label = str(ws.get("label") or wid)
        panes = ws.get("pane_count", 0)
        tabs = ws.get("tab_count", 0)
        status = ws.get("agent_status", "unknown")
        entries.append(
            Entry(
                kind="workspace",
                title=f"󰍹 {focused} {number}: {label}",
                subtitle=f"{tabs} tabs, {panes} panes, {status}",
                value=wid,
            )
        )
    return entries


def zoxide_entries() -> list[Entry]:
    data = run_json(["sesh", "list", "--json", "--zoxide"])
    if not isinstance(data, list):
        return []

    entries: list[Entry] = []
    seen_paths: set[str] = set()
    for item in data:
        path = str(item.get("Path") or "")
        if not path or path in seen_paths:
            continue
        seen_paths.add(path)
        name = str(item.get("Name") or Path(path).name or path)
        entries.append(
            Entry(kind="zoxide", title=f" {name}", subtitle=path, value=path)
        )
    return entries


def all_entries() -> list[Entry]:
    return workspace_entries() + zoxide_entries()


def choose_with_fzf(entries: list[Entry]) -> Entry | None:
    fzf = shutil.which("fzf")
    if not fzf:
        return None

    lines = [entry.line(i + 1) for i, entry in enumerate(entries)]
    proc = subprocess.run(
        [fzf, "--ansi", "--prompt", "workspace > ", "--height", "100%", "--reverse"],
        input="\n".join(lines) + "\n",
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        selected = int(proc.stdout.strip().split(".", 1)[0]) - 1
    except ValueError:
        return None
    return entries[selected] if 0 <= selected < len(entries) else None


def choose_numbered(entries: list[Entry]) -> Entry | None:
    print("Sesh Workspaces\n")
    for i, entry in enumerate(entries, 1):
        print(entry.line(i))
    print()
    raw = input("workspace > ").strip()
    if not raw:
        return None
    try:
        selected = int(raw) - 1
    except ValueError:
        return None
    return entries[selected] if 0 <= selected < len(entries) else None


def choose(entries: list[Entry]) -> Entry | None:
    if shutil.which("fzf"):
        return choose_with_fzf(entries)
    return choose_numbered(entries)


def focus_or_create(entry: Entry) -> None:
    if entry.kind == "workspace":
        run_checked([herdr_bin(), "workspace", "focus", entry.value])
        return

    if entry.kind == "zoxide":
        path = Path(entry.value).expanduser()
        if not path.is_dir():
            raise SystemExit(f"not a directory: {path}")
        run_checked(
            [
                herdr_bin(),
                "workspace",
                "create",
                "--cwd",
                str(path),
                "--label",
                path.name or str(path),
                "--focus",
            ]
        )
        return

    raise SystemExit(f"unknown entry type: {entry.kind}")


def launch() -> None:
    plugin_id = os.environ.get("HERDR_PLUGIN_ID") or PLUGIN_ID
    run_checked(
        [
            herdr_bin(),
            "plugin",
            "pane",
            "open",
            "--plugin",
            plugin_id,
            "--entrypoint",
            PICKER_ENTRYPOINT,
            "--placement",
            "overlay",
        ]
    )


def picker() -> None:
    entries = all_entries()
    if not entries:
        raise SystemExit("no herdr workspaces or sesh zoxide entries found")
    selected = choose(entries)
    if selected is None:
        return
    focus_or_create(selected)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="herdr workspace picker backed by sesh zoxide"
    )
    parser.add_argument("command", choices=["launch", "picker", "version"])
    args = parser.parse_args(argv)

    if args.command == "version":
        print("herdr-sesh-workspaces 0.1.0")
    elif args.command == "launch":
        launch()
    elif args.command == "picker":
        picker()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
