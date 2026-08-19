from __future__ import annotations

import os
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, TypeVar

import tomllib

T = TypeVar("T")

DEFAULT_SESSION_ICON = ""


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
        """Return a user-friendly ~ shortened path."""
        home = str(Path.home())
        p = str(self.expanded_path)
        if p == home:
            return "~"
        if p.startswith(home + "/"):
            return "~" + p[len(home) :]
        return p

    def effective_icon(self, fallback: str = DEFAULT_SESSION_ICON) -> str:
        """Return the custom icon if defined, otherwise fallback."""
        return self.icon if self.icon else fallback

    def get_startup_commands(self) -> list[str]:
        """Normalize startup command(s) into a list of executable shell command strings.

        Supports:
        - None / disabled -> []
        - string -> multiline split or single command
        - list[str] -> argv-style argument list (joined with shlex.join) or
                       list of distinct command lines.
        """
        if self.disable_startup_command or not self.startup_command:
            return []

        if isinstance(self.startup_command, str):
            cmd = self.startup_command.strip()
            if not cmd:
                return []
            return [line.strip() for line in cmd.splitlines() if line.strip()]

        if isinstance(self.startup_command, (list, tuple)):
            items = [str(x).strip() for x in self.startup_command if str(x).strip()]
            if not items:
                return []

            # Check if this list is an argv token list (e.g. ["cloudtop", "--exec", "foo"])
            # vs a list of separate multi-word command strings (e.g. ["echo 1", "nvim"])
            is_argv = len(items) > 1 and (
                any(x.startswith("-") for x in items[1:])
                or all(" " not in x and "\n" not in x for x in items)
            )
            if is_argv:
                return [shlex.join(items)]
            return items

        return []


def find_sesh_config_path() -> Path | None:
    """Locate the sesh configuration file."""
    # 1. Environment variables
    for env_var in ("HERDR_SESH_CONFIG", "SESH_CONFIG_FILE", "SESH_CONFIG_PATH"):
        if val := os.environ.get(env_var):
            p = Path(val).expanduser()
            if p.is_file():
                return p

    # 2. XDG config home or ~/.config/herdr/herdr-sesh.toml
    xdg_config = os.environ.get("XDG_CONFIG_HOME")
    if xdg_config:
        p = Path(xdg_config).expanduser() / "herdr" / "herdr-sesh.toml"
        if p.is_file():
            return p

    p = Path.home() / ".config" / "herdr" / "herdr-sesh.toml"
    if p.is_file():
        return p

    # 3. Direct path in dotfiles repo (relative to plugin dir)
    herdr_dir = Path(__file__).resolve().parent.parent.parent
    user = os.environ.get("USER", "")
    for candidate in (
        "herdr-sesh.toml",
        f"herdr-sesh-{user}-mac.toml",
        f"herdr-sesh-{user}-mbp.toml",
        "herdr-sesh-maxcchuang-mac.toml",
        "herdr-sesh-madmax-mbp.toml",
    ):
        p = herdr_dir / candidate
        if p.is_file():
            return p

    # 4. Fallback to ~/.config/sesh/sesh.toml or ~/.sesh.toml
    if xdg_config:
        p = Path(xdg_config).expanduser() / "sesh" / "sesh.toml"
        if p.is_file():
            return p

    p = Path.home() / ".config" / "sesh" / "sesh.toml"
    if p.is_file():
        return p

    p = Path.home() / ".sesh.toml"
    if p.is_file():
        return p

    return None


def parse_session_dict(raw: dict[str, Any]) -> SessionConfig | None:
    """Parse a single [[session]] dictionary from TOML into a SessionConfig instance."""
    if not isinstance(raw, dict):
        return None

    raw_name = raw.get("name")
    raw_path = raw.get("path") or "~"

    # Derive name from path if not explicitly provided
    if raw_name is not None and str(raw_name).strip():
        name = str(raw_name).strip()
    else:
        expanded = Path(os.path.expanduser(str(raw_path)))
        name = expanded.name or str(raw_path)

    # startup_command can be specified as 'startup_command' or 'startup',
    # and can be a string or a list of strings
    startup_raw = raw.get("startup_command")
    if startup_raw is None:
        startup_raw = raw.get("startup")

    startup_command: str | list[str] | None = None
    if isinstance(startup_raw, str):
        startup_command = startup_raw
    elif isinstance(startup_raw, (list, tuple)):
        startup_command = [str(x) for x in startup_raw]

    disable_startup = bool(raw.get("disable_startup_command", False))

    icon = str(raw["icon"]).strip() if raw.get("icon") is not None else None
    alias = str(raw["alias"]).strip() if raw.get("alias") is not None else None
    alias_auto_connect = bool(raw.get("alias_auto_connect", False))
    preview_cmd = (
        str(raw["preview_command"]).strip()
        if raw.get("preview_command") is not None
        else None
    )

    return SessionConfig(
        name=name,
        path=str(raw_path),
        startup_command=startup_command,
        disable_startup_command=disable_startup,
        icon=icon,
        alias=alias,
        alias_auto_connect=alias_auto_connect,
        preview_command=preview_cmd,
    )


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
        content = target_path.read_text(encoding="utf-8")
        data = tomllib.loads(content)
    except Exception:
        return []

    sessions: list[SessionConfig] = []

    # Handle imports if any
    raw_imports = data.get("import")
    if isinstance(raw_imports, list):
        for imp in raw_imports:
            if isinstance(imp, str) and imp.strip():
                imp_path = Path(imp.strip()).expanduser()
                if not imp_path.is_absolute():
                    imp_path = (target_path.parent / imp_path).resolve()
                imported = load_sesh_sessions(imp_path, _visited=visited)
                sessions.extend(imported)

    # Parse [[session]] entries
    raw_sessions = data.get("session")
    if isinstance(raw_sessions, list):
        for item in raw_sessions:
            if isinstance(item, dict):
                sess = parse_session_dict(item)
                if sess is not None:
                    sessions.append(sess)

    # Deduplicate sessions by name (keep first occurrence)
    unique_sessions: list[SessionConfig] = []
    seen_names: set[str] = set()
    for s in sessions:
        if s.name not in seen_names:
            seen_names.add(s.name)
            unique_sessions.append(s)

    return unique_sessions


def session_entries(
    entry_cls: Callable[..., T],
    sessions: list[SessionConfig] | None = None,
    config_path: str | Path | None = None,
) -> list[T]:
    """Generate picker Entry objects for sesh sessions."""
    sess_list = (
        sessions
        if sessions is not None
        else load_sesh_sessions(config_path=config_path)
    )

    entries: list[T] = []
    for s in sess_list:
        icon = s.effective_icon(DEFAULT_SESSION_ICON)
        title = s.name
        if s.alias:
            subtitle = f"{s.display_path}  [{s.alias}]"
        else:
            subtitle = s.display_path

        entries.append(
            entry_cls(
                kind="session",
                icon=icon,
                title=title,
                subtitle=subtitle,
                value=s.name,
            )
        )
    return entries
