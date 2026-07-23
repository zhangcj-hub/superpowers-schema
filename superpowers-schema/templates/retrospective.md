# Retrospective: <change-name>

> Written: <YYYY-MM-DD> (after verify passed)
> Commit range: `<base-sha>..<head-sha>`
> Worktree: <path or "merged to main">

---

## 0. Evidence

> Quantitative baseline data — subsequent Wins / Misses bullets reference these
> directly, avoiding repetitive [evidence: ...] per line. In cold-write scenarios
> (retro written some time after the cycle ended), this section should be
> reconstructable using only `git log` + `tasks.md` + commit messages.

- **Commit range**: `<base-sha>..<head-sha>` (<n> commits)
- **Diff size**: <+X / -Y lines across N files>
- **Tasks done**: <x>/<y> (`grep -cE '^\s*- \[x\]' tasks.md` → x; regex allows sub-task indentation)
- **Active hours**: <estimate>
- **Subagent dispatches**: <count or "n/a">
- **New external dependencies**: <list, with license + version, or "none">
- **Bugs encountered post-merge**: <count, one-line each, or "none">
- **OpenSpec validate state at archive**: <pass / fail / not-run>
- **Test coverage signal**: <e.g. jacoco %, pytest count, vitest count, or "n/a">

Commit chain (chronological):

```
<base-sha> <one-line summary>
...
<head-sha> <archive commit one-line>
```

---

## 1. Wins

- [evidence: <commit/file/test>] <description>

## 2. Misses

- 🔴 [blocking | evidence: ...] <description>
- 🟡 [painful  | evidence: ...] <description>
- 📌 [nit      | evidence: ...] <description>

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| 1.2       | ...          | ... |

## 4. Skill / workflow compliance

| Skill                                            | Used |
|--------------------------------------------------|------|
| brainstorming                                    |      |
| writing-plans                                    |      |
| using-git-worktrees                              |      |
| subagent-driven-development                      |      |
| (transitive) test-driven-development             |      |
| (transitive) requesting-code-review              |      |
| systematic-debugging                             |      |
| finishing-a-development-branch                   |      |

> **Default expectation**: all ✓. Every skill is part of the schema design;
> skipping is an exceptional situation. Any ✗ MUST be explained in the
> `### Deliberately Skipped Skills` subsection below with reason and prevention
> plan.

### Deliberately Skipped Skills

> Skipping a skill is a designed escape hatch, not a regular path. Each ✗ MUST
> answer the three questions below; a blank section (all green) is the expected
> state.

- **`<skill name>`**
  - **What was skipped**: <whether the entire skill or a specific sub-step was skipped>
  - **Why this cycle**: <specific cycle conditions — do NOT write vague reasons
    like "not needed" / "too small" / "no time" / "blocked by external dep" /
    "skill output looked wrong"; write the actual trigger (specific commit /
    log line / observed behavior)>
  - **How to prevent recurrence**: How to avoid skipping again in the next
    cycle under similar conditions? Choose one:
    - `schema graph fix` — write which specific section of schema.yaml to change
    - `skill description tightening` — write which specific skill's frontmatter
      / instruction to change
    - `CLAUDE.md trigger` — write which specific detection rule to add to the
      adopter CLAUDE.md.fragment
    - `scope-judgment rule` — write how this cycle's scope should have been judged
    - `one-off — schema boundary case, no prevention possible` — but must clearly
      state why it's a boundary case (no vague reservations accepted)

> **Relationship with §6 Promote candidates**: Multiple cycles, same skill,
> same "How to prevent" answer → that pattern should be promoted to §6,
> directly triggering a schema / skill PR; do NOT let it accumulate as "normal."

## 5. Surprises

- <assumption that turned out wrong>

## 6. Promote candidates → long-term learning

Format each candidate as a `- [ ]` checklist:

- Title: severity emoji (🔴/🟡/📌) + one-line learning
- `→ **Promote to** <destination>` (memory / CLAUDE.md / schema / skill / one-off)
- Two-line body (matching the superpowers feedback memory body schema):
  - `> **Why**: <reason; often a past incident or strong preference>`
  - `> **How to apply**: <when/where this guidance kicks in>`

Unchecked `- [ ]` items are candidates not yet promoted — they can be carried
forward to the next cycle's retro for re-evaluation, or kept as cross-cycle
observation points.

> **Carry-forward mechanism**: When writing the next cycle's retro, run
> `grep -A 5 '^- \[ \]' openspec/changes/archive/*/retrospective.md` to
> retrieve past unchecked candidates, then decide per item whether to
> carry-forward to this cycle's §6, promote in-place, or mark as stale and
> stop tracking.

Example:

- [ ] 🔴 **<short rule>** → **Promote to memory** (type: feedback)
  > **Why**: <past incident or strong preference that motivated this rule>
  > **How to apply**: <which file / cycle phase / decision moment this kicks in>

- [ ] 🟡 **<another candidate>** → **Promote to project CLAUDE.md** (`<path/to/CLAUDE.md>` section)
  > **Why**: ...
  > **How to apply**: ...

- [ ] 📌 **<third candidate>** → **One-off** (record only, do not promote)
  > **Why**: <why it doesn't generalize>

---

## Metrics

<!-- Machine-readable metrics for automated evaluation (ai-eval skill).
     Parsed by scanning openspec/changes/archive/*/retrospective.md using
     Select-String regex (NO YAML parser available in PowerShell).
     Format: key: value (one per line, plain text, no code block).
     Heading must be exactly "## Metrics" — no § prefix, no numbering.
     Fill every field even if value is 0 or "pending". -->

change_name: <change-name>
commits: <n>
diff_insertions: <n>
diff_deletions: <n>
tasks_total: <y>
tasks_done: <x>
tdd_used: <true | false>
code_review_used: <true | false>
systematic_debugging_used: <true | false>
deliberately_skipped_skills_count: <count>
promote_candidates_proposed: <count of unchecked - [ ] in section 6>
promote_candidates_promoted: <count of checked - [x] in section 6>
carry_forward_items: <count of items carried from previous cycle>
post_merge_bugs: <count or "pending">

> `post_merge_bugs`: at write time (pre-merge), write `0` or `pending`.
> After merge, if bugs are discovered, use the forward-pointer policy to
> update this field: `> **Update YYYY-MM-DD**: post_merge_bugs: N`