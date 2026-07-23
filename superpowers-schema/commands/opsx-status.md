---
description: Show current change status and derived workflow state
---

Show the current status of a change, including the derived state machine state.

**Input**: Optionally specify a change name (e.g., `/opsx-status my-feature`). If omitted, list all active changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Run `openspec list --json` to get all active changes
   - If no active changes exist → "No active changes. Run `/opsx-propose <name>` to start one."
   - If one active change exists → use it automatically
   - If multiple → use **AskUserQuestion tool** to let the user select

2. **Get artifact status**

   ```bash
   openspec status --change "<name>" --json
   ```

   Parse the JSON to get:
   - `artifacts`: list with `id`, `status` (`ready` / `blocked` / `done`)
   - `applyRequires`: what apply needs
   - `schemaName`: the schema being used

3. **Derive the workflow state**

   Apply these rules to determine the current state:

   | Condition | State |
   |---|---|
   | brainstorm.md missing or "Skipped" placeholder | exploring |
   | brainstorm done, tasks.md or plan.md not done | specifying |
   | plan done, execution-contract.md missing | bridging |
   | execution-contract.md exists with `## Approval` section | approved-for-build |
   | approved + tasks.md has `[x]` but not all done | executing |
   | bug-investigation.md exists with Resolution = unresolved/escalated | debugging |
   | apply done + verify.md exists | closing |
   | user explicitly requested | abandoned |

4. **Display status**

   ```
   ## Change: <name> (schema: <schema-name>)

   **Workflow State**: <derived-state>

   ### Artifacts

   | Artifact | Status |
   |---|---|
   | brainstorm | ✅ done / ⏳ ready / 🚫 blocked |
   | proposal | ... |
   | ... | ... |

   **Apply requires**: <applyRequires> (<done? "satisfied" : "not satisfied">)

   ### Next Action

   <based on state, suggest the next command to run>
   ```

5. **Suggest next action**

   Based on the derived state:

   | State | Suggested next action |
   |---|---|
   | exploring | `/opsx-continue` to create brainstorm |
   | specifying | `/opsx-continue` to create next planning artifact |
   | bridging | `/opsx-continue` to create execution-contract |
   | approved-for-build | `/opsx-apply` to start implementation |
   | executing | `/opsx-apply` to continue implementation |
   | debugging | Resolve the bug — see bug-investigation.md |
   | closing | `/opsx-continue` to produce verify/retrospective, then `/opsx-archive` |
   | abandoned | No further action |

**Guardrails**
- Always run `openspec status` fresh — do not use cached results
- Derive state from file existence + content, not from timestamps
- If brainstorm.md contains "> Workflow mode: Hotfix", account for skipped artifacts
- If brainstorm.md contains "> Workflow mode: Tweak", report state as "tweak — direct edit"
