#!/usr/bin/env python3
"""Pick a Rex session or a saved sesh/zoxide/CITC directory with fzf.

Invocation modes:
  sesh-picker.py [CLIENT_ID]      Run the interactive fzf session picker.
  sesh-picker.py preview <INDEX>  Render the fzf preview pane for entry INDEX.
"""

from __future__ import annotations

import json
import os
import pwd
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path

import citc
import session_config

TITLE_PAD_WIDTH = 40
ICON_PAD_WIDTH = 3

ICON_ACTIVE_SESSION = "󰍹"
ICON_CITC = ""
ICON_ZOXIDE = ""

ANSI_RESET = "\033[0m"
ANSI_DIM = "\033[90m"  # gray
DEFAULT_KIND_COLOR = "\033[33m"  # yellow


class EntryKind(StrEnum):
    ACTIVE_SESSION = "active_session"
    SAVED_SESSION = "saved_session"
    CITC = "citc"
    ZOXIDE = "zoxide"


KIND_COLORS: dict[EntryKind, str] = {
    EntryKind.ACTIVE_SESSION: "\033[36m",  # cyan
    EntryKind.SAVED_SESSION: "\033[34m",  # blue
    EntryKind.CITC: "\033[37m",  # white
    EntryKind.ZOXIDE: DEFAULT_KIND_COLOR,
}


@dataclass(frozen=True)
class Entry:
    kind: EntryKind
    title: str
    value: str
    subtitle: str | None = None
    icon: str = ""
    label: str | None = None

    def display_fields(self) -> tuple[str, str]:
        title = self.title.ljust(TITLE_PAD_WIDTH)
        if self.icon:
            color = KIND_COLORS.get(self.kind, DEFAULT_KIND_COLOR)
            icon = f"{color}{self.icon.ljust(ICON_PAD_WIDTH)}{ANSI_RESET}"
            title = f"{icon} {title}"

        subtitle = f"{ANSI_DIM}{self.subtitle}{ANSI_RESET}" if self.subtitle else ""
        return title, subtitle


def current_user() -> str:
    # Nix's Python has no NSS modules, so pwd lookups fail for LDAP users
    # (e.g. on a cloudtop). Prefer the environment.
    user = os.environ.get("USER") or os.environ.get("LOGNAME")
    if user:
        return user
    try:
        return pwd.getpwuid(os.getuid()).pw_name
    except KeyError:
        return ""


def setup_path() -> None:
    # Rex supplies REX_BIN_DIR, but the login shell used for this pane can
    # replace PATH before Python starts. Match the Nix/Homebrew bins used by
    # the Hammerspoon config (macOS) and standalone home-manager (Linux),
    # keeping Rex's own CLI first.
    prefixes = [
        os.environ.get("REX_BIN_DIR"),
        f"/etc/profiles/per-user/{current_user()}/bin",
        "/run/current-system/sw/bin",
        "/opt/homebrew/bin",
        str(Path.home() / ".nix-profile/bin"),
        "/nix/var/nix/profiles/default/bin",
    ]
    os.environ["PATH"] = ":".join(
        part for part in [*prefixes, os.environ.get("PATH")] if part
    )


def run_command(argv: list[str]) -> str:
    return subprocess.run(argv, text=True, capture_output=True, check=True).stdout


def inspect_session(session_id: str) -> dict:
    try:
        return json.loads(
            run_command(["rex", "session", "inspect", "--json", session_id])
        )
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return {}


def session_stats(session_id: str) -> str:
    # Exclude floating layers (like this picker) so the counts match
    # what the session shows when tiled.
    windows = inspect_session(session_id).get("windows") or []
    blocks = sum(
        len(layer.get("blocks") or [])
        for window in windows
        for layer in window.get("layers") or []
        if layer.get("kind") == "tiled"
    )
    return f"{len(windows)} tabs, {blocks} panes"


