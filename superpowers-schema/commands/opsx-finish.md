---
description: Open PR via finishing-a-development-branch skill
---

Open a PR for a completed change. This is the last step — retrospective and archive must be done first.

**Input**: Optionally specify a change name. If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise auto-select or prompt via `openspec list --json`.

   Always announce: "Using change: <name>"

2. **PRECHECK — retrospective + archive done**

   - Check `openspec/changes/archive/` for a folder matching `YYYY-MM-DD-<name>`. If the change is still in `openspec/changes/<name>/` (not archived) → STOP: "Change not archived yet. Run `/opsx-archive <name>` first."
   - Check `retrospective.md` exists in the archived folder. If missing → STOP: "Retrospective not written. Run `/opsx-continue <name>` first."

3. **Open PR via skill**

   MANDATORY SKILL INVOCATION: You MUST invoke the `skill` tool with name `finishing-a-development-branch`. Do NOT open the PR manually via `gh pr create` — the skill tool call produces a `skill-call` audit marker.

   Invoke the skill tool now: `skill` with name `finishing-a-development-branch`.

   The skill:
   - Confirms tests are green
   - Presents merge / PR / keep-branch / discard options
   - Cleans up the worktree

4. **Report to user**

   Show the PR URL (or merge result) and worktree cleanup status.

**Guardrails**
- PR is the LAST step — if retro or archive haven't been done, STOP
- Do NOT skip retrospective or archive — they must land in the same PR diff
