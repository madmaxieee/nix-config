---
description: Generate and apply a commit based on current changes and chat context
agent: fast
subtask: false
---

Detect the VCS in use and apply a commit with a well-crafted message.

## Step 1: Detect VCS

- If `.jj/` exists at repo root → use **jj** commands
- If `.git/` exists (and no `.jj/`) → use **git** commands

## Step 2: Gather context

Run the appropriate commands to understand current state:

**For jj:**

- `jj log -r @ --no-graph` — current change description
- `jj diff` — full diff of uncommitted changes
- `jj status` — file-level status

**For git:**

- `git diff --cached` — staged changes
- `git diff` — unstaged changes
- `git status --short` — file-level status

## Step 3: Learn commit convention

Check if the repo has a commit convention by looking for:

- `AGENTS.md` at repo root (look for commit/message conventions)
- `.gitmessage` or `.gitmessage.txt`
- Recent commit history for patterns: `jj log -n 10 --no-graph -T 'description.first_line() ++ "\n"' -r ::@-` or `git log --oneline -10`

## Step 4: Write commit message

Based on the diff, chat context from this session, and any discovered convention, write a commit message that:

- Follows the repo's convention if one exists
- Is concise but descriptive
- Uses imperative mood ("fix bug" not "fixed bug")
- References relevant context from our conversation

## Step 5: Apply the commit

**For jj:**

- Use `jj describe -m 'MESSAGE'`
- Note: jj auto-commits on every change, so you're setting the description of the current change

**For git:**

- Stage all relevant changes: `git add -A`
- Commit: `git commit -m 'MESSAGE'`

## Rules

- If there are no changes, report that and do nothing
- If the commit convention is unclear, use Conventional Commits format: `type(scope): description`
- Always show the final commit message before applying it
- For jj repos, do NOT use `git commit` — use `jj describe`
