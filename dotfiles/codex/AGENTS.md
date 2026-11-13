## File Search

- Use `fff` MCP tools for file and content searches when available.

## Jujutsu

- In repositories with `.jj` (or Git worktrees linked to a repository with `.jj`), use `jj` for all version-control inspection and mutations (`jj status`, `jj diff`, `jj log`, `jj describe`, `jj new`, `jj bookmark`, `jj git push`) rather than raw `git` commands.
- Create isolated checkouts as colocated `jj` workspaces: `jj -R <repo> workspace add --colocate -r 'trunk()' <dest>`, followed by `git -C <dest> submodule update --init --recursive` when `.gitmodules` exists.
- In T3 Code worktrees backed by a `.jj` repository that do not yet have `.jj`, run `"$HOME/.local/bin/t3-jj-worktree" setup` before inspecting or editing.