def active_sessions(include_stats: bool = True) -> list[Entry]:
    data = json.loads(run_command(["rex", "ls", "--json"]))
    current_session_id = os.getenv("REX_SESSION")
    # Session numbers match the ctrl+N session_goto binds in init.lua.
    entries: list[Entry] = []
    for number, session in enumerate(data.get("sessions", []), start=1):
        session_id = session.get("session_id")
        label = session.get("label")
        if not (session_id and label):
            continue
        marker = "*" if session_id == current_session_id else " "
        entries.append(
            Entry(
                kind=EntryKind.ACTIVE_SESSION,
                title=f"{number}: {label}",
                value=session_id,
                subtitle=session_stats(session_id) if include_stats else None,
                icon=f"{ICON_ACTIVE_SESSION} {marker}",
                label=label,
            )
        )
    return entries


def ensure_main_session(active: list[Entry]) -> list[Entry]:
    # Keep a "main" session rooted at ~.
    if any(s.label == "main" for s in active):
        return active
    try:
        run_command(["rex", "new", "--json", "--cwd", str(Path.home()), "main"])
    except (OSError, subprocess.CalledProcessError):
        return active
    return active_sessions()


def saved_session_entries() -> list[Entry]:
    entries: list[Entry] = []
    for session in session_config.load_sesh_sessions():
        subtitle = (
            f"{session.display_path}  [{session.alias}]"
            if session.alias
            else session.display_path
        )
        entries.append(
            Entry(
                kind=EntryKind.SAVED_SESSION,
                title=session.name,
                value=session.name,
                subtitle=subtitle,
                icon=session.display_icon,
            )
        )
    return entries


def citc_entries() -> list[Entry]:
    return [
        Entry(
            kind=EntryKind.CITC,
            title=ws.name,
            value=ws.path,
            icon=ICON_CITC,
        )
        for ws in citc.list_citc_workspaces()
    ]


def zoxide_entries() -> list[Entry]:
    try:
        zoxide_output = run_command(["zoxide", "query", "--list"])
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []

    seen: set[str] = set()
    entries: list[Entry] = []
    for raw_line in zoxide_output.splitlines():
        path = raw_line.strip()
        if not path or path in seen:
            continue
        seen.add(path)
        display = citc.to_citc_display_path(path) or session_config.shorten_home(path)
        entries.append(
            Entry(
                kind=EntryKind.ZOXIDE,
                title=display,
                value=path,
                subtitle=path,
                icon=ICON_ZOXIDE,
            )
        )
    return entries


def candidate_entries() -> list[Entry]:
    return [*saved_session_entries(), *citc_entries(), *zoxide_entries()]


def choose(entries: list[Entry]) -> Entry | None:
    # Each fzf line is "<index>\t<title>\t<subtitle>".
    # --with-nth=2.. hides <index>, so --nth=1 fuzzy-matches <title> (display
    # column 1), while --accept-nth=1 and `preview {1}` still use raw field 1 (<index>).
    lines = []
    for index, entry in enumerate(entries):
        title, subtitle = entry.display_fields()
        lines.append(f"{index}\t{title}\t{subtitle}")
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


def preview_session(session_id: str, title: str, lines: int = 30) -> None:
    # Show the tail of the focused block in the session's active window.
    info = inspect_session(session_id)
    window = next(
        (
            w
            for w in info.get("windows") or []
            if w.get("window_id") == info.get("active_window_id")
        ),
        None,
    )
    block_id = window.get("focused_block_id") if window else None
    if block_id:
        try:
            screen = run_command(["rex", "capture", "--block", block_id])
        except subprocess.CalledProcessError:
            screen = ""
        tail = screen.rstrip().splitlines()[-lines:]
        if tail:
            print("\n".join(tail))
            return
    print(f"Session: {title}\nID: {session_id}")


