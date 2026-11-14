"""Agent SessionStart instructions and a best-effort PreToolUse Git guard.

Only inspect text and filesystem markers; never execute the pending command.
This intentionally isn't a shell interpreter or a security boundary.
"""

import json
import os
from pathlib import Path
import re
import shlex
import sys


INSTRUCTIONS = """JJ-GUARD: This repository uses Jujutsu (jj) for version control.
Use jj commands instead of direct git commands, including for status, diff and log.
Use jj git fetch/push for remotes and jj bookmark for named references.
The working copy is a change; use jj describe, jj new and jj edit as appropriate.
Do not translate Git flags mechanically: check jj help for the intended operation.
Direct Git tool calls are blocked here, except for `git submodule` in jj repositories
(allowed with a warning because Jujutsu does not natively manage Git submodules).
If another operation truly requires Git, ask the user for an explicit exception;
do not evade the guard with a wrapper.
"""

GUIDANCE = {
    "status": "Use jj status.",
    "diff": "Use jj diff.",
    "log": "Use jj log; choose a revset with -r when needed.",
    "show": "Use jj show <revision>.",
    "blame": "Use jj file annotate <file>.",
    "fetch": "Use jj git fetch.",
    "push": "Use jj git push.",
    "remote": "Use jj git remote.",
    "branch": "Use jj bookmark list/create/set/delete as appropriate.",
    "add": "jj has no Git staging area; use jj status or jj file track as appropriate.",
    "commit": "Use jj describe to describe a change and jj new to start the next one.",
    "checkout": "Use jj edit <revision> or jj new <revision> as appropriate.",
    "switch": "Use jj edit <bookmark> or jj new <bookmark> as appropriate.",
    "stash": "Your change is saved; use jj new, then jj edit to return to it.",
    "restore": "Use jj restore; check jj help restore for the desired source.",
    "reset": "Use jj restore, jj edit or jj abandon according to your intent.",
    "rebase": "Use jj rebase; check jj help rebase for the source and destination.",
    "merge": "Use jj new <parent1> <parent2> to create a merge change.",
    "pull": "Use jj git fetch, then jj rebase or jj new to integrate changes.",
    "worktree": "Use jj workspace add/list/forget/update-stale as appropriate.",
    "rev-parse": "Use jj root for the repository root, or jj log -r <rev> -T commit_id for an ID.",
}

ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z_0-9]*=")
SEPARATORS = {";", "&", "&&", "|", "||", "\n"}
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "ksh"}


def directory(value, cwd):
    """Resolve only literal paths and common HOME/PWD references."""
    value = value.replace("${PWD}", str(cwd)).replace("$PWD", str(cwd))
    value = value.replace("${HOME}", str(Path.home())).replace(
        "$HOME", str(Path.home())
    )
    path = Path(os.path.expanduser(value))
    return (path if path.is_absolute() else cwd / path).resolve()


def linked_worktree_jj_root(worktree_path):
    """If worktree_path/.git is a Git worktree linked to a jj repo, return that jj root."""
    git_marker = worktree_path / ".git"
    try:
        if not git_marker.is_file():
            return None
        raw = git_marker.read_text(encoding="utf-8", errors="replace").strip()
        if not raw.startswith("gitdir:"):
            return None
        git_dir = (worktree_path / raw[len("gitdir:") :].strip()).resolve()
        commondir_file = git_dir / "commondir"
        if not commondir_file.is_file():
            return None
        common_rel = commondir_file.read_text(
            encoding="utf-8", errors="replace"
        ).strip()
        if not common_rel:
            return None
        common_git_dir = (git_dir / common_rel).resolve()
        main_repo = common_git_dir.parent
        if (main_repo / ".jj").exists():
            return main_repo
    except OSError:
        return None
    return None


def repo_state(cwd):
    """Return ('jj', root, None) or ('unconverted_worktree', root, worktree) or None."""
    for path in (cwd, *cwd.parents):
        if (path / ".jj").exists():
            return ("jj", path, None)
        if (path / ".git").exists():
            linked_root = linked_worktree_jj_root(path)
            if linked_root is not None:
                return ("unconverted_worktree", linked_root, path)
            # A nested plain Git repository owns its own version-control policy.
            return None
    return None


