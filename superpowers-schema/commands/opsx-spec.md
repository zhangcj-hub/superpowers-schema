---
description: Create change + run planning to specs only, then stop
---

Create a change and produce planning artifacts up to specs, then STOP.
Use this for "requirements first, implement later" workflow.

**Input**: Optionally specify a change name. If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select or create the change**

   If a name is provided and the change doesn't exist:
   ```bash
   openspec new change "<name>"
   ```
   If omitted, auto-select if only one active change exists.

   Always announce: "Using change: <name>"

2. **Run planning loop until specs are done**

   ```bash
   openspec status --change "<name>" --json
   ```

   Loop: find the first artifact with `status: "ready"` that is a *planning* artifact (brainstorm, proposal, design, specs). For each:
   a. Get instructions:
      ```bash
      openspec instructions <artifact-id> --change "<name>" --json
      ```
   b. Read the `instruction` field — follow it exactly (including skill invocations and PRECHECKs)
   c. Write the artifact to `resolvedOutputPath`
   d. Re-run `openspec status` to check next ready artifact

   **STOP after specs are done.** Do NOT create tasks, plan, execution-contract, or run apply. Tell the user: "Specs complete. Run `/opsx-continue <name>` when ready to proceed to tasks/plan/contract/apply."

3. **Mode-aware handling**

   After creating brainstorm.md, check for "> Workflow mode:" line:
   - If "Tweak": STOP. Tell user to make changes directly.
   - If "Hotfix": This command is not applicable (Hotfix skips specs). Tell user to use `/opsx-propose <name>` instead.

**Guardrails**
- Only create planning artifacts up to specs — do NOT create tasks/plan/execution-contract
- Follow each artifact's `instruction` field exactly (includes PRECHECKs and skill invocations)
- If brainstorm is interactive (brainstorming skill), pause for user dialogue
