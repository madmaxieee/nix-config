import type { Plugin } from "@opencode-ai/plugin";

// Bun-Guard OpenCode plugin — blocks npm, npx, yarn, pnpm commands in bun projects.
// Activated when bun.lock or bun.lockb is present in the repository root.
// Simply blocks and tells the agent this project uses bun.
// Also injects a system prompt line so the agent proactively uses bun.

const BUN_SYSTEM_LINE = [
  "IMPORTANT: This project uses bun as its package manager.",
  "Use `bun` commands: `bun install`, `bun run`, `bun add`, `bun remove`, `bun test`.",
  "Use `bunx` instead of `npx`.",
  "Do NOT use npm, yarn, or pnpm unless the user explicitly approves it.",
].join(" ");

const BLOCKED = ["npm", "npx", "yarn", "pnpm", "pnpx"];

export const BunGuardPlugin: Plugin = async ({ $, client }) => {
  let isBunProject = false;

  try {
    const root = String(
      await $`git rev-parse --show-toplevel`.quiet().nothrow(),
    ).trim();
    if (!root) return {};
    for (const lock of ["bun.lockb", "bun.lock"]) {
      const exists = (await $`test -f ${root}/${lock}`.quiet().nothrow())
        .exitCode;
      if (exists === 0) {
        isBunProject = true;
        break;
      }
    }
  } catch {
    await client.app.log({
      body: {
        service: "bun-guard",
        level: "info",
        message: "Failed to detect bun lock file — plugin disabled",
      },
    });
    return {};
  }

  if (!isBunProject) {
    await client.app.log({
      body: {
        service: "bun-guard",
        level: "info",
        message: "No bun lock file found — plugin disabled",
      },
    });
    return {};
  }

  return {
    "experimental.chat.system.transform": async (_input, output) => {
      if (!output.system.includes(BUN_SYSTEM_LINE)) {
        output.system.push(BUN_SYSTEM_LINE);
      }
    },
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase();
      if (tool !== "bash" && tool !== "shell") return;

      const args = output?.args;
      if (!args || typeof args !== "object") return;

      const command = (args as Record<string, unknown>).command;
      if (typeof command !== "string" || !command) return;

      const trimmed = command.trim();

      // Check for `rtk <pm> ...` pattern
      if (trimmed.startsWith("rtk ")) {
        const rest = trimmed.slice(4).trim();
        for (const pm of BLOCKED) {
          if (rest === pm || rest.startsWith(pm + " ")) {
            throw new Error(
              `BUN-GUARD: This project uses bun as its package manager.\n\n` +
                `Blocked: ${trimmed}\n` +
                `Use bun commands instead (bun install, bun run, bun add, etc.).`,
            );
          }
        }
      }

      // Check for direct `npm ...`, `npx ...`, `yarn ...`, `pnpm ...`
      for (const pm of BLOCKED) {
        if (trimmed === pm || trimmed.startsWith(pm + " ")) {
          throw new Error(
            `BUN-GUARD: This project uses bun as its package manager.\n\n` +
              `Blocked: ${trimmed}\n` +
              `Use bun commands instead (bun install, bun run, bun add, etc.).`,
          );
        }
      }
    },
  };
};
