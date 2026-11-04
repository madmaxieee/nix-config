"""Merge repo-managed settings while preserving Claude Code's writable state."""

import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


def merge(target, settings):
    for key, value in settings.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            merge(target[key], value)
        else:
            target[key] = value


def main():
    target, source = (Path(arg) for arg in sys.argv[1:3])
    target = target.resolve()
    settings = json.loads(source.read_text())

    original = json.loads((target.read_text() if target.exists() else "") or "{}")
    config = json.loads(json.dumps(original))
    merge(config, settings)
    # Claude Code rewrites these files often, so leave them alone when up to date.
    if config == original:
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
            json.dump(config, f, indent=2)
            f.write("\n")
        if target.exists():
            shutil.copymode(target, temporary)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
