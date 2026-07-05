from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
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


def list_citc_workspaces() -> list[CitcWorkspace]:
    logname = get_citc_username()
    if not logname:
        return []
    citc_dir = f"/google/src/cloud/{logname}"
    if not os.path.isdir(citc_dir):
        return []

    try:
        proc = subprocess.run(
            ["jj", "citc_list"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError:
        return []
    if proc.returncode != 0 or not proc.stdout.strip():
        return []

    workspaces: list[CitcWorkspace] = []
    seen_paths: set[str] = set()

    for line in proc.stdout.splitlines():
        workspace_name = line.strip()
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
