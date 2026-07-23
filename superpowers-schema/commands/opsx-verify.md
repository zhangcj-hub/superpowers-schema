---
description: Run post-implementation verification checks
---

Run verification checks on a completed change and produce verify.md.

**Input**: Optionally specify a change name (e.g., `/opsx-verify my-feature`). If omitted, auto-select if only one active change exists, otherwise prompt.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` and use **AskUserQuestion tool** to let the user select

2. **Check that implementation has been done**

   ```bash
   openspec status --change "<name>" --json
   ```

   Look at the artifacts list:
   - If `execution-contract` is not `done` → STOP: "Planning not complete. Run `/opsx-propose <name>` or `/opsx-continue <name>` first."
   - If `execution-contract` is `done` but no git commits exist on the branch → STOP: "Apply has not been run yet. Run `/opsx-implement <name>` or `/opsx-apply <name>` first."

   > This command can be run independently after `/opsx-implement` or `/opsx-apply` — it does not require apply to have been a single command invocation, only that implementation work exists (commits + task progress).

3. **Check mode — lightweight verify for hotfix/tweak**

   Read brainstorm.md. If it contains "> Workflow mode: Hotfix" or "> Workflow mode: Tweak":
   - Run lightweight verification only:
     - Files exist and are non-empty
     - Syntax is valid (`node --check`, `dotnet build`, or equivalent)
     - No test regressions (run the project's test suite)
   - Write a minimal verify.md with just the lightweight results and "Overall Decision: ✅ PASS" or "❌ FAIL"
   - Skip the full verification below
   - Return

4. **Full verification (Full mode)**

   4.0 **Run the test suite for real** (before filling any check):

       Read `openspec/config.yaml`. If it declares `verify_test_command:`,
       execute that command in the worktree FOR REAL — do not skip, do
       not assume it passed, do not mark "unknown". This is the one
       check with objective teeth: exit code cannot be fabricated.

       - Capture: exit code + last 20 lines of output + passed count
         + skipped count (parse from the report: Playwright HTML /
         xUnit XML / Vitest JSON / `grep -c 'passed\|skipped'`).
       - Fill the Metrics section's `tests_pass` / `tests_run_evidence` /
         `test_skip_rate` from ACTUAL execution output.
       - Decision rules (feed into DP-6):
         - exit code ≠ 0 → tests_pass = false → FAIL
         - passed count < `verify_min_passed` (default 1 if undeclared)
           → tests_pass = false → FAIL (the suite ran but nothing truly
           passed — likely all skipped)
         - skip rate > 50% → FAIL (e2e collectively skipped because
           SUT unavailable ≠ coverage)
         - skip rate 20–50% → at least PASS WITH WARNINGS
       - If the test command fails to run at all (e.g. SUT not started,
         command not found), tests_pass = false, record the failure
         reason in `tests_run_evidence`. Do NOT mark "unknown" to
         bypass — the whole point of this step is that "unknown" is
         no longer an accepted escape hatch.

       This step 4.0 is MANDATORY for Full mode. Skipping it = verify
       FAIL regardless of other checks.

   4.1 Get the verify artifact instructions:

   ```bash
   openspec instructions verify --change "<name>" --json
   ```

   Follow the `instruction` field exactly. It contains:
   - PRECHECK: commit evidence + task progress evidence (must both be positive)
   - 9 checks to perform and record in verify.md:
     1. Structural validation (`openspec validate --all --json`)
     2. Task completion (all `- [x]` in tasks.md)
     3. Task completion spot audit (recommended, non-blocking;
         anti self-attestation — companion to Check 2)
     4. Delta spec sync state
     5. Design/specs coherence (non-blocking warning)
     6. Implementation signal (commits, no unstaged files)
     7. Front-door routing leak detector (non-blocking warning)
     8. Deferred dogfood vs automated-test equivalence
     9. Acceptance anchor coverage (blocking — traces to config.yaml's
        acceptance_doc via milestone-mandated + contract-declared union;
        Check 9's internal Step 0 reads proposal's milestone → config
        mandated anchor set; any ❌ NOT COVERED or ❌ NOT DECLARED → FAIL)

     Note: tests_pass / test_skip_rate from Step 4.0 above also feed
     Decision Point DP-6 in the Overall Decision.

5. **Write verify.md**

   Use the `template` field from the instructions JSON as the structure.
   Write to `resolvedOutputPath`.
   Fill in each check's results.
   Mark Overall Decision: ✅ PASS / ⚠️ PASS WITH WARNINGS / ❌ FAIL

6. **Report to user**

   Show the Overall Decision and any blocking issues.
   - If PASS or PASS WITH WARNINGS → "Verification complete. Run `/opsx-continue` to produce retrospective."
   - If FAIL → "Verification failed. Fix the blocking issues, then re-run `/opsx-verify`."

**Guardrails**
- Run all 9 checks for Full mode — do not skip any
- Use lightweight checks only for Hotfix/Tweak mode
- If verify.md already exists, overwrite it with fresh results
- Cite actual command output, not assumptions
