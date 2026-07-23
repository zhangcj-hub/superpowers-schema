<!--
Delta spec template for a change.

This template demonstrates 4 delta section types; use only what you need:
- ADDED / MODIFIED / REMOVED / RENAMED
File path: openspec/changes/<change-name>/specs/<capability>/spec.md
(`<capability>` matches the directory name under openspec/specs/<capability>/)

Hard format rules (validated by OpenSpec):
- Requirement sentences MUST contain `SHALL` or `MUST`
- Each Requirement MUST have at least one `#### Scenario:`
- Scenarios MUST use level-4 (`####`); level-3 or bullets will silently fail
  to validate

Authoring guidance (not validated, but expected for TDD traceability):
- GIVEN is optional: add it ONLY when the initial state is NOT the default
  (e.g., already-logged-in user, non-TTY stdin, pre-existing data). Default-
  state scenarios omit GIVEN and start with WHEN. WHEN/THEN is the minimum
  skeleton; GIVEN, when present, defines the test's Arrange phase — omitting
  it for non-default states loses the setup contract that TDD relies on.
-->

## ADDED Requirements

<!-- New behavior. List Requirements this change adds to the capability. -->

### Requirement: <!-- requirement name -->
<!-- requirement text — MUST contain SHALL or MUST -->

#### Scenario: <!-- scenario name -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

---

## MODIFIED Requirements

<!--
Modify an existing Requirement. **MUST use the exact same normalized header
as openspec/specs/<capability>/spec.md** (trimmed, case-sensitive match),
or the delta apply during archive will fail because the corresponding
requirement cannot be found.

**MUST paste the full modified content** (not just a diff), because OpenSpec
archive applies MODIFIED via full-text replacement.
-->

### Requirement: <!-- same header as in the existing spec -->
<!-- full modified requirement text — MUST contain SHALL or MUST -->

#### Scenario: <!-- scenario name (can be new or modified) -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

---

## REMOVED Requirements

<!--
Remove an existing Requirement. MUST include Reason and Migration notes so
reviewers understand why it is being removed and how existing callers should
adapt.
-->

### Requirement: <!-- header to remove, exactly as in the existing spec -->

**Reason**: <!-- why this is being removed -->

**Migration**: <!-- how existing callers/dependents should adapt -->

---

## RENAMED Requirements

<!--
Rename a Requirement header. Fixed format: FROM / TO using code-fence headers.
If both name AND content change, list the name change in RENAMED AND write the
full new content under MODIFIED using the **new** header.

Archive apply order: RENAMED → REMOVED → MODIFIED → ADDED
-->

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`