def jj_root(cwd):
    state = repo_state(cwd)
    return state[1] if state is not None else None


def worktree_instructions(worktree, root):
    return (
        f"JJ-GUARD: The checkout at {worktree} is a plain Git worktree of the "
        f"Jujutsu (jj) repository at {root}, without a .jj workspace.\n"
        f'Run `"$HOME/.local/bin/t3-jj-worktree" setup "{worktree}"` first to '
        "convert it into a colocated jj workspace, then use jj commands instead of git.\n"
    )


def session_instructions_for(cwd):
    state = repo_state(cwd)
    if state is None:
        return None
    kind, root, worktree = state
    if kind == "unconverted_worktree":
        return worktree_instructions(worktree, root) + "\n" + INSTRUCTIONS
    return INSTRUCTIONS


def deny_reason(operation, state):
    kind, root, worktree = state
    guidance = GUIDANCE.get(operation, "Use jj help to find the appropriate operation.")
    if kind == "unconverted_worktree":
        return (
            f"JJ-GUARD: Direct git commands are blocked in {worktree}, which is an "
            f"unconverted Git worktree of the jj repository at {root}. "
            f'Run \'"$HOME/.local/bin/t3-jj-worktree" setup "{worktree}"\' first to '
            f"convert it into a colocated jj workspace, then use jj commands. {guidance}"
        )
    reason = f"JJ-GUARD: Direct git commands are blocked in the jj repository at {root}. {guidance}"
    reason += " If Git is truly required, ask the user for an explicit exception; do not bypass the guard."
    return reason


def submodule_warning(state):
    _, root, _ = state
    return (
        f"JJ-GUARD WARNING: Allowing `git submodule` in the jj repository at {root} "
        "because Jujutsu does not natively manage Git submodules. "
        "Submodule checkout/state changes may not be tracked directly by jj; "
        "continue using jj for all other version-control operations."
    )


def format_warnings(states):
    messages = []
    seen = set()
    for state in states:
        msg = submodule_warning(state)
        if msg not in seen:
            seen.add(msg)
            messages.append(msg)
    return "\n".join(messages)


def substitutions(text):
    """Extract common $() and backtick forms, excluding single-quoted literals."""
    quote = None
    i = 0
    while i < len(text):
        char = text[i]
        if char == "\\" and quote != "'":
            i += 2
            continue
        if char == "'" and quote != '"':
            quote = None if quote == "'" else "'"
        elif char == '"' and quote != "'":
            quote = None if quote == '"' else '"'
        elif quote != "'" and (text.startswith("$(", i) or char == "`"):
            start = i + (2 if char == "$" else 1)
            end = start
            depth = 1
            while end < len(text):
                if text[end] == "\\":
                    end += 2
                    continue
                if char == "`":
                    if text[end] == "`":
                        break
                else:
                    if text[end] == "(":
                        depth += 1
                    elif text[end] == ")":
                        depth -= 1
                        if depth == 0:
                            break
                end += 1
            if end < len(text):
                yield i, end + 1, text[start:end]
                i = end
        i += 1


def git_operation(args, cwd):
    """Honor Git directory options before locating the subcommand."""
    git_dir = None
    work_tree = None
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "-C" and i + 1 < len(args):
            cwd = directory(args[i + 1], cwd)
            i += 2
        elif arg in {"--work-tree", "--git-dir"} and i + 1 < len(args):
            if arg == "--work-tree":
                work_tree = args[i + 1]
            else:
                git_dir = args[i + 1]
            i += 2
        elif arg.startswith("-C") and len(arg) > 2:
            cwd = directory(arg[2:], cwd)
            i += 1
        elif arg.startswith("--work-tree="):
            work_tree = arg.split("=", 1)[1]
            i += 1
        elif arg.startswith("--git-dir="):
            git_dir = arg.split("=", 1)[1]
            i += 1
        elif arg in {
            "-c",
            "--config-env",
            "--namespace",
            "--exec-path",
        } and i + 1 < len(args):
            i += 2
        elif arg.startswith("-"):
            i += 1
        else:
            target = work_tree or git_dir
            return arg, directory(target, cwd) if target else cwd
    target = work_tree or git_dir
    return "", directory(target, cwd) if target else cwd


