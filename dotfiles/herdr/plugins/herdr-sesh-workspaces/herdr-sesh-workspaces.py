#!/usr/bin/env python3
"""herdr-sesh-workspaces: a tiny herdr workspace picker backed by zoxide and CITC.

What it does:

  - Shows existing herdr workspaces and focuses the selected one.
  - Shows zoxide entries directly (via `zoxide query --list`) and
    creates/focuses a new herdr workspace rooted at the selected zoxide path.
  - Shows CITC JJ workspaces and creates/focuses a new herdr workspace rooted
    at the selected CITC path.
  - Uses fzf with hidden indices and ANSI colors for a clean, aligned, and
    interactive picker experience.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import citc

PLUGIN_ID = "madmax.herdr-sesh-workspaces"
PICKER_ENTRYPOINT = "picker"

TITLE_PAD_WIDTH = 40


@dataclass(frozen=True)
class Entry:
    kind: str
    icon: str
    title: str
    value: str
    subtitle: str | None = None

    def display_fields(self) -> tuple[str, str]:
        colors = {
            "workspace": "\033[36m",  # cyan
            "citc": "\033[37m",  # white
            "zoxide": "\033[33m",  # yellow
        }
        dim = "\033[90m"
        reset = "\033[0m"

        color = colors.get(self.kind, "\033[33m")
        icon_part = f"{color}{self.icon:<3}{reset}" if self.icon else ""

        padded_title = self.title
        if len(self.title) < TITLE_PAD_WIDTH:
            padded_title = self.title + " " * (TITLE_PAD_WIDTH - len(self.title))

        if icon_part:
            title_part = f"{icon_part} {padded_title}"
        else:
            title_part = padded_title

        subtitle_part = f"{dim}{self.subtitle}{reset}" if self.subtitle else ""
        return title_part, subtitle_part

    def line(self) -> str:
        title_part, subtitle_part = self.display_fields()
        if self.subtitle:
            return f"{title_part}\t{subtitle_part}"
        return f"{title_part}"


@lru_cache()
def get_herdr_bin() -> str:
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


def to_display_path(path: str) -> str:
    home = str(Path.home())
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        return "~" + path[len(home) :]

    citc_path = citc.to_citc_display_path(path)
    if citc_path is not None:
        return citc_path

    return path


def workspace_entries() -> list[Entry]:
    data = run_json([get_herdr_bin(), "workspace", "list"])
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

        subtitle = f"{tabs} tabs, {panes} panes, {status}"

        entries.append(
            Entry(
                kind="workspace",
                icon=f"󰍹 {focused}",
                title=f"{number}: {label}",
                subtitle=subtitle,
                value=wid,
            )
        )
    return entries


def zoxide_entries() -> list[Entry]:
    try:
        proc = subprocess.run(
            ["zoxide", "query", "--list"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError:
        return []
    if proc.returncode != 0 or not proc.stdout.strip():
        return []

    entries: list[Entry] = []
    seen_paths: set[str] = set()

    for line in proc.stdout.splitlines():
        path = line.strip()
        if not path or path in seen_paths:
            continue
        seen_paths.add(path)

        entries.append(
            Entry(
                kind="zoxide",
                icon="",
                title=to_display_path(path),
                subtitle=path,
                value=path,
            )
        )
    return entries


def citc_entries() -> list[Entry]:
    return citc.citc_entries(Entry)


def all_entries() -> list[Entry]:
    return workspace_entries() + citc_entries() + zoxide_entries()


def choose_with_fzf(entries: list[Entry]) -> Entry | None:
    fzf = shutil.which("fzf")
    if not fzf:
        return None

    lines = []
    for i, entry in enumerate(entries):
        title_part, subtitle_part = entry.display_fields()
        lines.append(f"{i}\t{title_part}\t{subtitle_part}")

    proc = subprocess.run(
        [
            fzf,
            "--no-sort",
            "--ansi",
            "--reverse",
            "--delimiter=\t",
            # on accept, print the 1st field BEFORE transformation, the index
            "--accept-nth=1",
            # transform line to hide the 1st field (index)
            "--with-nth=2..",
            # limit search scope to the 1st field AFTER transformation, which is the original 2nd field (title)
            "--nth=1",
        ],
        input="\n".join(lines),
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        selected = int(proc.stdout)
    except ValueError:
        return None
    return entries[selected] if 0 <= selected < len(entries) else None


def choose_numbered(entries: list[Entry]) -> Entry | None:
    print("Sesh Workspaces\n")
    for i, entry in enumerate(entries, 1):
        print(f"{i:3d}. {entry.line()}")
    print()
    raw = input("> ").strip()
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
        run_checked([get_herdr_bin(), "workspace", "focus", entry.value])
        return

    if entry.kind in ("zoxide", "citc"):
        path = Path(entry.value).expanduser()
        if not path.is_dir():
            raise SystemExit(f"not a directory: {path}")
        label = f"{entry.icon} {path.name or str(path)}"
        run_checked(
            [
                get_herdr_bin(),
                "workspace",
                "create",
                "--cwd",
                str(path),
                "--label",
                label,
                "--focus",
            ]
        )
        return

    raise SystemExit(f"unknown entry type: {entry.kind}")


def get_current_workspace_id() -> str | None:
    data = run_json([get_herdr_bin(), "pane", "current"])
    if not isinstance(data, dict):
        return None
    result = data.get("result")
    if not isinstance(result, dict):
        return None
    pane = result.get("pane")
    if not isinstance(pane, dict):
        return None
    return pane.get("workspace_id")


def find_existing_picker_pane(current_workspace_id: str) -> str | None:
    data = run_json([get_herdr_bin(), "pane", "list"])
    if not isinstance(data, dict):
        return None
    result = data.get("result")
    if not isinstance(result, dict):
        return None
    panes = result.get("panes")
    if not isinstance(panes, list):
        return None

    plugin_dir = str(Path(__file__).parent.resolve())
    for pane in panes:
        if not isinstance(pane, dict):
            continue
        if pane.get("workspace_id") != current_workspace_id:
            continue

        is_picker = False
        if pane.get("label") == "Sesh Workspaces":
            is_picker = True
        elif pane.get("cwd") == plugin_dir or pane.get("foreground_cwd") == plugin_dir:
            is_picker = True

        if is_picker:
            return pane.get("pane_id")
    return None


def toggle() -> None:
    current_ws = get_current_workspace_id()
    if current_ws:
        existing_pane_id = find_existing_picker_pane(current_ws)
        if existing_pane_id:
            run_checked([get_herdr_bin(), "pane", "close", existing_pane_id])
            return

    plugin_id = os.environ.get("HERDR_PLUGIN_ID") or PLUGIN_ID
    run_checked(
        [
            get_herdr_bin(),
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


def ensure_main_workspace() -> None:
    try:
        data = run_json([get_herdr_bin(), "workspace", "list"])
        if not isinstance(data, dict):
            return
        result = data.get("result")
        if not isinstance(result, dict):
            return
        workspaces = result.get("workspaces")
        if not isinstance(workspaces, list):
            return

        has_main = False
        for ws in workspaces:
            if not isinstance(ws, dict):
                continue
            if ws.get("label") == "main" or ws.get("workspace_id") == "main":
                has_main = True
                break

        if not has_main:
            home = str(Path.home())
            subprocess.run(
                [
                    get_herdr_bin(),
                    "workspace",
                    "create",
                    "--cwd",
                    home,
                    "--label",
                    "main",
                    "--no-focus",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
    except Exception:
        pass


def picker() -> None:
    ensure_main_workspace()
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
    parser.add_argument("command", choices=["toggle", "picker", "version", "list"])
    args = parser.parse_args(argv)

    if args.command == "version":
        print("herdr-sesh-workspaces 0.1.0")
    elif args.command == "toggle":
        toggle()
    elif args.command == "picker":
        picker()
    elif args.command == "list":
        for entry in all_entries():
            print(entry.line())
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
