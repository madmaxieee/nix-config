from __future__ import annotations

import os
import shlex
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

DEFAULT_SESSION_ICON = ""


def shorten_home(path: str | Path) -> str:
    """Return a user-friendly ~ shortened path."""
    home = str(Path.home())
    text = str(path)
    if text == home:
        return "~"
    if text.startswith(home + "/"):
        return "~" + text.removeprefix(home)
    return text


@dataclass(frozen=True)
class SessionConfig:
    name: str
    path: str = "~"
    startup_command: str | list[str] | None = None
    disable_startup_command: bool = False
    icon: str | None = None
    alias: str | None = None
    alias_auto_connect: bool = False
    preview_command: str | None = None

    @property
    def expanded_path(self) -> Path:
        """Resolve path with tilde expansion and environment variable expansion."""
        raw_path = self.path or "~"
        expanded = os.path.expanduser(os.path.expandvars(raw_path))
        return Path(expanded).resolve()

    @property
    def display_path(self) -> str:
        return shorten_home(self.expanded_path)

    @property
    def display_icon(self) -> str:
        return self.icon or DEFAULT_SESSION_ICON

    def get_startup_commands(self) -> list[str]:
        """Normalize startup command(s) into executable shell command strings.

        Supports:
        - None / disabled -> []
        - string -> multiline split or single command
        - list[str] -> argv-style argument list (joined with shlex.join) or
                       list of distinct command lines.
        """
        if self.disable_startup_command or not self.startup_command:
            return []

        if isinstance(self.startup_command, str):
            return [
                line.strip()
                for line in self.startup_command.splitlines()
                if line.strip()
            ]

        if isinstance(self.startup_command, (list, tuple)):
            items = [str(x).strip() for x in self.startup_command if str(x).strip()]
            if not items:
                return []

            # Distinguish an argv token list (e.g. ["cloudtop", "--exec", "foo"])
            # from separate multi-word command lines (e.g. ["echo 1", "nvim"]).
            is_argv = len(items) > 1 and (
                any(x.startswith("-") for x in items[1:])
                or all(" " not in x and "\n" not in x for x in items)
            )
            return [shlex.join(items)] if is_argv else items

        return []


def find_sesh_config_path() -> Path | None:
    """Locate the sesh configuration file."""
    candidates: list[Path] = []
    if env_config := os.environ.get("REX_SESH_CONFIG"):
        candidates.append(Path(env_config).expanduser())
    if xdg_config := os.environ.get("XDG_CONFIG_HOME"):
        candidates.append(Path(xdg_config).expanduser() / "rex" / "sesh.toml")
    candidates.append(Path.home() / ".config" / "rex" / "sesh.toml")

    return next((path for path in candidates if path.is_file()), None)


def _optional_str(raw: dict[str, Any], key: str) -> str | None:
    value = raw.get(key)
    return str(value).strip() if value is not None else None


def parse_session_dict(raw: dict[str, Any]) -> SessionConfig | None:
    """Parse a single [[session]] dictionary from TOML into a SessionConfig."""
    if not isinstance(raw, dict):
        return None

    raw_path = raw.get("path") or "~"
    if raw_name := _optional_str(raw, "name"):
        name = raw_name
    else:
        expanded = Path(os.path.expanduser(str(raw_path)))
        name = expanded.name or str(raw_path)

    startup_raw = raw.get("startup_command")
    if startup_raw is None:
        startup_raw = raw.get("startup")

    startup_command: str | list[str] | None = None
    if isinstance(startup_raw, str):
        startup_command = startup_raw
    elif isinstance(startup_raw, (list, tuple)):
        startup_command = [str(x) for x in startup_raw]

    return SessionConfig(
        name=name,
        path=str(raw_path),
        startup_command=startup_command,
        disable_startup_command=bool(raw.get("disable_startup_command", False)),
        icon=_optional_str(raw, "icon"),
        alias=_optional_str(raw, "alias"),
        alias_auto_connect=bool(raw.get("alias_auto_connect", False)),
        preview_command=_optional_str(raw, "preview_command"),
    )


def _load_imported_sessions(
    data: dict[str, Any],
    base_dir: Path,
    visited: set[Path],
) -> list[SessionConfig]:
    raw_imports = data.get("import")
    if not isinstance(raw_imports, list):
        return []

    imported: list[SessionConfig] = []
    for entry in raw_imports:
        if not isinstance(entry, str) or not entry.strip():
            continue
        imp_path = Path(entry.strip()).expanduser()
        if not imp_path.is_absolute():
            imp_path = (base_dir / imp_path).resolve()
        imported.extend(load_sesh_sessions(imp_path, _visited=visited))
    return imported


def _deduplicate_by_name(sessions: list[SessionConfig]) -> list[SessionConfig]:
    """Keep the first session config seen for each session name."""
    unique: list[SessionConfig] = []
    seen_names: set[str] = set()
    for session in sessions:
        if session.name not in seen_names:
            seen_names.add(session.name)
            unique.append(session)
    return unique


def load_sesh_sessions(
    config_path: str | Path | None = None,
    _visited: set[Path] | None = None,
) -> list[SessionConfig]:
    """Parse [[session]] configurations from sesh TOML configuration file(s)."""
    target_path = (
        Path(config_path).expanduser() if config_path else find_sesh_config_path()
    )
    if target_path is None or not target_path.is_file():
        return []

    target_path = target_path.resolve()
    visited = _visited if _visited is not None else set()
    if target_path in visited:
        return []
    visited.add(target_path)

    try:
        data = tomllib.loads(target_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, tomllib.TOMLDecodeError):
        return []

    sessions = _load_imported_sessions(data, target_path.parent, visited)

    raw_sessions = data.get("session")
    if isinstance(raw_sessions, list):
        for item in raw_sessions:
            if isinstance(item, dict) and (parsed := parse_session_dict(item)):
                sessions.append(parsed)

    return _deduplicate_by_name(sessions)


def find_sesh_session(
    name: str,
    config_path: str | Path | None = None,
) -> SessionConfig | None:
    """Return the first configured sesh session matching `name`, if any."""
    return next(
        (s for s in load_sesh_sessions(config_path=config_path) if s.name == name),
        None,
    )
