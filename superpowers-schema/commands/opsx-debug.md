---
description: Independently trigger bug investigation (systematic-debugging)
---

Trigger a bug investigation for a change. Works at any phase — during apply, during manual testing, or for production investigation. Does NOT require apply to be in progress.

**Input**: Optionally specify a change name. If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise auto-select or prompt via `openspec list --json`.

   Always announce: "Using change: <name>"

2. **PRECHECK — skill availability**

   Confirm `systematic-debugging` appears in your available skills list. If missing → STOP: "Superpowers plugin must be installed. systematic-debugging skill is required."

3. **Trigger bug-investigation artifact**

   ```bash
   openspec instructions bug-investigation --change "<name>" --json
   ```

   Read the `instruction` field and follow it exactly. The instruction invokes `systematic-debugging` skill (MANDATORY) and runs 4 phases:
   - Phase 1: Root Cause Investigation
   - Phase 2: Pattern Analysis
   - Phase 3: Hypothesis & Testing
   - Phase 4: Implementation (failing test → fix → verify)

   Escalation rule: ≥3 failed fixes → STOP, fill Escalation section, present options to user.

4. **Report Resolution**

   After investigation, show the Resolution:
   - `resolved`: root cause found, fix applied, tests pass → "Bug resolved. Resume `/opsx-implement <name>` if apply was paused."
   - `unresolved`: still investigating → "Investigation ongoing. Apply stays paused."
   - `escalated`: ≥3 failures → "Escalated. Choose: (a) rethink approach, (b) simplify scope, (c) seek help."

**Guardrails**
- The Iron Law: no fixes without completing Phase 1 (root cause investigation)
- If invoked during apply step 2 (subagent reported BLOCKED), apply is already PAUSED — this command produces the same bug-investigation.md
- If invoked independently (no apply in progress), the change directory must still exist
- Do NOT run verify/archive/PR in this command
