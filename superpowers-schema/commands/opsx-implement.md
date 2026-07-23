---
description: Implement tasks via subagent-driven-development with TDD + code review
---

Execute implementation of a change's tasks using subagent-driven-development (with transitive TDD + code review per task).

**Input**: Optionally specify a change name. If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise auto-select or prompt via `openspec list --json`.

   Always announce: "Using change: <name>"

2. **PRECHECK — workspace + plan source**

   a. Worktree exists:
      ```bash
      Test-Path .worktrees/<name>/
      ```
      If missing → STOP: "No worktree found. Run `/opsx-worktree <name>` first."

   b. Plan source available (Full mode has plan.md; Hotfix has execution-contract only):
      - Read `openspec/changes/<name>/brainstorm.md`. Look for "> Workflow mode:" line.
      - If "Full" or no mode line: confirm `plan.md` exists. If missing → STOP: "plan.md not found. Run `/opsx-continue <name>` to generate it."
      - If "Hotfix": plan.md is skipped (placeholder). Use execution-contract.md's Task Batches as the task source. Confirm execution-contract.md exists with `## Approval`.

   c. CLI tools on PATH:
      Read plan.md (or execution-contract.md for Hotfix) and surface any tool mentioned (e.g., `mvn`, `docker`, `node`). If a tool is missing, surface as WARNING (not STOP).

3. **Execute via skill**

   MANDATORY SKILL INVOCATION: You MUST invoke the `skill` tool with name `subagent-driven-development`. Do NOT execute tasks yourself without dispatching subagents — the skill tool call loads the skill's subagent orchestration logic AND produces a `skill-call` audit marker. Skipping = process violation.

   Invoke the skill tool now: `skill` with name `subagent-driven-development`.

   Tell the executor:
   - Full mode: Read `plan.md` for micro-tasks
   - Hotfix mode: Read execution-contract.md's Task Batches for coarse task list
   - Update `tasks.md` checkboxes as coarse tasks complete
   - Work within the created worktree

   **Transitive skill activation** (each dispatched subagent MUST invoke):
   - `test-driven-development` — before writing implementation code. RED→GREEN→REFACTOR. Implementation code before failing test → delete and redo.
   - `requesting-code-review` — after each task. Spec compliance + code quality. Critical issues block.

4. **Checkpoint protocol**

   After each coarse task group in tasks.md is completed (all micro-steps for a `## N` heading done, checkbox `[x]`), append:
   ```
   <!-- checkpoint: <commit-sha> at <YYYY-MM-DD HH:MM> — <task group title> done -->
   ```

5. **Resume from interruption**

   If tasks.md has checkpoints:
   1. Read tasks.md, locate last checkpoint annotation
   2. Confirm `git log` has that commit-sha
   3. Resume from next incomplete task group
   4. If checkpoint sha missing from history → warn user, re-verify from last completed group

6. **Report to user**

   "Implementation complete. Tasks: <done>/<total>. Run `/opsx-verify <name>` to verify."

   If a subagent reported BLOCKED:
   "Subagent BLOCKED on <task>. Run `/opsx-debug <name>` to investigate."

**Guardrails**
- Do NOT run verify, retrospective, archive, or PR in this command — use `/opsx-verify`, `/opsx-continue`, `/opsx-archive`, `/opsx-finish`
- If all tasks already `[x]`, inform user and skip (idempotent)
- This schema does NOT support `executing-plans` as fallback (it doesn't transitively activate TDD/code-review)
