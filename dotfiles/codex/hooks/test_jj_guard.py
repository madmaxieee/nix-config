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

    def _make_linked_worktree(self, repo_root, name):
        wt_git_dir = repo_root / ".git" / "worktrees" / name
        wt_git_dir.mkdir(parents=True)
        (wt_git_dir / "commondir").write_text("../..\n")
        wt = self.base / name
        wt.mkdir()
        (wt / ".git").write_text(f"gitdir: {wt_git_dir}\n")
        return wt

    def test_linked_git_worktree_of_jj_repo(self):
        jj_wt = self._make_linked_worktree(self.repo, "t3-jj-wt")
        plain_wt = self._make_linked_worktree(self.plain, "t3-plain-wt")

        # SessionStart warns that jj_wt is an unconverted Git worktree of self.repo
        session = jj_guard.handle(
            {"hook_event_name": "SessionStart", "cwd": str(jj_wt)}
        )
        self.assertIsNotNone(session)
        ctx = session["hookSpecificOutput"]["additionalContext"]
        self.assertIn("t3-jj-worktree", ctx)
        self.assertIn(str(self.repo), ctx)

        # Direct git commands in unconverted jj worktree are denied; setup helper is allowed
        denied = self.hook("git status", cwd=jj_wt)
        self.assertEqual(denied["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn(
            "t3-jj-worktree",
            denied["hookSpecificOutput"]["permissionDecisionReason"],
        )
        self.assertIsNone(
            self.hook('"$HOME/.local/bin/t3-jj-worktree" setup', cwd=jj_wt)
        )

        # Plain-Git worktrees remain untouched
        self.assertIsNone(
            jj_guard.handle({"hook_event_name": "SessionStart", "cwd": str(plain_wt)})
        )
        self.assertIsNone(self.hook("git status", cwd=plain_wt))

    def test_antigravity_wire_protocol(self):
        script = str(Path(jj_guard.__file__))
        attachments = self.base / "attachments"
        attachments.mkdir()
        jj_wt = self._make_linked_worktree(self.repo, "agy-wt")

        # 1. SessionStart with [attachments, jj_wt]
        res = subprocess.run(
            [sys.executable, script, "agy", "session_start"],
            input=json.dumps({"workspacePaths": [str(attachments), str(jj_wt)]}),
            text=True,
            capture_output=True,
            check=True,
        )
        parsed = json.loads(res.stdout)
        sys_msg = parsed["injectSteps"][0]["systemMessage"]["systemMessage"]
        self.assertIn("t3-jj-worktree", sys_msg)
        self.assertIn("Jujutsu", sys_msg)

        # 2. SessionStart on plain repo emits empty stdout
        res_plain = subprocess.run(
            [sys.executable, script, "agy", "session_start"],
            input=json.dumps({"workspacePaths": [str(self.plain)]}),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(res_plain.stdout, "")

        # 3. PreToolUse blocks git in jj repo and unconverted worktree
        for target_dir in (self.repo, jj_wt):
            res_deny = subprocess.run(
                [sys.executable, script, "agy", "pre_tool"],
                input=json.dumps(
                    {
                        "workspacePaths": [str(attachments), str(target_dir)],
                        "toolCall": {
                            "name": "run_command",
                            "args": {
                                "CommandLine": "git status",
                                "Cwd": str(target_dir),
                            },
                        },
                    }
                ),
                text=True,
                capture_output=True,
                check=True,
            )
            deny_json = json.loads(res_deny.stdout)
            self.assertEqual(deny_json["decision"], "deny")
            self.assertIn("JJ-GUARD", deny_json["reason"])

        # 4. PreToolUse allows git submodule with warning in jj repo, denies in unconverted worktree
        res_sub = subprocess.run(
            [sys.executable, script, "agy", "pre_tool"],
            input=json.dumps(
                {
                    "workspacePaths": [str(attachments), str(self.repo)],
                    "toolCall": {
                        "name": "run_command",
                        "args": {
                            "CommandLine": "git submodule update --init --recursive",
                            "Cwd": str(self.repo),
                        },
                    },
                }
            ),
            text=True,
            capture_output=True,
            check=True,
        )
        sub_json = json.loads(res_sub.stdout)
        self.assertEqual(sub_json["decision"], "allow")
        self.assertIn("JJ-GUARD WARNING", sub_json["reason"])

        res_sub_wt = subprocess.run(
            [sys.executable, script, "agy", "pre_tool"],
            input=json.dumps(
                {
                    "workspacePaths": [str(attachments), str(jj_wt)],
                    "toolCall": {
                        "name": "run_command",
                        "args": {
                            "CommandLine": "git submodule status",
                            "Cwd": str(jj_wt),
                        },
                    },
                }
            ),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(json.loads(res_sub_wt.stdout)["decision"], "deny")

        # 5. PreToolUse emits strictly empty stdout (never {}) when allowed
        for cmd in ("jj status", '"$HOME/.local/bin/t3-jj-worktree" setup'):
            res_ok = subprocess.run(
                [sys.executable, script, "agy", "pre_tool"],
                input=json.dumps(
                    {
                        "workspacePaths": [str(attachments), str(self.repo)],
                        "toolCall": {
                            "name": "run_command",
                            "args": {"CommandLine": cmd, "Cwd": str(self.repo)},
                        },
                    }
                ),
                text=True,
                capture_output=True,
                check=True,
            )
            self.assertEqual(res_ok.stdout, "")

    def test_allows_git_submodule_with_warning(self):
        for command in [
            "git submodule",
            "git submodule status",
            "git submodule update --init --recursive",
            "git -c protocol.file.allow=always submodule update",
            "bash -lc 'git submodule status'",
            'echo "$(git submodule status)"',
            f'jj status && git -C "{self.repo}" submodule update --init --recursive',
        ]:
            with self.subTest(command=command):
                output = self.hook(command)
                self.assertIsNotNone(output)
                hook_out = output["hookSpecificOutput"]
                self.assertNotIn("permissionDecision", hook_out)
                self.assertIn("JJ-GUARD WARNING", hook_out["additionalContext"])
                self.assertIn(str(self.repo), hook_out["additionalContext"])
                self.assertIn("JJ-GUARD WARNING", output["systemMessage"])

        # Targeting jj repo from plain cwd also warns
        from_plain = self.hook(
            f'git -C "{self.repo}" submodule status', cwd=self.plain
        )
        self.assertIsNotNone(from_plain)
        self.assertIn(
            "JJ-GUARD WARNING", from_plain["hookSpecificOutput"]["additionalContext"]
        )

        # Targeting plain repo emits no warning
        self.assertIsNone(self.hook(f'git -C "{self.plain}" submodule status'))
        self.assertIsNone(self.hook("git submodule status", cwd=self.plain))

        # Chaining with blocked git commands must still deny
        for blocked_cmd in [
            "git submodule status && git status",
            "git status && git submodule status",
            "git -c submodule.recurse=true status",
        ]:
            with self.subTest(blocked_cmd=blocked_cmd):
                output = self.hook(blocked_cmd)
                self.assertEqual(
                    output["hookSpecificOutput"]["permissionDecision"], "deny"
                )

        # Unconverted worktree still denies git submodule until setup is run
        jj_wt = self._make_linked_worktree(self.repo, "sub-wt")
        denied_wt = self.hook("git submodule status", cwd=jj_wt)
        self.assertEqual(denied_wt["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn(
            "t3-jj-worktree",
            denied_wt["hookSpecificOutput"]["permissionDecisionReason"],
        )


if __name__ == "__main__":
    unittest.main()
