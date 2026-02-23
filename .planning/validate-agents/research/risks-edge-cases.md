# Risks & Edge Cases Research

> Task: Add a validate-agents script that checks all agent .md files have required sections (Role, Constraints, Workflow, Output Format, Success Criteria)
> Last researched: 2026-02-23T16:53:15Z

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `team-leader.md` uses `## Lifecycle` instead of `## Workflow` — validator would flag a false positive | high | high | Decide upfront whether "Workflow" is strict or has known synonyms. Either rename the section in `team-leader.md` or teach the validator that `## Lifecycle` is an acceptable alias for `## Workflow`. Document the decision |
| Agents have additional sections beyond the required five (e.g., `## Focus Areas`, `## Agent Team Behavior`, `## Smart Resume`) — overly strict validation could reject valid files | high | medium | Validate that required sections *exist*, not that they are the *only* sections. The validator should check for presence, not exclusivity |
| YAML frontmatter fields vary across agents (`tools`, `skills`, `mcpServers` are optional) — a validator that checks frontmatter could false-positive on missing optional fields | medium | medium | Scope validation to body sections only (as the task specifies), or if frontmatter is validated later, define which fields are required (`name`, `description`) vs optional |
| Some agents have duplicate `## Success Criteria` headings (e.g., `team-verifier.md` has one at line 155 inside Agent Team Behavior context and another at line 250) — naive heading search would find the first and miss structural intent | medium | medium | Search for all `## Success Criteria` occurrences and require at least one. Alternatively, validate only top-level H2 headings (not those inside subsections). The verifier's second `## Success Criteria` at line 250 is the real one; the one at line 155 closes the main Workflow section |
| New agent files added in the future may not be caught if the script path is hardcoded | medium | medium | Use a glob pattern (`plugins/jc/agents/team-*.md` or `plugins/jc/agents/*.md`) rather than a hardcoded file list |
| Regex-based heading detection matches H2 inside code blocks (triple-backtick fenced blocks contain `## ` lines in Output Format sections) | high | high | The Output Format sections of nearly every agent contain markdown templates inside fenced code blocks with `## Result`, `## Summary`, `## Details`, `## Completed:` etc. A naive `grep '## Role'` would not false-positive on these (the required section names are unlikely inside code blocks), but `## Success Criteria` or `## Workflow` could appear inside code block examples. Strip or skip fenced code blocks before scanning, or use a state machine that tracks whether the parser is inside a code block |
| Script fails silently on file-read errors (permissions, broken symlinks) | low | medium | Check file readability before parsing. Exit with non-zero and a clear message on any I/O error |
| Heading detection is case-sensitive — `## role` or `## ROLE` would not match | low | low | All existing agents use title case (`## Role`). Keep case-sensitive matching since the convention is consistent, but document the assumption |

## Edge Cases