def _inspect_segment(args, cwd, depth):
    # Unwrap common launchers without running them or trusting bypass variables.
    while args:
        if args[0] in {"if", "then", "elif", "else", "do", "while", "until", "!"}:
            args = args[1:]
            continue
        if ASSIGNMENT.match(args[0]):
            args = args[1:]
            continue
        name = Path(args[0]).name
        if name not in {"env", "command", "builtin", "exec", "nohup", "time", "sudo"}:
            break
        args = args[1:]
        while args and args[0].startswith("-"):
            option = args.pop(0)
            if name == "command" and option in {"-v", "-V"}:
                return None, [], cwd
            if name == "env" and option in {"-C", "--chdir"} and args:
                cwd = directory(args.pop(0), cwd)
            elif name == "env" and option.startswith("--chdir="):
                cwd = directory(option.split("=", 1)[1], cwd)
            elif name == "env" and option in {"-S", "--split-string"} and args:
                blocked, warnings = _inspect_command(args[0], cwd, depth + 1)
                return blocked, warnings, cwd
            elif name == "env" and option in {"-u", "--unset"} and args:
                args.pop(0)
            elif (
                name == "sudo"
                and option in {"-u", "-g", "-h", "-p", "-C", "-T", "-R"}
                and args
            ):
                args.pop(0)
            elif name == "sudo" and option in {"-D", "--chdir"} and args:
                cwd = directory(args.pop(0), cwd)
    if not args:
        return None, [], cwd
    name = Path(args[0]).name
    if name == "git":
        operation, target = git_operation(args[1:], cwd)
        state = repo_state(target)
        if state is None:
            return None, [], cwd
        kind, _, _ = state
        if operation == "submodule" and kind == "jj":
            return None, [state], cwd
        return (operation, state), [], cwd
    if name == "cd":
        paths = [arg for arg in args[1:] if arg not in {"--", "-L", "-P"}]
        if paths and paths[0] != "-":
            return None, [], directory(paths[0], cwd)
        if not paths:
            return None, [], Path.home()
    if name in SHELLS:
        for i, arg in enumerate(args[1:], 1):
            if (
                arg.startswith("-")
                and not arg.startswith("--")
                and "c" in arg
                and i + 1 < len(args)
            ):
                blocked, warnings = _inspect_command(args[i + 1], cwd, depth + 1)
                return blocked, warnings, cwd
    if name == "eval":
        blocked, warnings = _inspect_command(" ".join(args[1:]), cwd, depth + 1)
        return blocked, warnings, cwd
    return None, [], cwd


def _inspect_command(command, cwd, depth=0):
    if depth > 16:
        return None, []
    # Keep substitution bodies associated with their segment's working directory.
    # Mask them before tokenizing so nested operators don't split the outer shell.
    bodies = {}
    pieces = []
    previous = 0
    for start, end, body in substitutions(command):
        marker = f"__JJ_GUARD_SUB_{len(bodies)}__"
        bodies[marker] = body
        pieces.extend([command[previous:start], marker])
        previous = end
    pieces.append(command[previous:])
    masked = "".join(pieces)
    lexer = shlex.shlex(masked, posix=True, punctuation_chars=";&|()\n")
    lexer.whitespace = " \t\r"
    try:
        tokens = list(lexer)
    except ValueError:
        # Incomplete/unsupported shell text: try the recognizable portion.
        tokens = masked.split()
    segment = []
    scopes = []
    warnings = []
    for token in [*tokens, ";"]:
        if token in SEPARATORS or re.fullmatch(r"[;&|()\n]+", token):
            for argument in segment:
                for marker, body in bodies.items():
                    if marker in argument:
                        blocked, sub_warnings = _inspect_command(body, cwd, depth + 1)
                        warnings.extend(sub_warnings)
                        if blocked:
                            return blocked, warnings
            blocked, seg_warnings, cwd = _inspect_segment(segment, cwd, depth)
            warnings.extend(seg_warnings)
            if blocked:
                return blocked, warnings
            segment = []
            for char in token:
                if char == "(":
                    scopes.append(cwd)
                elif char == ")" and scopes:
                    cwd = scopes.pop()
        elif token in {"{", "}"}:
            continue
        else:
            segment.append(token)
    return None, warnings


