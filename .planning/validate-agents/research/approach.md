# Approach Research

> Task: Add a validate-agents script that checks all agent .md files have required sections (Role, Constraints, Workflow, Output Format, Success Criteria)
> Last researched: 2026-02-23T16:53:16Z

## Context

The repo at `/Users/jamescarr/Git/jamesacarr/claude` is a pure markdown/config project (Claude Code plugin system). There is:
- No `package.json`, no `Makefile`, no existing scripts directory
- No test framework or build tooling
- 8 agent files at `plugins/jc/agents/team-*.md`
- Each agent file has YAML frontmatter (`---` delimiters) followed by markdown with `## ` headings

### Current Section Coverage

All 8 agents have: `## Role`, `## Constraints`, `## Output Format`, `## Success Criteria`.
All agents have `## Workflow` **except** `team-leader.md` which uses `## Lifecycle` instead (functionally equivalent -- it describes the agent's step-by-step process).

## Viable Approaches

### 1. Bash Script

- **What:** A standalone `.sh` script using `grep` to check for required `## ` headings in each agent file.
- **How:** Loop over `plugins/jc/agents/team-*.md`, for each file grep for `^## Role`, `^## Constraints`, `^## Workflow`, `^## Output Format`, `^## Success Criteria`. Report missing sections. Exit non-zero on failure.
- **Pros:**
  - Zero dependencies -- works on any machine with bash and grep
  - Fastest to implement (< 50 lines)
  - Natural fit for a CI pre-commit hook or GitHub Actions step
  - Follows the repo's zero-tooling pattern (no package.json, no build system)
- **Cons:**
  - Limited expressiveness for complex validation (e.g., checking frontmatter fields, section ordering, minimum content length)
  - Bash can be fragile with edge cases (filenames with spaces, etc.) though not a concern here
  - Harder to extend for structural validation (e.g., "Workflow must contain numbered steps")
- **Best when:** The validation is limited to presence-checking of headings, and no additional tooling is desired.
- **Sources:** Codebase inspection -- no existing scripts or package manager present.

### 2. Node.js Script (with or without package.json)

- **What:** A `.mjs` or `.js` script using Node's `fs` module to read agent files, parse markdown, and validate required sections.
- **How:** Read each `.md` file, split on `## ` headings (or use a lightweight markdown parser like `remark`/`unified`), check for required sections. Could also validate YAML frontmatter with `yaml` or `gray-matter`.
- **Pros:**
  - More expressive -- can validate frontmatter fields (`name`, `description`, `tools`), section content, cross-references
  - Easier to extend with structural rules over time
  - Can produce structured JSON output for programmatic consumption
  - Familiar language for the repo owner (Sr. Frontend Engineer)
- **Cons:**
  - Requires Node.js runtime (reasonable assumption given Claude Code targets)
  - Introduces `package.json` and potentially `node_modules` if using parsing libraries -- overhead for a small repo
  - Overkill if the only requirement is heading presence checks
  - If zero-dep: just doing string splitting, losing the main advantage over bash
- **Best when:** Validation requirements are expected to grow beyond heading presence (frontmatter validation, content quality checks, cross-file consistency).
- **Sources:** Based on training data -- no library lookup needed for `fs.readFileSync` / string splitting.

### 3. Makefile Target with Inline Validation

- **What:** Add a `Makefile` to the repo with a `validate-agents` target that runs the validation inline using shell commands.
- **How:** A `Makefile` with a target that loops over agent files and greps for required headings. Essentially wraps Approach 1 in a Make target.
- **Pros:**
  - Aligns with user preference for `make` targets (`Prefer makefile targets over direct tool invocation`)
  - Self-documenting via `make help`
  - Can be extended with other targets (e.g., `lint`, `format`)
  - Provides a standard entry point even if the actual validation is a separate script
- **Cons:**
  - Still shell-based, same limitations as Approach 1 for complex validation
  - Adds a Makefile to a repo that currently has none (though the user prefers Makefiles)
  - Make syntax can be awkward for multi-line shell logic
- **Best when:** The repo is expected to gain more tooling targets over time, and the user wants a consistent `make <target>` interface.
- **Sources:** User preference from `~/.claude/CLAUDE.md`: "Prefer makefile targets (e.g. `make help`) over direct tool invocation".

## Recommendation

**Approach 3 (Makefile) wrapping Approach 1 (Bash script).**

Rationale:
1. The user explicitly prefers Makefile targets as the interface (`make validate-agents`)
2. The underlying validation logic is simple enough for bash -- only checking heading presence in 8 files
3. Keeping the validation in a standalone `.sh` script (called from the Makefile) separates concerns: the Makefile is the interface, the script is the logic. This is cleaner than inline shell in the Makefile
4. Zero new dependencies -- no package.json or node_modules
5. Easy to extend: add more Makefile targets later, or swap the bash script for a Node.js one if validation grows complex

Suggested file layout:
```
scripts/validate-agents.sh    # validation logic
Makefile                       # make validate-agents target
```

### Key Design Decision: `## Workflow` vs `## Lifecycle`

`team-leader.md` uses `## Lifecycle` instead of `## Workflow`. The script should either:
- **(a)** Accept `## Lifecycle` as a valid alias for `## Workflow` for the leader agent specifically
- **(b)** Treat `## Workflow` as strictly required, which would flag team-leader as non-compliant

Recommendation: **(a)** -- accept both. The Lifecycle section serves the same purpose (step-by-step process). The script should check for `## Workflow` OR `## Lifecycle` to satisfy the Workflow requirement. Document this in the script's comments.

## Open Questions

1. **Should the script also validate YAML frontmatter fields?** All agents have `name` and `description`; most have `tools`. This is not in the task description but would be a natural extension. Planner should decide whether to scope this in or defer.
2. **Where should the script live?** `scripts/validate-agents.sh` is suggested, but the Planner may prefer a different location (e.g., `bin/`, `tools/`, or directly in the project root).
3. **Should this run as a git pre-commit hook?** The `.git/hooks/` directory has only sample files. Integrating with pre-commit would catch issues earlier but adds friction. Planner should decide if this is in scope.
4. **Exit code semantics:** Should the script exit on first failure or collect all failures and report them together? Collecting all is more user-friendly for fixing multiple issues at once.
