import type {Plugin} from '@opencode-ai/plugin';

// JJ-Guard OpenCode plugin — blocks git commands in jj repositories.
// Throws an error with guidance so the agent sees the message and
// decides to use jj commands instead. Git-specific operations that
// have no jj equivalent ask the agent to request user approval.
// Also injects a system prompt line so the agent proactively uses jj.

const JJ_SYSTEM_LINE = [
  'IMPORTANT: This repository uses Jujutsu (jj) for version control, NOT git.',
  'Use `jj` commands: `jj status`, `jj diff`, `jj log`, `jj new`, `jj edit`, `jj describe`, etc.',
  'Do NOT run `git` commands unless the user explicitly approves it, except `git submodule` (allowed with a warning because Jujutsu does not natively manage Git submodules).',
].join(' ');

// Direct 1:1 equivalents — same concept, just different command name.
const JJ_EQUIVALENTS: Record<string, string> = {
  bisect: 'jj bisect',
  blame: 'jj file annotate <file>',
  describe: 'jj describe [revision]',
  diff: 'jj diff',
  fetch: 'jj git fetch',
  push: 'jj git push',
  rebase: 'jj rebase -s <source> -d <destination>',
  remote: 'jj git remote',
  restore: 'jj restore',
  show: 'jj show',
  status: 'jj status',
};

// Git-specific constructs — jj has a different model entirely.
// Show a help message explaining the jj way instead of a direct equivalent.
const JJ_HELP: Record<string, string> = {
  branch: `JJ-GUARD: jj doesn't use branches — it uses 'bookmarks'.

  Instead of: git branch
  Use:        jj bookmark list
              jj bookmark create <name>
              jj bookmark set --revision <rev> <name>
              jj bookmark move --to <rev> <name>
              jj bookmark delete <name>

  Unlike git, bookmarks don't auto-update when you commit.
  Use 'jj bookmark set' to point a bookmark at a revision.`,

  commit: `JJ-GUARD: jj doesn't have a commit command — the working copy is always saved.

  Instead of: git commit
  Use:        jj describe           → set or edit the current change's description
              jj new                → create a new change (current one is already saved)
              jj edit <revision>    → switch to another change

  In jj, there's no staging area and no explicit commit step.
  Every change is automatically saved as you work.`,

  checkout: `JJ-GUARD: jj doesn't have a checkout command — there's no 'current branch'.

  Instead of: git checkout <rev>
  Use:        jj edit <revision>    → make a revision the working copy
              jj new <revision>     → create a new change on top of a revision

  In jj, the working copy is always a commit. Use 'jj edit' to examine
  an existing change, or 'jj new' to start a new one.`,

  switch: `JJ-GUARD: jj doesn't have a switch command — there's no 'current branch'.

  Instead of: git switch <branch>
  Use:        jj edit <bookmark>    → make a bookmark's revision the working copy
              jj new <bookmark>     → create a new change on top of a bookmark

  Bookmarks in jj don't auto-update on commit. Use 'jj bookmark set'
  to point a bookmark at your current working copy.`,

  stash: `JJ-GUARD: jj doesn't need stash — your in-progress work is always a saved commit.

  Instead of: git stash
  Use:        Your work is already saved as the working-copy commit.
              jj describe           → set a description, work stays saved
              jj new                → create a new change (work stays in the old one)
              jj edit <revision>    → return to a previous change

  There's no staging area in jj. Every change is a commit.`,

  reset: `JJ-GUARD: jj doesn't have a single reset command — use the right tool for the intent.

  Instead of: git reset
  Use:        jj abandon <revision>              → discard a change (like git reset --hard)
              jj restore --from <revision>       → restore files from another revision
              jj squash --from @-                → fold parent into working copy (like git reset --soft)
              jj edit <revision>                 → move working copy to a revision`,

  pull: `JJ-GUARD: jj doesn't have a single pull command — fetch and integrate separately.

  Instead of: git pull
  Use:        jj git fetch                        → fetch from remote
              jj new @ <remote/bookmark>          → merge fetched changes
              jj rebase -s @ -d <remote/bookmark> → rebase onto fetched changes`,

  merge: `JJ-GUARD: jj creates merges differently — every commit can have multiple parents.

  Instead of: git merge <branch>
  Use:        jj new @ <branch>                   → create a merge commit

  In jj, conflicts can be committed. Use 'jj resolve' to fix conflicts,
  then 'jj commit' to finish.`,

  log: `JJ-GUARD: jj log has different defaults than git log.

  Instead of: git log
  Use:        jj log                              → shows mutable revisions only (default)
              jj log -r ::                        → show ALL revisions including immutable
              jj log -r ::@                       → show ancestors of working copy
              jj log -T builtin_log_compact_full_description → show full commit messages

  jj log shows a graph by default and only mutable revisions unless you
  specify a revset with -r. Immutable revisions are hidden by default.`,

  worktree: `JJ-GUARD: jj uses 'workspaces' instead of worktrees.

  Instead of: git worktree
  Use:        jj workspace add <path>             → create a new working copy
              jj workspace list                   → list all workspaces
              jj workspace forget <name>          → remove a workspace
              jj workspace update-stale           → sync a stale workspace

  Each workspace has its own working-copy commit, shown as 'name@' in jj log.`,
};

// Git plumbing/low-level operations with no jj equivalent.
// These require user approval to run.
const GIT_SPECIFIC_OPS = [
  'archive',
  'bundle',
  'cat-file',
  'filter-branch',
  'fsck',
  'hash-object',
  'instaweb',
  'ls-tree',
  'merge-base',
  'pack-objects',
  'reflog',
  'rev-list',
  'rev-parse',
  'unpack-objects',
  'update-ref',
];