def inspect_command(command, cwd, depth=0):
    blocked, _ = _inspect_command(command, cwd, depth)
    return blocked


def agy_workspace_paths(payload):
    raw = payload.get("workspacePaths")
    if not isinstance(raw, list):
        return []
    paths = []
    for entry in raw:
        if isinstance(entry, str) and entry:
            try:
                paths.append(Path(entry).resolve())
            except OSError:
                continue
    return paths


def handle_agy(payload, mode):
    workspace_paths = agy_workspace_paths(payload)
    if mode == "session_start":
        messages = []
        seen = set()
        for ws_path in workspace_paths:
            msg = session_instructions_for(ws_path)
            if msg and msg not in seen:
                seen.add(msg)
                messages.append(msg)
        if messages:
            return {
                "injectSteps": [
                    {"systemMessage": {"systemMessage": "\n".join(messages)}}
                ]
            }
        return None

    if mode == "pre_tool":
        tool_call = payload.get("toolCall")
        if not isinstance(tool_call, dict) or tool_call.get("name") != "run_command":
            return None
        args = tool_call.get("args")
        if not isinstance(args, dict):
            return None
        command = args.get("CommandLine")
        if not isinstance(command, str):
            return None
        default_cwd = next(
            (p for p in workspace_paths if repo_state(p) is not None),
            workspace_paths[0] if workspace_paths else Path.cwd(),
        )
        raw_cwd = args.get("Cwd")
        cwd = (
            directory(raw_cwd, default_cwd)
            if isinstance(raw_cwd, str) and raw_cwd
            else default_cwd
        )
        blocked, warnings = _inspect_command(command, cwd)
        if blocked:
            operation, state = blocked
            return {
                "decision": "deny",
                "reason": deny_reason(operation, state),
            }
        if warnings:
            return {
                "decision": "allow",
                "reason": format_warnings(warnings),
            }
        # Empty stdout means "no opinion" in Antigravity; never return {} on PreToolUse.
        return None

    return None


def handle(payload, agent=None, mode=None):
    if agent == "agy":
        return handle_agy(payload, mode)

    cwd = Path(payload.get("cwd") or os.getcwd()).resolve()
    event = payload.get("hook_event_name")
    if event == "SessionStart":
        instructions = session_instructions_for(cwd)
        if instructions:
            return {
                "hookSpecificOutput": {
                    "hookEventName": event,
                    "additionalContext": instructions,
                }
            }
    elif event == "PreToolUse" and payload.get("tool_name") in {
        "Bash",
        "exec_command",
        "shell",
        "shell_command",
    }:
        args = payload.get("tool_input")
        if not isinstance(args, dict):
            return None
        command = args.get("command", args.get("cmd"))
        if not isinstance(command, str):
            return None
        cwd = directory(args.get("cwd") or args.get("workdir") or str(cwd), cwd)
        blocked, warnings = _inspect_command(command, cwd)
        if blocked:
            operation, state = blocked
            return {
                "hookSpecificOutput": {
                    "hookEventName": event,
                    "permissionDecision": "deny",
                    "permissionDecisionReason": deny_reason(operation, state),
                }
            }
        if warnings:
            warning = format_warnings(warnings)
            return {
                "systemMessage": warning,
                "hookSpecificOutput": {
                    "hookEventName": event,
                    "additionalContext": warning,
                },
            }
    return None


def main():
    agent = sys.argv[1] if len(sys.argv) > 1 else None
    mode = sys.argv[2] if len(sys.argv) > 2 else None
    try:
        payload = json.load(sys.stdin)
        output = (
            handle(payload, agent=agent, mode=mode)
            if isinstance(payload, dict)
            else None
        )
    except (ValueError, OSError, TypeError) as error:
        # Fail open for malformed input/filesystem failures, as a best-effort hook.
        print(f"JJ-GUARD: Could not inspect hook input: {error}", file=sys.stderr)
        return
    if output:
        print(json.dumps(output))


if __name__ == "__main__":
    main()
