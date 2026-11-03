#!/usr/bin/env python3
"""Pick a Rex session or a saved sesh/zoxide/CITC directory with fzf."""

from __future__ import annotations

import json
import os
import pwd
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(
    0,
    str(Path(__file__).resolve().parents[1] / "herdr/plugins/herdr-sesh-workspaces"),
)
import citc  # noqa: E402
import session_config  # noqa: E402

TITLE_PAD_WIDTH = 40


def setup_path() -> None:
    # Rex supplies REX_BIN_DIR, but the login shell used for this pane can
    # replace PATH before Python starts. Match the Nix/Homebrew bins used by
    # the Hammerspoon config, keeping Rex's own CLI first.
    user = pwd.getpwuid(os.getuid()).pw_name
    prefixes = [
        os.environ.get("REX_BIN_DIR"),
        f"/etc/profiles/per-user/{user}/bin",
        "/run/current-system/sw/bin",
        "/opt/homebrew/bin",
    ]
    os.environ["PATH"] = ":".join(
        part for part in [*prefixes, os.environ.get("PATH")] if part
    )


@dataclass(frozen=True)
class Entry:
    kind: str
    title: str
    value: str
    subtitle: str | None = None
    icon: str = ""

    def display_fields(self) -> tuple[str, str]:
        colors = {
            "workspace": "\033[36m",
            "session": "\033[34m",
            "citc": "\033[37m",
            "zoxide": "\033[33m",
        }
        reset = "\033[0m"
        color = colors.get(self.kind, "\033[33m")
        icon_part = f"{color}{self.icon:<3}{reset}" if self.icon else ""
        padded_title = self.title.ljust(TITLE_PAD_WIDTH)
        title_part = f"{icon_part} {padded_title}" if icon_part else padded_title
        subtitle_part = f"\033[90m{self.subtitle}{reset}" if self.subtitle else ""
        return title_part, subtitle_part


def output(argv: list[str]) -> str:
    return subprocess.run(argv, text=True, capture_output=True, check=True).stdout


def sessions() -> list[Entry]:
    data = json.loads(output(["rex", "ls", "--json"]))
    return [
        Entry(
            "workspace",
            s["label"],
            s["session_id"],
            icon=f"󰍹 {'*' if s['session_id'] == os.getenv('REX_SESSION') else ' '}",
        )
        for s in data.get("sessions", [])
        if s.get("session_id") and s.get("label")
    ]


def paths() -> list[Entry]:
    entries = session_config.session_entries(Entry)
    entries.extend(citc.citc_entries(Entry))
    try:
        zoxide = output(["zoxide", "query", "--list"])
    except (FileNotFoundError, subprocess.CalledProcessError):
        zoxide = ""
    seen = set()
    for raw in zoxide.splitlines():
        path = raw.strip()
        if path and path not in seen:
            seen.add(path)
            home = str(Path.home())
            display = "~" + path[len(home) :] if path.startswith(home + "/") else path
            display = citc.to_citc_display_path(path) or display
            entries.append(Entry("zoxide", display, path, path, ""))
    return entries


def choose(entries: list[Entry]) -> Entry | None:
    lines = []
    for i, entry in enumerate(entries):
        title_part, subtitle_part = entry.display_fields()
        lines.append(f"{i}\t{title_part}\t{subtitle_part}")
    preview_command = (
        f"{shlex.quote(sys.executable)} "
        f"{shlex.quote(str(Path(__file__).resolve()))} preview {{1}}"
    )
    selected = subprocess.run(
        [
            "fzf",
            "--no-sort",
            "--ansi",
            "--reverse",
            "--delimiter=\t",
            "--accept-nth=1",
            "--with-nth=2..",
            "--nth=1",
            f"--preview={preview_command}",
            "--preview-window=right:50%:hidden",
            "--bind=?,ctrl-/:toggle-preview",
        ],
        input="\n".join(lines),
        text=True,
        capture_output=True,
        check=False,
    )
    if selected.returncode != 0 or not selected.stdout.strip():
        return None
    index = int(selected.stdout.strip())
    return entries[index] if 0 <= index < len(entries) else None


def preview(index: int) -> None:
    entries = sessions() + paths()
    if not 0 <= index < len(entries):
        return
    entry = entries[index]
    if entry.kind == "workspace":
        print(output(["rex", "block", "ls", "--session", entry.value]))
        return
    if entry.kind == "session":
        saved = next(
            (s for s in session_config.load_sesh_sessions() if s.name == entry.value),
            None,
        )
        if saved and saved.preview_command:
            subprocess.run(
                saved.preview_command,
                shell=True,
                cwd=str(saved.expanded_path) if saved.expanded_path.is_dir() else None,
                check=False,
            )
            return
    directory = Path(entry.value).expanduser()
    if directory.is_dir():
        if shutil.which("eza"):
            subprocess.run(
                ["eza", "--color=always", "-la", "--icons=always", str(directory)],
                check=False,
            )
        else:
            subprocess.run(["ls", "-la", str(directory)], check=False)
    else:
        print(f"{entry.title}: {entry.value}")


def select_session(session_id: str, client_id: str | None) -> None:
    command = ["rex"]
    if client_id:
        command.extend(["-C", client_id])
    command.extend(["do", "session.select", f"session_id={session_id}"])
    subprocess.run(command, check=True)


def create_session(entry: Entry) -> str:
    if entry.kind == "session":
        saved = next(
            (s for s in session_config.load_sesh_sessions() if s.name == entry.value),
            None,
        )
        directory = saved.expanded_path if saved else Path(entry.value).expanduser()
    else:
        saved = None
        directory = Path(entry.value).expanduser()
    if not directory.is_dir():
        raise ValueError(f"directory does not exist: {directory}")
    label = (
        entry.title if entry.kind == "session" else (directory.name or str(directory))
    )
    command = ["rex", "new", "--json", "--cwd", str(directory), label]
    if entry.kind == "session":
        startup = saved.get_startup_commands() if saved else []
        if startup:
            command.extend(["--", "/bin/sh", "-lc", "\n".join(startup)])
    result = json.loads(output(command))
    return result["session_id"]


def main() -> int:
    setup_path()
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        try:
            preview(int(sys.argv[2]))
        except (OSError, subprocess.CalledProcessError, KeyError, ValueError) as exc:
            print(f"Preview: {exc}", file=sys.stderr)
        return 0
    client_id = sys.argv[1] if len(sys.argv) > 1 else None
    active = sessions()
    entry = choose(active + paths())
    if entry is None:
        return 0
    if entry.kind == "workspace":
        session_id = entry.value
    else:
        existing = next((s for s in active if s.title == entry.title), None)
        session_id = (
            existing.value
            if existing and entry.kind == "session"
            else create_session(entry)
        )
    select_session(session_id, client_id)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, KeyError, ValueError) as exc:
        print(f"Sesh picker: {exc}", file=sys.stderr)
        input("Press Enter to close...")
        raise SystemExit(1)