def preview_directory(entry: Entry) -> None:
    directory = Path(entry.value).expanduser()
    if not directory.is_dir():
        print(f"{entry.title}: {entry.value}")
        return
    if shutil.which("eza"):
        cmd = ["eza", "--color=always", "-la", "--icons=always", str(directory)]
    else:
        cmd = ["ls", "-la", str(directory)]
    subprocess.run(cmd, check=False)


def preview(index: int) -> None:
    entries = active_sessions(include_stats=False) + candidate_entries()
    if not 0 <= index < len(entries):
        return
    entry = entries[index]
    if entry.kind == EntryKind.ACTIVE_SESSION:
        preview_session(entry.value, entry.title)
        return
    if entry.kind == EntryKind.SAVED_SESSION:
        saved = session_config.find_sesh_session(entry.value)
        if saved and saved.preview_command:
            cwd = str(saved.expanded_path) if saved.expanded_path.is_dir() else None
            subprocess.run(saved.preview_command, shell=True, cwd=cwd, check=False)
            return
    preview_directory(entry)


def resolve_client(client_id: str | None) -> str | None:
    # Clients connect to each host separately, so the ID the keymap's server
    # passed in (e.g. the Mac's) may not exist on this host. Fall back to the
    # app attached to this session, most recently connected first.
    try:
        clients = (
            json.loads(run_command(["rex", "client", "ls", "--json"])).get("clients")
            or []
        )
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return client_id
    if client_id and any(c.get("client_id") == client_id for c in clients):
        return client_id
    apps = sorted(
        (c for c in clients if (c.get("info") or {}).get("kind") == "app"),
        key=lambda c: c.get("connected_at") or "",
        reverse=True,
    )
    session = os.environ.get("REX_SESSION")
    attached = [c for c in apps if session in (c.get("session_ids") or [])]
    candidates = attached or apps
    return candidates[0].get("client_id") if candidates else None


def select_session(session_id: str, client_id: str | None) -> None:
    command = ["rex"]
    resolved_client = resolve_client(client_id)
    if resolved_client:
        command.extend(["-C", resolved_client])
    command.extend(["do", "session.select", f"session_id={session_id}"])
    subprocess.run(command, check=True)


def create_session(entry: Entry) -> str:
    if entry.kind == EntryKind.SAVED_SESSION:
        saved = session_config.find_sesh_session(entry.value)
        directory = saved.expanded_path if saved else Path(entry.value).expanduser()
        label = entry.title
        startup = saved.get_startup_commands() if saved else []
    else:
        directory = Path(entry.value).expanduser()
        label = directory.name or str(directory)
        startup = []

    if not directory.is_dir():
        raise ValueError(f"directory does not exist: {directory}")

    command = ["rex", "new", "--json", "--cwd", str(directory), label]
    if startup:
        command.extend(["--", "/bin/sh", "-lc", "\n".join(startup)])
    result = json.loads(run_command(command))
    return result["session_id"]


def resolve_session_id(entry: Entry, active: list[Entry]) -> str:
    if entry.kind == EntryKind.ACTIVE_SESSION:
        return entry.value
    if entry.kind == EntryKind.SAVED_SESSION:
        existing = next((s for s in active if s.label == entry.title), None)
        if existing:
            return existing.value
    return create_session(entry)


def main() -> int:
    setup_path()
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        try:
            preview(int(sys.argv[2]))
        except (OSError, subprocess.CalledProcessError, KeyError, ValueError) as exc:
            print(f"Preview: {exc}", file=sys.stderr)
        return 0

    client_id = sys.argv[1] if len(sys.argv) > 1 else None
    active = ensure_main_session(active_sessions())
    entry = choose(active + candidate_entries())
    if entry is None:
        return 0

    session_id = resolve_session_id(entry, active)
    select_session(session_id, client_id)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, KeyError, ValueError) as exc:
        print(f"Sesh picker: {exc}", file=sys.stderr)
        input("Press Enter to close...")
        raise SystemExit(1)
