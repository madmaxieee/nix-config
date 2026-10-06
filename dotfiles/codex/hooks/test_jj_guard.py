"""Run with: python3 -m unittest discover -s dotfiles/codex/hooks -v"""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import jj_guard


class JjGuardTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / "jj repo"
        self.repo.mkdir()
        (self.repo / ".jj").mkdir()
        (self.repo / ".git").mkdir()
        self.subdir = self.repo / "src"
        self.subdir.mkdir()
        self.plain = self.base / "plain"
        self.plain.mkdir()
        (self.plain / ".git").mkdir()
        self.nested = self.repo / "nested"
        self.nested.mkdir()
        (self.nested / ".git").write_text("gitdir: elsewhere\n")

    def hook(self, command, cwd=None, **args):
        return jj_guard.handle(
            {
                "hook_event_name": "PreToolUse",
                "tool_name": "Bash",
                "cwd": str(cwd or self.subdir),
                "tool_input": {"command": command, **args},
            }
        )

    def test_session_instructions(self):
        for source in ("startup", "resume", "clear", "compact"):
            with self.subTest(source=source):
                output = jj_guard.handle(
                    {
                        "hook_event_name": "SessionStart",
                        "cwd": str(self.subdir),
                        "source": source,
                    }
                )
                self.assertIn(
                    "Jujutsu", output["hookSpecificOutput"]["additionalContext"]
                )
                self.assertEqual(
                    output["hookSpecificOutput"]["hookEventName"], "SessionStart"
                )

    def test_no_instructions_for_plain_repo(self):
        for cwd in (self.plain, self.nested, self.base):
            self.assertIsNone(
                jj_guard.handle({"hook_event_name": "SessionStart", "cwd": str(cwd)})
            )

    def test_blocks_common_git_forms(self):
        commands = [
            "git status",
            "/usr/bin/git diff",
            "git",
            "git -c color.ui=false status",
            "FOO=bar git status",
            "env FOO=bar git status",
            "env -u FOO git status",
            "command git status",
            "exec git status",
            "nohup git status",
            "time git status",
            "sudo -u someone git status",
            "echo ready && git status",
            "false || git diff",
            "printf x | git status",
            "echo ready\ngit status",
            "(git status)",
            "{ git status; }",
            "if git status; then echo yes; fi",
            "while git status; do break; done",
            "bash -lc 'git status'",
            "zsh -c 'env FOO=bar git status'",
            "eval 'git status'",
            'echo "$(git status)"',
            "echo `git status`",
            "echo $(echo $(git status))",
            f'cd "{self.repo}" && git status',
            f'git -C "{self.repo}" status',
            "JJ_GUARD_BYPASS=1 git status",
        ]
        for command in commands:
            with self.subTest(command=command):
                output = self.hook(command)
                self.assertIsNotNone(output)
                self.assertEqual(
                    output["hookSpecificOutput"]["permissionDecision"], "deny"
                )

    def test_leaves_other_commands_alone(self):
        for command in [
            "jj status",
            "jj git fetch",
            "jj git push",
            "echo 'git status'",
            "rg git README.md",
            "command -v git",
            "gitty status",
            "# git status\necho fine",
            "echo '$(git status)'",
            "echo '\\`git status\\`'",
            "printf '%s' 'git status; git diff'",
        ]:
            with self.subTest(command=command):
                self.assertIsNone(self.hook(command))

    def test_checks_target_directory_each_time(self):
        self.assertIsNone(self.hook("git status", cwd=self.plain))
        self.assertIsNone(self.hook("git status", cwd=self.nested))
        self.assertIsNone(self.hook("git status", workdir=str(self.plain)))
        self.assertIsNotNone(
            self.hook("git status", cwd=self.plain, workdir=str(self.repo))
        )
        self.assertIsNotNone(
            self.hook(f'cd "{self.repo}" && git status', cwd=self.base)
        )
        self.assertIsNone(self.hook(f'cd "{self.plain}" && git status'))
        self.assertIsNone(self.hook(f'git -C "{self.plain}" status'))
        self.assertIsNotNone(self.hook(f'git -C "{self.repo}" status', cwd=self.plain))
        self.assertIsNotNone(
            self.hook(f'git -C "{self.base}" -C "jj repo" status', cwd=self.plain)
        )
        self.assertIsNotNone(
            self.hook(f'env --chdir="{self.repo}" git status', cwd=self.plain)
        )
        self.assertIsNotNone(
            self.hook(f'env -C "{self.repo}" git status', cwd=self.plain)
        )
        self.assertIsNotNone(self.hook(f'(cd "{self.plain}" && echo fine); git status'))
        self.assertIsNone(
            self.hook(f'(cd "{self.repo}" && echo fine); git status', cwd=self.plain)
        )
        self.assertIsNotNone(self.hook(f'echo "$(git status)"; cd "{self.plain}"'))
        self.assertIsNotNone(
            self.hook(f'cd "{self.repo}"; echo "$(git status)"', cwd=self.plain)
        )

    def test_workspace_marker_can_be_file(self):
        workspace = self.base / "workspace"
        workspace.mkdir()
        (workspace / ".jj").write_text("workspace marker\n")
        self.assertIsNotNone(self.hook("git status", cwd=workspace))

    def test_git_directory_options(self):
        self.assertIsNotNone(
            self.hook(f'git --git-dir="{self.repo}/.git" -C "{self.plain}" status')
        )
        self.assertIsNotNone(
            self.hook(f'git --work-tree="{self.repo}" -C "{self.plain}" status')
        )
        self.assertIsNotNone(
            self.hook(
                f'git --git-dir .git --work-tree . -C "{self.repo}" status',
                cwd=self.plain,
            )
        )
        self.assertIsNone(self.hook(f'git --git-dir="{self.plain}/.git" status'))

    def test_guidance_uses_actual_subcommand(self):
        output = self.hook("git -c color.ui=false diff")
        self.assertIn(
            "Use jj diff", output["hookSpecificOutput"]["permissionDecisionReason"]
        )

    def test_wire_protocol(self):
        script = str(Path(jj_guard.__file__))
        for command, blocked in [("git status", True), ("jj git fetch", False)]:
            payload = {
                "hook_event_name": "PreToolUse",
                "tool_name": "Bash",
                "cwd": str(self.repo),
                "tool_input": {"command": command},
            }
            result = subprocess.run(
                [sys.executable, script],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                check=True,
            )
            if blocked:
                self.assertEqual(
                    json.loads(result.stdout)["hookSpecificOutput"][
                        "permissionDecision"
                    ],
                    "deny",
                )
            else:
                self.assertEqual(result.stdout, "")
        result = subprocess.run(
            [sys.executable, script], input="not json", text=True, capture_output=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("Could not inspect", result.stderr)

    def test_unknown_events_and_inputs(self):
        for payload in [
            {},
            {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": None},
            {"hook_event_name": "PostToolUse"},
        ]:
            self.assertIsNone(jj_guard.handle(payload))


if __name__ == "__main__":
    unittest.main()
