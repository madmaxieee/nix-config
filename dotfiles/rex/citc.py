from __future__ import annotations

import contextlib
import hashlib
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path

CACHE_PATH = Path.home() / ".cache" / "jj_citc_workspaces"
IGNORED_DIR_PREFIXES = (".", "fig-export-", "jj-export-")


@dataclass(frozen=True)
class CitcWorkspace:
    name: str
    path: str


def get_citc_username() -> str | None:
    return os.environ.get("LOGNAME") or os.environ.get("USER")


def to_citc_display_path(path: str) -> str | None:
    username = get_citc_username()
    if not username:
        return None

    citc_prefix = f"/google/src/cloud/{username}/"
    if not path.startswith(citc_prefix):
        return None

    client_name, _, rest = path.removeprefix(citc_prefix).partition("/")
    if rest == "google3":
        return f"{client_name}@//"
    if rest.startswith("google3/"):
        return f"{client_name}@//{rest.removeprefix('google3/')}"
    if rest:
        return f"{client_name}@//depot/{rest}"
    return f"{client_name}@//depot"


def _citc_dir_fingerprint(citc_dir: str) -> str | None:
    """Hash visible entries in /google/src/cloud/<user> to detect workspace changes."""
    try:
        entries = sorted(
            name
            for name in os.listdir(citc_dir)
            if not name.startswith(IGNORED_DIR_PREFIXES)
        )
    except OSError:
        return None

    listing = "".join(f"{name}\n" for name in entries)
    return hashlib.sha1(listing.encode("utf-8")).hexdigest()


def _read_cached_clients(fingerprint: str) -> list[str] | None:
    """Return cached client list if line 0 matches the current directory fingerprint."""
    if not CACHE_PATH.is_file():
        return None
    try:
        lines = CACHE_PATH.read_text().splitlines()
    except OSError:
        return None
    if lines and lines[0] == fingerprint:
        return lines[1:]
    return None


def _write_cached_clients(fingerprint: str, clients: list[str]) -> None:
    with contextlib.suppress(OSError):
        CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
        CACHE_PATH.write_text("\n".join([fingerprint, *clients]) + "\n")


def _fetch_citc_client_names(citc_dir: str) -> list[str]:
    fingerprint = _citc_dir_fingerprint(citc_dir)
    if fingerprint is None:
        return []

    cached = _read_cached_clients(fingerprint)
    if cached is not None:
        return cached

    try:
        proc = subprocess.run(
            ["jj", "piper", "citc", "list"],
            text=True,
            capture_output=True,
            check=False,
        )
    except FileNotFoundError:
        return []

    if proc.returncode != 0:
        return []

    clients = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    _write_cached_clients(fingerprint, clients)
    return clients


def _should_skip_workspace(name: str) -> bool:
    return not name or name.startswith("subagent-")


def list_citc_workspaces() -> list[CitcWorkspace]:
    username = get_citc_username()
    if not username:
        return []
    citc_dir = f"/google/src/cloud/{username}"
    if not os.path.isdir(citc_dir):
        return []

    workspaces: list[CitcWorkspace] = []
    seen_paths: set[str] = set()
    for raw_name in _fetch_citc_client_names(citc_dir):
        name = raw_name.strip()
        if _should_skip_workspace(name):
            continue
        path = f"{citc_dir}/{name}"
        if path in seen_paths:
            continue
        seen_paths.add(path)
        workspaces.append(CitcWorkspace(name=name, path=path))
    return workspaces
