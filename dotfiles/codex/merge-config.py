"""Merge repo-managed settings while preserving Codex's writable app state."""

import os
from pathlib import Path
import shutil
import sys
import tempfile
from collections.abc import Mapping

import tomlkit


def merge(target, settings):
    for key, value in settings.items():
        if isinstance(value, Mapping):
            if key not in target or not isinstance(target[key], Mapping):
                target[key] = tomlkit.table()
            merge(target[key], value)
        else:
            target[key] = value


def main():
    target, source = (Path(arg) for arg in sys.argv[1:3])
    target = target.resolve()
    settings = tomlkit.parse(source.read_text())
    settings.setdefault("mcp_servers", {}).setdefault("fff", {})["command"] = sys.argv[
        3
    ]

    original = target.read_text() if target.exists() else ""
    config = tomlkit.parse(original)
    merge(config, settings)
    updated = tomlkit.dumps(config)
    if updated == original:
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    backup = target.with_name(target.name + ".before-nix")
    if target.exists() and not backup.exists():
        shutil.copy2(target, backup)
        backup.chmod(0o600)

    # Parse both inputs before writing, then atomically replace the live file.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=target.parent, delete=False
        ) as f:
            temporary = Path(f.name)
            f.write(updated)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
