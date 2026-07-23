---
description: Resume a change — create only the missing artifacts
---

Resume an interrupted change by creating only the artifacts that are not yet done.

**Input**: Optionally specify a change name (e.g., `/opsx-continue my-feature`). If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` and use **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>"

2. **Check current artifact status**

   ```bash
   openspec status --change "<name>" --json
   ```

   Parse the JSON to get:
   - `artifacts`: list with `id`, `status` (`ready` / `blocked` / `done`)
   - `applyRequires`: what needs to be done before apply is unblocked

3. **If all `applyRequires` artifacts are done → tell user**

   "All planning artifacts are complete. Ready for `/opsx-apply`."

   If verify.md or retrospective.md are still missing (post-apply), continue to create them.

4. **Create the next ready artifact**

   Find the first artifact with `status: "ready"` (dependencies satisfied, not yet done):

   a. Get instructions:
      ```bash
      openspec instructions <artifact-id> --change "<name>" --json
      ```
   b. Read the `instruction` field — follow it exactly
   c. Read the `template` field — use it as the output structure
   d. Read any dependency files listed in `dependencies`
   e. Apply `context` and `rules` as constraints (do NOT copy them into the file)
   f. Write the artifact to `resolvedOutputPath`
   g. Show brief progress: "Created <artifact-id>"

5. **Check for mode-aware skip**

   After creating brainstorm.md, if it contains "> Workflow mode: Tweak":
   - STOP the loop. Tell the user: "This change is in Tweak mode. Make changes directly — no opsx artifacts needed. Use `/opsx-archive` when done."
   - Do NOT attempt to create further artifacts.

   If it contains "> Workflow mode: Hotfix":
   - Continue the loop, but proposal/design/specs/tasks/plan will self-skip (write placeholder lines)
   - The loop will proceed to execution-contract (hotfix mode)

6. **Loop or finish**

   Re-run `openspec status --change "<name>" --json` after each artifact.
   - If more `ready` artifacts exist → repeat step 4
   - If all `applyRequires` artifacts are done → "All planning artifacts complete. Run `/opsx-apply` to implement."
   - If only post-apply artifacts remain (verify, retrospective) → tell user to run `/opsx-apply` first

**Guardrails**
- Only create artifacts with `status: "ready"` — do not touch `blocked` or `done` artifacts
- Follow the `instruction` field exactly — it contains mode PRECHECKs and skill invocations
- If an artifact instruction says "STOP" or "skip" (mode-aware), respect it
- If context is unclear, use **AskUserQuestion tool** to clarify before creating
