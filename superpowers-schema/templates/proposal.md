## Why

<!--
Explain the motivation for this change. What problem does this solve? Why now?

Hard limit: 50 ≤ characters ≤ 1000 (validated by OpenSpec zod schema)
- Too short: you will get `Why section must be at least 50 characters` error
- Too long: you will get `Why section should not exceed 1000 characters` error

Suggested structure: current pain point → why address now → expected benefit
(1-2 sentences each)
-->

## What Changes

<!--
Describe what will change. Be specific about new capabilities, modifications, or removals.

For behavioral changes with clear before/after contrast, use From/To format
(markdown without inline diff):

**<Section or Behavior Name>**
- From: <current state / requirement>
- To: <future state / requirement>
- Reason: <why this change is needed>
- Impact: <breaking / non-breaking, who's affected>

Repeat this block for multiple changes; pure additions or deletions can use a
simple list.
-->

## Capabilities

### New Capabilities
<!--
Capabilities being introduced. Replace <name> with kebab-case identifier.
Naming rules: see openspec/specs/README.md — use compound nouns (at least 2 words),
e.g. `user-auth`, `data-export`, `api-rate-limiting`. Do NOT use single words.
Each creates specs/<name>/spec.md
-->
- `<name>`: <brief description of what this capability covers>

### Modified Capabilities
<!--
Existing capabilities whose REQUIREMENTS are changing (not just implementation).
Only list here if spec-level behavior changes. Each needs a delta spec file.
Use existing spec names from openspec/specs/. Leave empty if no requirement changes.
-->
- `<existing-name>`: <what requirement is changing>

## Impact

<!-- Affected code, APIs, dependencies, systems -->

## Milestone

<!--
If this project's openspec/config.yaml declares `acceptance_doc:` with
milestone-mapped anchors, declare which milestone this change targets
(e.g. "Milestone: R5"). The apply-phase PRECHECK enforces this when
config has acceptance_doc; verify Check 9 Step 0 uses it to resolve the
mandated anchor set.

If your project has no `acceptance_doc` (e.g. a library with no external
PRD), write "N/A — no external acceptance baseline declared".
-->

Milestone: <milestone-label or N/A>