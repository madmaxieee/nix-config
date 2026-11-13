---
name: t3-model-routing
description: Route substantial scouting and worker tasks to Gemini 4 Hydrogen when Gemini 4 Carbon, Claude Fable 5.2, or Claude Opus 5.5 leads in T3 Code.
---

# T3 Model Routing

Apply when T3's orchestration tools are available and the current lead is Gemini 4 Carbon (`gemini-4-carbon`), Claude Fable 5.2 (`claude-fable-5-2`), or Claude Opus 5.5 (`claude-opus-5-5`). Explicit user model choices override this policy. Other leads keep their existing routing.

## Division of work

- Keep the current lead responsible for framing, design decisions, synthesis, and final acceptance.
- Delegate broad scouting and self-contained, multi-step implementation or test tasks to Gemini 4 Hydrogen (`gemini-4-hydrogen`) with high reasoning. Keep quick lookups, tiny edits, and tightly coupled decisions with the lead when briefing and review would cost more than doing the work directly.
- Hydrogen workers complete their assigned scope without spawning children. Scope changes or unresolved design choices return to the lead with evidence and `ESCALATE: <reason>`.

## Dispatch

1. Before the first delegation in a thread, call `orchestrator_capabilities` to resolve the enabled Antigravity provider instance and confirm `gemini-4-hydrogen` is available. Reuse that discovery unless an error or user-requested provider change requires refreshing it. If unavailable, report the unavailable route rather than substituting another worker.
2. Use T3's **`delegate_task` explicitly under every supported lead**, including Carbon. Set `target.providerInstanceId` to the discovered Antigravity instance, `target.model` to `gemini-4-hydrogen`, and `target.options` to `{ thinking_level: "high" }` unless the user requested other supported worker settings. This avoids inheriting the lead's model or effort options through native delegation.
3. Give each worker a self-contained brief: objective, relevant context and paths, owned files, constraints, acceptance checks, and the stop rule above. T3 children receive no parent conversation history. Mark scouting read-only and use `role: "research"`; use `"implementation"` or `"test"` for worker changes. Use `isolation: "worktree"` for independent parallel writers. Worktrees start from the parent's committed state; use shared, sequential work when required inputs are uncommitted.
4. Follow the tool's returned `next` instruction. An async completion wakes the lead; collect the result then. Verify evidence and changes, integrate isolated work when needed, and resolve escalations before accepting the task.