- **Empty `.md` file** — expected behaviour: validator reports all 5 sections missing and exits non-zero
- **File with only YAML frontmatter, no body** — expected behaviour: validator reports all 5 sections missing (frontmatter `---` delimiters should not be confused with section markers)
- **Heading with trailing whitespace** (`## Role   `) — expected behaviour: validator should still match. Use a pattern like `^## Role\s*$` or strip trailing whitespace
- **Heading with extra content** (`## Role and Responsibilities`) — expected behaviour: should NOT match `## Role` as a required section. Use exact match (`^## Role$` with optional trailing whitespace), not substring match
- **Nested headings** (`### Role` as H3 inside another section) — expected behaviour: should NOT count as the required `## Role` section. Require exactly `## ` (H2 level)
- **`## Lifecycle` in `team-leader.md`** — this agent uses `## Lifecycle` instead of `## Workflow`. Currently the only file with this deviation. Expected behaviour: depends on design decision (see Risks above). If strict, the leader fails validation and needs a section rename. If aliased, the validator accepts it
- **Code block false positives** — agent files like `team-verifier.md`, `team-executor.md`, and `team-debugger.md` contain fenced code blocks (` ``` `) with `## Result`, `## Summary`, `## Details` headings inside. While these don't match the 5 required section names directly, future required sections could collide. Example: `team-leader.md` line 286 has `## Completed: {task title}` inside a code block
- **Multiple occurrences of same heading** — `team-verifier.md` has `## Success Criteria` at lines 155 and 250. Expected behaviour: validator should pass as long as at least one occurrence exists
- **No agent files found** (empty agents directory) — expected behaviour: script should exit cleanly with a message like "no agent files found" rather than silently passing
- **Non-agent `.md` files in the agents directory** — currently all files match `team-*.md`, but if a `README.md` or other doc is added to `plugins/jc/agents/`, it should not be validated. Use a specific glob pattern
- **Windows line endings (`\r\n`)** — if files are edited on Windows or with certain editors, `\r` before `\n` could break `^## Role$` regex. Use `\r?$` or strip carriage returns before matching
- **Unicode lookalike characters** — extremely unlikely but `##` could contain non-ASCII space or hash. Not worth handling unless discovered

## Backward Compatibility

No breaking changes. This is a new script that does not modify existing files. However, there are two considerations:

1. **If the script is added to CI or pre-commit hooks**, it becomes a gate. Any existing agent that fails validation (e.g., `team-leader.md` with `## Lifecycle` instead of `## Workflow`) would block the pipeline. The script should be validated against all 8 existing agents before being added to any gate.
2. **If the script is added to a Makefile target**, it establishes a new convention. Future agent authors need to know the required sections. Consider having the script output a helpful message listing the missing sections when validation fails.

## Fragile Areas

- `plugins/jc/agents/team-leader.md` — uses `## Lifecycle` instead of `## Workflow`. This is the only agent that deviates from the expected section naming. The validator design must account for this or the file must be updated. Changing the heading in `team-leader.md` could affect any documentation or agent code that references `## Lifecycle` by name, though grep shows no such references outside the file itself.
- `plugins/jc/agents/team-verifier.md` — has two `## Success Criteria` sections (lines 155 and 250). The second one (line 250) is appended after the `## Agent Team Behavior` section and appears to be the authoritative one for the Agent Team Behavior context. A validator that counts exact section occurrences (expecting exactly 1) would flag this incorrectly.
- `plugins/jc/agents/team-reviewer.md` — the `## Role` section is followed by sub-content including `### Review Methodology` and `#### Quality Dimensions` before `## Focus Areas` appears at line 64. Deep nesting could confuse a validator that expects H2 sections to appear in a specific order.

## Unknowns

- **Whether `## Workflow` is a hard requirement or `## Lifecycle` is an acceptable alias** — the task description says "Workflow" but the existing `team-leader.md` uses "Lifecycle" for the same purpose. The Planner needs to decide: (a) rename the heading in `team-leader.md`, (b) treat "Lifecycle" as an alias in the validator, or (c) exempt `team-leader.md` from the Workflow check. Option (a) is cleanest.
- **Whether the script should also validate YAML frontmatter** — the task description mentions only body sections, but frontmatter validation (required `name` and `description` fields) would be a natural extension. Scope decision needed.
- **Whether section ordering matters** — all agents currently follow Role → ... → Constraints → ... → Workflow → ... → Output Format → ... → Success Criteria ordering, but the task description only says sections must exist. If ordering is validated, it adds complexity and fragility.
- **Where the script should live** — no existing scripts directory. Options: project root, `plugins/jc/scripts/`, or as a Makefile target. The Planner should decide based on codebase conventions.
- **Whether the script should be shell (bash) or another language** — the approach research should cover this, but the choice affects how code-block-aware parsing is implemented. A simple bash script with `grep` cannot easily skip fenced code blocks; a more capable parser (node, python) handles this trivially.