const SUBMODULE_WARNING =
  'JJ-GUARD WARNING: Allowing `git submodule` in this jj repository because Jujutsu does not natively manage Git submodules. Submodule checkout/state changes may not be tracked directly by jj; continue using jj for all other version-control operations.';

const SEGMENT_SPLIT = /\s*(?:&&|\|\||[;|])\s*/;
const ENV_ASSIGNMENT = /^[A-Za-z_][A-Za-z_0-9]*=/;
const GIT_VALUE_FLAGS = new Set([
  '-C',
  '-c',
  '--work-tree',
  '--git-dir',
  '--config-env',
  '--namespace',
  '--exec-path',
]);

function parseGitSegment(segment: string): {gitCmd: string; segParts: string[]} | null {
  const parts = segment.split(/\s+/).filter(Boolean);
  while (parts.length > 0 && ENV_ASSIGNMENT.test(parts[0])) {
    parts.shift();
  }
  if (parts.length === 0) return null;
  const bin = parts[0].split('/').pop();
  if (bin !== 'git') return null;

  let i = 1;
  while (i < parts.length) {
    const arg = parts[i];
    if (GIT_VALUE_FLAGS.has(arg) && i + 1 < parts.length) {
      i += 2;
    } else if (arg.startsWith('-')) {
      i += 1;
    } else {
      return {gitCmd: arg, segParts: parts};
    }
  }
  return {gitCmd: '', segParts: parts};
}

function inspectCommandSegments(command: string): {
  blocked: {gitCmd: string; segParts: string[]} | null;
  hasSubmodule: boolean;
} {
  const segments = command
    .trim()
    .split(SEGMENT_SPLIT)
    .map((s) => s.trim())
    .filter(Boolean);

  let hasSubmodule = false;
  for (const segment of segments) {
    const parsed = parseGitSegment(segment);
    if (!parsed) continue;
    if (parsed.gitCmd === 'submodule') {
      hasSubmodule = true;
      continue;
    }
    return {blocked: parsed, hasSubmodule};
  }
  return {blocked: null, hasSubmodule};
}

export const JjGuardPlugin: Plugin = async ({$, client}) => {
  try {
    await $`jj root`.quiet();
  } catch {
    await client.app.log({
      body: {
        service: 'jj-guard',
        level: 'info',
        message: 'Not in a jj repository — plugin disabled',
      },
    });
    return {};
  }

  const submoduleCalls = new Set<string>();

  return {
    'experimental.chat.system.transform': async (_input, output) => {
      if (!output.system.includes(JJ_SYSTEM_LINE)) {
        output.system.push(JJ_SYSTEM_LINE);
      }
    },
    'tool.execute.before': async (input, output) => {
      const tool = String(input?.tool ?? '').toLowerCase();
      if (tool !== 'bash' && tool !== 'shell') return;

      const args = output?.args;
      if (!args || typeof args !== 'object') return;

      const command = (args as Record<string, unknown>).command;
      if (typeof command !== 'string' || !command) return;

      const trimmed = command.trim();
      const {blocked, hasSubmodule} = inspectCommandSegments(trimmed);

      if (!blocked) {
        if (hasSubmodule) {
          if (input?.callID) submoduleCalls.add(input.callID);
          await client.app
            .log({
              body: {
                service: 'jj-guard',
                level: 'warn',
                message: SUBMODULE_WARNING,
              },
            })
            .catch(() => {});
        }
        return;
      }

      const {gitCmd, segParts} = blocked;

      // Git-specific operations — ask agent to request user approval
      if (GIT_SPECIFIC_OPS.includes(gitCmd)) {
        throw new Error(`JJ-GUARD: 'git ${gitCmd}' is a git-specific operation with no direct jj equivalent.
This requires user approval. Ask the user before proceeding.

If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`);
      }

      // config --global/--system
      if (
        gitCmd === 'config' &&
        (segParts.includes('--global') || segParts.includes('--system'))
      ) {
        throw new Error(`JJ-GUARD: Global/system git config is outside the jj repository scope.
This requires user approval. Ask the user before proceeding.

If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`);
      }

      // Git-specific construct — show jj help message
      const jjHelp = JJ_HELP[gitCmd];
      if (jjHelp) {
        throw new Error(jjHelp);
      }

      // Known command — suggest jj equivalent
      const jjCmd = JJ_EQUIVALENTS[gitCmd];
      if (jjCmd) {
        throw new Error(`JJ-GUARD: This repository uses Jujutsu (jj) for version control.

Instead of: ${trimmed}
Use:        ${jjCmd}

If you're unsure about the jj equivalent, ask the user for guidance.`);
      }

      // Unknown command — generic message
      throw new Error(`JJ-GUARD: This repository uses Jujutsu (jj) for version control.

Instead of: ${trimmed}
Please use jj commands instead.
If this is a git-specific operation with no jj equivalent, ask the user for approval.

If the user approves, they can run it with: JJ_GUARD_BYPASS=1 ${trimmed}`);
    },
    'tool.execute.after': async (input, output) => {
      const tool = String(input?.tool ?? '').toLowerCase();
      if (tool !== 'bash' && tool !== 'shell') return;

      const tracked = input?.callID ? submoduleCalls.delete(input.callID) : false;
      const command =
        input?.args && typeof input.args === 'object'
          ? (input.args as Record<string, unknown>).command
          : undefined;
      const matched =
        typeof command === 'string' && command
          ? (() => {
              const res = inspectCommandSegments(command);
              return !res.blocked && res.hasSubmodule;
            })()
          : false;

      if (!tracked && !matched) return;
      output.output = output.output
        ? `${SUBMODULE_WARNING}\n\n${output.output}`
        : SUBMODULE_WARNING;
    },
  };
};
