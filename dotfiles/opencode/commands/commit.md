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
- Uses imperative mood ("fix bug" not "fixed bug")
- Has a concise subject line (under 72 characters)
- **Includes a body when useful**: explain *why* the change was made, not just *what* changed
- References relevant context from our conversation
- Uses a blank line between subject and body

## Step 5: Apply the commit

**For jj:**

- For single-line messages: `jj describe -m 'MESSAGE'`
- For multi-line messages, use a heredoc:
  ```
  jj describe -m 'SUBJECT

  BODY LINE 1
  BODY LINE 2'
  ```
- Note: jj auto-commits on every change, so you're setting the description of the current change

**For git:**

- Stage all relevant changes: `git add -A`
- For single-line messages: `git commit -m 'MESSAGE'`
- For multi-line messages, use multiple `-m` flags or a heredoc:
  ```
  git commit -m 'SUBJECT' -m 'BODY LINE 1

  BODY LINE 2'
  ```

## Rules

- If there are no changes, report that and do nothing
- If the commit convention is unclear, use Conventional Commits format: `type(scope): description`
- Always show the final commit message before applying it
- For jj repos, do NOT use `git commit` — use `jj describe`
