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


@dataclass(frozen=True)
class Entry:
    kind: str
    title: str
    value: str
    subtitle: str | None = None
    icon: str = ""
    label: str | None = None

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


def inspect_session(session_id: str) -> dict:
    try:
        return json.loads(output(["rex", "session", "inspect", "--json", session_id]))
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return {}


def session_stats(session_id: str) -> str:
    # herdr shows "N tabs, M panes, <agent status>"; Rex has windows and
    # blocks but no agent status. Floating layers (like this picker) are
    # excluded so the counts match what the session shows when tiled.
    windows = inspect_session(session_id).get("windows") or []
    blocks = sum(
        len(layer.get("blocks") or [])
        for window in windows
        for layer in window.get("layers") or []
        if layer.get("kind") == "tiled"
    )
    return f"{len(windows)} tabs, {blocks} panes"


def sessions(stats: bool = True) -> list[Entry]:
    data = json.loads(output(["rex", "ls", "--json"]))
    # Number sessions like herdr's workspace picker; the numbers match the
    # ctrl+N session_goto binds in init.lua.
    return [
        Entry(
            "workspace",
            f"{number}: {s['label']}",
            s["session_id"],
            session_stats(s["session_id"]) if stats else None,
            icon=f"󰍹 {'*' if s['session_id'] == os.getenv('REX_SESSION') else ' '}",
            label=s["label"],
        )
        for number, s in enumerate(data.get("sessions", []), 1)
        if s.get("session_id") and s.get("label")
    ]


def ensure_main_session(active: list[Entry]) -> list[Entry]:
    # Like herdr's ensure_main_workspace: keep a "main" session rooted at ~.
    if any(s.label == "main" for s in active):
        return active
    try:
        output(["rex", "new", "--json", "--cwd", str(Path.home()), "main"])
    except (OSError, subprocess.CalledProcessError):
        return active
    return sessions()


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
            if path == home:
                display = "~"
            elif path.startswith(home + "/"):
                display = "~" + path[len(home) :]
            else:
                display = path
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


def preview_session(session_id: str, title: str, lines: int = 30) -> None:
    # Like herdr's `pane read --lines 30`: show the tail of the focused block
    # in the session's active window.
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
            screen = output(["rex", "capture", "--block", block_id])
        except subprocess.CalledProcessError:
            screen = ""
        tail = screen.rstrip().splitlines()[-lines:]
        if tail:
            print("\n".join(tail))
            return
    print(f"Session: {title}\nID: {session_id}")


def preview(index: int) -> None:
    entries = sessions(stats=False) + paths()
    if not 0 <= index < len(entries):
        return
    entry = entries[index]
    if entry.kind == "workspace":
        preview_session(entry.value, entry.title)
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


def resolve_client(client_id: str | None) -> str | None:
    # Clients connect to each host separately, so the ID the keymap's server
    # passed in (e.g. the Mac's) may not exist on this host. Fall back to the
    # app attached to this session, most recently connected first.
    try:
        clients = json.loads(output(["rex", "client", "ls", "--json"])).get(
            "clients"
        ) or []
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
    chosen = (attached or apps or [None])[0]
    return chosen.get("client_id") if chosen else None


def select_session(session_id: str, client_id: str | None) -> None:
    command = ["rex"]
    client_id = resolve_client(client_id)
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
    active = ensure_main_session(sessions())
    entry = choose(active + paths())
    if entry is None:
        return 0
    if entry.kind == "workspace":
        session_id = entry.value
    else:
        existing = next((s for s in active if s.label == entry.title), None)
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
