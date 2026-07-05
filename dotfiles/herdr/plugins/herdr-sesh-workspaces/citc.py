from __future__ import annotations

import hashlib
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, TypeVar

T = TypeVar("T")


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

    rel_path = path[len(citc_prefix) :]
    parts = rel_path.split("/", 1)
    client_name = parts[0]
    rest = parts[1] if len(parts) > 1 else ""
    if rest.startswith("google3/"):
        sub_path = rest[len("google3/") :]
        return f"{client_name}@//{sub_path}"
    elif rest == "google3":
        return f"{client_name}@//"
    else:
        if rest:
            return f"{client_name}@//depot/{rest}"
        else:
            return f"{client_name}@//depot"


def _fetch_citc_client_names(citc_dir: str) -> list[str]:
    try:
        entries = sorted(
            [
                name
                for name in os.listdir(citc_dir)
                if not name.startswith((".", "fig-export-", "jj-export-"))
            ]
        )
    except OSError:
        return []

    content = "".join(f"{name}\n" for name in entries)
    workspaces_sha1 = hashlib.sha1(content.encode("utf-8")).hexdigest()

    cache_file = Path.home() / ".cache" / "jj_citc_workspaces"
    cache_lines: list[str] = []
    if cache_file.is_file():
        try:
            cache_lines = cache_file.read_text().splitlines()
        except OSError:
            cache_lines = []

    if cache_lines and cache_lines[0] == workspaces_sha1:
        return cache_lines[1:]

    try:
        proc = subprocess.run(
            ["jj", "piper", "citc", "list"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError:
        return []

    if proc.returncode != 0:
        return []

    clients = [line.strip() for line in proc.stdout.splitlines() if line.strip()]

    try:
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        cache_content = "\n".join([workspaces_sha1] + clients) + "\n"
        cache_file.write_text(cache_content)
    except OSError:
        pass

    return clients


def list_citc_workspaces() -> list[CitcWorkspace]:
    logname = get_citc_username()
    if not logname:
        return []
    citc_dir = f"/google/src/cloud/{logname}"
    if not os.path.isdir(citc_dir):
        return []

    client_names = _fetch_citc_client_names(citc_dir)

    workspaces: list[CitcWorkspace] = []
    seen_paths: set[str] = set()

    for workspace_name in client_names:
        workspace_name = workspace_name.strip()
        if not workspace_name:
            continue
        path = f"{citc_dir}/{workspace_name}"
        if path in seen_paths:
            continue
        seen_paths.add(path)

        workspaces.append(CitcWorkspace(name=workspace_name, path=path))
    return workspaces


def citc_entries(entry_cls: Callable[..., T]) -> list[T]:
    return [
        entry_cls(
            kind="citc",
            icon="",
            title=ws.name,
            value=ws.path,
        )
        for ws in list_citc_workspaces()
    ]
