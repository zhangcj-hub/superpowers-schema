---
description: Create isolated git worktree for a change
---

Create an isolated git worktree for implementing a change.

**Input**: Optionally specify a change name. If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise auto-select or prompt via `openspec list --json`.

   Always announce: "Using change: <name>"

2. **PRECHECK — execution-contract approved**

   ```bash
   openspec status --change "<name>" --json
   ```

   - If `execution-contract` is not `done` → STOP: "Planning not complete. Run `/opsx-propose <name>` or `/opsx-continue <name>` first."
   - Read `openspec/changes/<name>/execution-contract.md`. If no `## Approval` section → STOP: "Execution contract not approved. Approve it first."

3. **Create worktree via skill**

   MANDATORY SKILL INVOCATION: You MUST invoke the `skill` tool with name `using-git-worktrees`. Do NOT create the worktree manually via `git worktree add` — the skill tool call produces a `skill-call` audit marker that the ai-eval evaluation pipeline relies on.

   Invoke the skill tool now: `skill` with name `using-git-worktrees`.

   The skill creates `.worktrees/<change-name>/`, switches to a new branch, runs project setup, confirms a clean test baseline.

4. **Report to user**

   "Worktree ready at `.worktrees/<name>/`. Run `/opsx-implement <name>` to start implementation."

**Guardrails**
- Do NOT proceed to implementation in this command — that's `/opsx-implement`'s job
- If worktree already exists, inform the user and skip creation (idempotent)
