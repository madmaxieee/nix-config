{
  config,
  lib,
  pkgs,
  ...
}:

let
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
  linkDotfile = config.lib.custom.linkDotfile;

  jjGuardCmd = "${pkgs.python3}/bin/python3 \"${config.home.homeDirectory}/.gemini/config/hooks/jj_guard.py\"";
  agyJjGuardInstall = pkgs.writeShellScript "antigravity-jj-guard-install" ''
    set -eu
    config_dir="''${ANTIGRAVITY_CLI_CONFIG_DIR:-$HOME/.gemini/config}"
    [ -d "$config_dir" ] || exit 0
    hooks="$config_dir/hooks.json"
    [ -s "$hooks" ] || echo '{}' > "$hooks"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    ${pkgs.jq}/bin/jq --arg cmd "${jjGuardCmd}" '
      ."jj-guard" = {
        "SessionStart": [
          { "type": "command", "command": ($cmd + " agy session_start"), "timeout": 5 }
        ],
        "PreToolUse": [
          {
            "matcher": "run_command",
            "hooks": [
              { "type": "command", "command": ($cmd + " agy pre_tool"), "timeout": 5 }
            ]
          }
        ]
      }
    ' "$hooks" > "$tmp"
    cat "$tmp" > "$hooks"
  '';

  agySkillsMaterializePy = pkgs.writeText "antigravity-skills-materialize.py" ''
    import os
    import re
    import shutil
    from pathlib import Path


    FM_DISABLE_RE = re.compile(
        r"^\s*disable-model-invocation\s*:\s*true\s*(?:#.*)?$"
    )


    def make_writable_and_rmtree(path: Path) -> None:
        for root, dirs, files in os.walk(path, topdown=True, followlinks=False):
            root_path = Path(root)
            try:
                os.chmod(root_path, 0o755)
            except OSError:
                pass
            for name in dirs:
                d = root_path / name
                if not d.is_symlink():
                    try:
                        os.chmod(d, 0o755)
                    except OSError:
                        pass
            for name in files:
                f = root_path / name
                if not f.is_symlink():
                    try:
                        os.chmod(f, 0o644)
                    except OSError:
                        pass
        shutil.rmtree(path)


    def normalize_permissions(path: Path) -> None:
        os.chmod(path, 0o755)
        for root, dirs, files in os.walk(path, topdown=True, followlinks=False):
            root_path = Path(root)
            for name in dirs:
                os.chmod(root_path / name, 0o755)
            for name in files:
                f = root_path / name
                mode = f.stat().st_mode
                os.chmod(f, 0o755 if (mode & 0o100) else 0o644)


    def strip_disable_model_invocation(text: str) -> str:
        lines = text.splitlines(keepends=True)
        if not lines or lines[0].rstrip("\r\n") != "---":
            return text
        end_idx = None
        for idx in range(1, len(lines)):
            if lines[idx].rstrip("\r\n") == "---":
                end_idx = idx
                break
        if end_idx is None:
            return text
        fm_lines = [
            line
            for line in lines[1:end_idx]
            if not FM_DISABLE_RE.match(line.rstrip("\r\n"))
        ]
        return "".join([lines[0], *fm_lines, *lines[end_idx:]])


    def main() -> None:
        home = Path(os.environ["HOME"])
        skills_src = Path(
            os.environ.get("AGENTS_SKILLS_DIR") or str(home / ".agents" / "skills")
        )
        config_dir = Path(
            os.environ.get("ANTIGRAVITY_CLI_CONFIG_DIR")
            or str(home / ".gemini" / "config")
        )
        skills_dst = config_dir / "skills"

        if not skills_src.is_dir():
            return

        config_dir.mkdir(parents=True, exist_ok=True)

        # CRITICAL: Never traverse or delete through a symlink (e.g. old HM symlink
        # pointing at ~/.agents/skills); unlink the symlink itself first.
        if skills_dst.is_symlink():
            skills_dst.unlink()
        elif skills_dst.exists() and not skills_dst.is_dir():
            skills_dst.unlink()

        skills_dst.mkdir(exist_ok=True)

        if skills_src.resolve() == skills_dst.resolve():
            raise RuntimeError(f"Refusing to sync {skills_src} onto itself")

        src_skills = {
            entry.name: entry
            for entry in skills_src.iterdir()
            if not entry.name.startswith(".") and entry.is_dir()
        }

        for existing in list(skills_dst.iterdir()):
            if existing.name not in src_skills:
                if existing.is_symlink() or not existing.is_dir():
                    existing.unlink()
                else:
                    make_writable_and_rmtree(existing)

        for name, src_dir in sorted(src_skills.items()):
            dst_dir = skills_dst / name
            if dst_dir.is_symlink() or (dst_dir.exists() and not dst_dir.is_dir()):
                dst_dir.unlink()
            elif dst_dir.exists():
                make_writable_and_rmtree(dst_dir)

            shutil.copytree(src_dir, dst_dir, symlinks=False)
            normalize_permissions(dst_dir)

            skill_md = dst_dir / "SKILL.md"
            if skill_md.is_file():
                original = skill_md.read_text(encoding="utf-8")
                updated = strip_disable_model_invocation(original)
                if updated != original:
                    skill_md.write_text(updated, encoding="utf-8")


    if __name__ == "__main__":
        main()
  '';

  agySkillsMaterialize = pkgs.writeShellScript "antigravity-skills-materialize" ''
    set -eu
    exec ${pkgs.python3}/bin/python3 ${agySkillsMaterializePy}
  '';
in
{
  home.file = {
    ".agents/skills/t3-model-routing" = {
      force = true;
      source = linkDotfile "agents/skills/t3-model-routing";
    };

    # Antigravity (CLI and T3 Code ACP) discovers global skills via config/skills,
    # not config/AGENTS.md; expose shared global instructions as a skill.
    ".agents/skills/global-instructions/SKILL.md" = {
      force = true;
      text = ''
        ---
        name: global-instructions
        description: Jujutsu (jj) version control and workspace rules, T3 Code worktree setup and handoff, and fff MCP file search. Use when working in a .jj repository or linked Git worktree, creating or handing off to a workspace or worktree, running VCS commands, or searching files when fff MCP tools are available.
        ---

      ''
      + builtins.readFile ../../dotfiles/codex/AGENTS.md
      + ''
        - In T3 Code on Antigravity, when `t3_worktree_status` reports `attached: false` and the task needs an isolated workspace, run the work via `delegate_task` with `isolation: "worktree"` (having the child rebase onto `trunk()` when independent work is expected) or `t3_thread_launch` with `workspaceStrategy` when asked for a new thread; never call `t3_worktree_handoff` on Antigravity (detaching the live ACP session mid-turn wedges the active run) or `jj workspace add` outside `workspacePaths` (blocked by Antigravity's path sandbox).
      '';
    };

    ".gemini/config/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";

    ".gemini/config/mcp_config.json" = {
      force = true;
      text = builtins.toJSON {
        mcpServers.fff = {
          command = lib.getExe fff-mcp;
          args = [ "--no-update-check" ];
          disabled = false;
        };
      };
    };
  };

  home.activation.antigravity_jj_guard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${agyJjGuardInstall}
  '';

  home.activation.antigravity_skills = lib.hm.dag.entryAfter [ "linkGeneration" "writeBoundary" ] ''
    run ${agySkillsMaterialize}
  '';
}
