import type { Plugin } from "@opencode-ai/plugin";

// JJ-Guard OpenCode plugin — blocks git commands in jj repositories.
// Throws an error with guidance so the agent sees the message and
// decides to use jj commands instead. Git-specific operations that
// have no jj equivalent ask the agent to request user approval.

const JJ_EQUIVALENTS: Record<string, string> = {
  bisect: "jj bisect",
  blame: "jj file annotate <file>",
  branch: "jj branch",
  checkout: "jj edit <revision>",
  commit: "jj commit (or jj describe to edit the current change's description)",
  describe: "jj describe [revision]",
  diff: "jj diff",
  fetch: "jj git fetch",
  log: "jj log",
  merge: "jj new <rev1> <rev2> (creates a merge change)",
  pull: "jj git fetch",
  push: "jj git push",
  rebase: "jj rebase -s <source> -d <destination>",
  remote: "jj git remote (list/add/remove)",
  reset: "jj abandon <revision> or jj edit <revision>",
  restore: "jj restore",
  worktree: "jj workspace",
  show: "jj show",
  stash: "jj stash create/list/pop",
  status: "jj status",
  switch: "jj edit <revision>",
};

const GIT_SPECIFIC_OPS = [
  "gc",
  "reflog",
  "fsck",
  "filter-branch",
  "submodule",
  "hash-object",
  "cat-file",
  "ls-tree",
  "rev-parse",
  "rev-list",
  "merge-base",
  "update-ref",
  "pack-objects",
  "unpack-objects",
];

export const JjGuardPlugin: Plugin = async ({ $ }) => {
  try {
    await $`jj root`.quiet();
  } catch {
    console.warn("[jj-guard] Not in a jj repository — plugin disabled");
    return {};
  }

  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase();
      if (tool !== "bash" && tool !== "shell") return;

      const args = output?.args;
      if (!args || typeof args !== "object") return;

      const command = (args as Record<string, unknown>).command;
      if (typeof command !== "string" || !command) return;

      const trimmed = command.trim();

      // Detect both `git ...` and `rtk git ...` commands
      const isRtkGit = trimmed.startsWith("rtk git ");
      if (!trimmed.startsWith("git ") && trimmed !== "git" && !isRtkGit) return;

      const parts = trimmed.split(/\s+/);
      // For `rtk git <cmd>`, the git subcommand is at index 2
      const gitCmd = isRtkGit ? parts[2] || "" : parts[1] || "";

      // Git-specific operations — ask agent to request user approval
      if (GIT_SPECIFIC_OPS.includes(gitCmd)) {
        throw new Error(
          `JJ-GUARD: 'git ${gitCmd}' is a git-specific operation with no direct jj equivalent.\n` +
            `This requires user approval. Ask the user before proceeding.\n\n` +
            `If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`,
        );
      }

      // config --global/--system
      if (
        gitCmd === "config" &&
        (parts.includes("--global") || parts.includes("--system"))
      ) {
        throw new Error(
          `JJ-GUARD: Global/system git config is outside the jj repository scope.\n` +
            `This requires user approval. Ask the user before proceeding.\n\n` +
            `If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`,
        );
      }

      // Known command — suggest jj equivalent
      const jjCmd = JJ_EQUIVALENTS[gitCmd];
      if (jjCmd) {
        throw new Error(
          `JJ-GUARD: This repository uses Jujutsu (jj) for version control.\n\n` +
            `Instead of: ${trimmed}\n` +
            `Use:        ${jjCmd}\n\n` +
            `If you're unsure about the jj equivalent, ask the user for guidance.`,
        );
      }

      // Unknown command — generic message
      throw new Error(
        `JJ-GUARD: This repository uses Jujutsu (jj) for version control.\n\n` +
          `Instead of: ${trimmed}\n` +
          `Please use jj commands instead.\n` +
          `If this is a git-specific operation with no jj equivalent, ask the user for approval.\n\n` +
          `If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`,
      );
    },
  };
};
