---
description: Generate and apply a commit description [revision|bookmark], defaults to working copy
agent: fast
subtask: true
---

You are an expert at writing clean jj commit descriptions.

Input: $ARGUMENTS

## Target Revision

- **No args**: Describe working copy (`jj diff`, `jj describe -m ...`)
- **Revision/ID/bookmark**: Verify with `jj log -r "$ARGUMENTS" --no-graph`, then `jj diff -r "$ARGUMENTS"`, `jj describe -r "$ARGUMENTS" -m ...`
- **Natural language hint**: Treat as hint for working copy
- **Unsure**: Try `jj log -r "$ARGUMENTS" --no-graph`; if it fails, treat as hint

## Steps

1. **Context**: Run `jj log -n 5 --no-graph -T 'description ++ "\n---\n"' -r ::@` to learn repo commit style. Run the appropriate `jj diff`. If empty, report no changes.
2. **Analyze**: Identify major changes; incorporate any hints from input.
3. **Generate**: Write the commit message.

## Output Rules

- Match existing repo commit style; default to conventional commits (chore:/feat:/fix:)
- No auto-generated trailers (Co-authored-by, Signed-off-by, Change-id)
- First line < 50 chars; subsequent lines < 72 chars
- Output only the commit message, no code blocks

## Action

Apply using heredoc:

```bash
# Working copy:
jj describe -m "$(cat <<'EOF'
<message>
EOF
)"

# Specific revision:
jj describe -r "$ARGUMENTS" -m "$(cat <<'EOF'
<message>
EOF
)"
```
